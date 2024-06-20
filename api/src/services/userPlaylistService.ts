import { formatNumberToReadableString } from "../lib/formatNumber";
import { ITrack, ITrackDocument, Track } from "../models/Track";
import {
  IUserPlaylistModel,
  UserPlaylist,
  IUserPlaylist,
  PlaylistStatus,
} from "../models/UserPlaylist";
import { getDayOfWeekTimeOfDayText } from "../time";
import {
  addToPlaylist,
  addTracksToPlaylist,
  createPlaylist,
  editSpotifyPlaylistDescription,
  fetchPlaylist,
  fetchTracks,
  removeTracksFromPlaylist,
} from "./spotifyAPIService";

const DEFAULT_PLAYLIST_PARAMS = {
  name: getDefaultPlaylistName(),
  decsription: `created via the iOS app, dj heartbeat.`,
  isPublic: false,
};

const DEFAULT_DJ_HEARTBEAT_PLAYLIST_NAME = "Heart Charts";

interface PlaylistWithDuration extends IUserPlaylist {
  playlistDurationMS: number;
}

function getDefaultPlaylistName(): string {
  const now = new Date();

  const monthNames = [
    "jan",
    "feb",
    "mar",
    "apr",
    "may",
    "jun",
    "jul",
    "aug",
    "sep",
    "oct",
    "nov",
    "dec",
  ];
  const month = monthNames[now.getMonth()]; // Get the current month's abbreviation
  const year = now.getFullYear() % 100; // Get the last two digits of the current year

  return `slaylist | ${month}${year}`;
}

export async function updateDjHeartbeatWeeklyPlaylist(
  djHeartbeatAccessToken: string,
  djHeartbeatUserId: string,
  spotifyTrackIds: string[],
  sumOfAllCountedHearbeats: number
): Promise<IUserPlaylist> {
  const playlist = await findOrCreateDJHeartbeatPlaylist(
    djHeartbeatAccessToken,
    djHeartbeatUserId
  );

  await clearDefaultPlaylist(djHeartbeatAccessToken, djHeartbeatUserId);

  try {
    await addTracksToSpotifyPlaylist(
      djHeartbeatAccessToken,
      spotifyTrackIds,
      playlist
    );
  } catch (error) {
    console.log("error adding tracks to spotify playlist: ", error);
  }

  const newDescription = `updated ${getDayOfWeekTimeOfDayText()}. ${formatNumberToReadableString(
    sumOfAllCountedHearbeats
  )} musical heartbeats so far this week`;
  await editSpotifyPlaylistDescription(
    djHeartbeatAccessToken,
    playlist.getThirdPartyId(),
    newDescription
  );

  await pullDefaultPlaylistFromSpotify(
    djHeartbeatAccessToken,
    djHeartbeatUserId
  );

  return playlist;
}

async function addTracksToSpotifyPlaylist(
  spotifyAccessToken: string,
  spotifyTrackIds: string[],
  playlist: IUserPlaylist
) {
  return await addTracksToPlaylist({
    spotifyPlaylistId: playlist.getThirdPartyId(),
    spotifyTrackUris: spotifyTrackIds,
    accessToken: spotifyAccessToken,
  });
}

export async function addTrackToDefaultPlaylist(
  accessToken: string,
  userId: string,
  trackId: string
): Promise<PlaylistWithDuration> {
  const playlist = await findOrCreateDefaultPlaylist(accessToken, userId);
  console.log("trackId ~~", trackId);
  const track = await Track.findById(trackId);
  if (!track) throw new Error(`unable to find track with id ${trackId}`);
  const { playlistDurationMS, updatedPlaylist } = await addTrackToPlaylist(
    accessToken,
    playlist,
    track
  );
  // todo: remove `playlistDurationMS` after march 29 release. we sum up in client side
  return {
    ...updatedPlaylist.toJSON(),
    playlistDurationMS,
  };
}

export async function getDefaultPlaylistAndDuration(
  accessToken: string,
  userId: string
): Promise<PlaylistWithDuration> {
  const playlist = await findOrCreateDefaultPlaylist(accessToken, userId);
  return {
    ...playlist.toJSON(),
    // todo: remove `playlistDurationMS` after march 29 release. we sum up in client side
    playlistDurationMS: playlist.getTotalDurationMS(),
  };
}

export async function clearDefaultPlaylist(
  accessToken: string,
  userId: string
) {
  await pullDefaultPlaylistFromSpotify(accessToken, userId);
  const playlist = await findOrCreateDefaultPlaylist(accessToken, userId);
  const spotifyTrackUris = playlist.tracks.map(
    (t) => `spotify:track:${t.thirdPartyId}`
  );

  await removeTracksFromPlaylist({
    accessToken,
    spotifyPlaylistId: playlist.getThirdPartyId(),
    spotifyTrackUris,
  });

  return await pullDefaultPlaylistFromSpotify(accessToken, userId);
}

export async function pullDefaultPlaylistFromSpotify(
  accessToken: string,
  userId: string
) {
  const userPlaylist = await findOrCreateDefaultPlaylist(accessToken, userId);

  const fetchedPlaylist = await fetchPlaylist(
    accessToken,
    userPlaylist.getThirdPartyId()
  );

  const spotifyTrackIds = fetchedPlaylist.tracks.items.map((t) => t.track?.id);
  const missingTrackIds = await findMissingTrackIds(spotifyTrackIds);

  const missingTracks = await fetchTracks(accessToken, missingTrackIds);
  await saveTracks(missingTracks);
  const dbTracks = await Track.find({
    thirdPartyId: { $in: spotifyTrackIds },
  });

  const spotifyTrackIdsUniqueCount = new Set(spotifyTrackIds).size;

  if (dbTracks.length !== spotifyTrackIdsUniqueCount) {
    throw new Error(
      "Missing spotify tracks in db... dbTracks.length:" +
        dbTracks.length +
        "new Set(spotifyTrackIds).size" +
        new Set(spotifyTrackIds).size
    );
  }

  return await clearAndOverwritePlaylistTracksInDB(userPlaylist, dbTracks);
}

async function saveTracks(tracks: SpotifyApi.TrackObjectFull[]) {
  const tracksFormatted = tracks.map((t): Exclude<ITrack, "_id"> => {
    return {
      name: t.name,
      thirdPartyId: t.id,
      artist: t.artists[0].name,
      trackDurationMS: t.duration_ms,
      albumArtUrl: t.album.images[0].url,
      fullApiResponse: t as unknown,
      provider: "spotify",
    } as Exclude<ITrack, "_id">;
  });
  await Track.saveMany(tracksFormatted);
}

export async function archivePreviousAndCreateNewDefaultPlaylist(
  accessToken: string,
  userId: string
) {
  const playlist = await UserPlaylist.findDefaultPlaylist(userId);

  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  if (playlist.createdAt <= startOfMonth) {
    console.log("archiving playlist for userId: ", userId);
    playlist.status = PlaylistStatus.INACTIVE;
    try {
      await playlist.save();
    } catch (e) {
      console.log("error archiving playlist: ", e);
    }

    await findOrCreateDefaultPlaylist(accessToken, userId);
  } else {
    console.log(
      "playlist for userId: ",
      userId,
      " already created for this month"
    );
  }
}

export async function findAllPlaylistsForUser(userId: string) {
  const playlists = await UserPlaylist.find({ userId });
  return { playlists };
}

async function findOrCreateDefaultPlaylist(
  accessToken: string,
  userId: string
) {
  let playlist = await UserPlaylist.findDefaultPlaylist(userId);
  if (!playlist) {
    playlist = await createDefaultPlaylistForUser(accessToken, userId);
  }

  return playlist;
}

async function findOrCreateDJHeartbeatPlaylist(
  djHeartBeatAccessToken: string,
  djHeartBeatUserId: string
) {
  let playlist = await UserPlaylist.findDefaultPlaylist(djHeartBeatUserId);
  if (!playlist) {
    playlist = await createDJHeartbeatDefaultPlaylist(
      djHeartBeatAccessToken,
      djHeartBeatUserId
    );
  }

  return playlist;
}

async function clearAndOverwritePlaylistTracksInDB(
  userPlaylist: IUserPlaylistModel,
  tracks: ITrack[]
) {
  userPlaylist.tracks = tracks;
  return await userPlaylist.save();
}

async function addTrackToPlaylist(
  accessToken: string,
  userPlaylist: IUserPlaylistModel,
  track: ITrackDocument
) {
  await addToPlaylist({
    accessToken: accessToken,
    spotifyTrackUri: track.spotifyUri,
    spotifyPlaylistId: userPlaylist.getThirdPartyId(),
  });
  await userPlaylist.addTrack(track._id);
  const updatedPlaylist = await UserPlaylist.findPlaylistById(userPlaylist._id);
  return {
    playlistDurationMS: updatedPlaylist.getTotalDurationMS(),
    updatedPlaylist,
  };
}

async function createDefaultPlaylistForUser(
  accessToken: string,
  userId: string
) {
  const spotifyUserId = userId.split(":")[1];
  const remotePlaylist = await createPlaylist({
    accessToken: accessToken,
    spotifyUserId: spotifyUserId,
    playlistName: DEFAULT_PLAYLIST_PARAMS.name,
    playlistDescription: DEFAULT_PLAYLIST_PARAMS.decsription,
    playistIsPublic: DEFAULT_PLAYLIST_PARAMS.isPublic,
  });

  const playlist = UserPlaylist.createDefaultPlaylist(
    DEFAULT_PLAYLIST_PARAMS.name,
    userId,
    remotePlaylist.spotifyUrl,
    remotePlaylist.spotifyUri
  );
  return playlist;
}

async function createDJHeartbeatDefaultPlaylist(
  djHeartbeatAccessToken: string,
  djHeartbeatUserId: string
) {
  const spotifyUserId = djHeartbeatUserId.split(":")[1];
  const remotePlaylist = await createPlaylist({
    accessToken: djHeartbeatAccessToken,
    spotifyUserId: spotifyUserId,
    playlistName: DEFAULT_DJ_HEARTBEAT_PLAYLIST_NAME,
    playlistDescription: "",
    playistIsPublic: true,
  });

  const playlist = UserPlaylist.createDefaultPlaylist(
    getDefaultPlaylistName(),
    djHeartbeatUserId,
    remotePlaylist.spotifyUrl,
    remotePlaylist.spotifyUri
  );
  return playlist;
}

async function findMissingTrackIds(spotifyTrackIds) {
  const foundTracks = await Track.find({
    thirdPartyId: { $in: spotifyTrackIds },
  }).select("thirdPartyId -_id");

  const foundTrackIds = foundTracks.map((track) => track.thirdPartyId);

  const missingTrackIds = spotifyTrackIds.filter(
    (id) => !foundTrackIds.includes(id)
  );

  return missingTrackIds;
}
