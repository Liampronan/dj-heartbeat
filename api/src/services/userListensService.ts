import { ITrackDocument, Track } from "../models/Track";
import { IUserListen, UserListen, ListenType } from "../models/UserListen";

export async function saveUserListens(apiResponseItems: any[], uid: string) {
  const savedTracks = await _saveUserListenTracks(apiResponseItems);
  await _saveUserListens(apiResponseItems, uid, savedTracks);
}

async function _saveUserListenTracks(apiResponseItems: any[]) {
  const tracksFormatted = apiResponseItems.map((item) => {
    return {
      name: item.track.name,
      thirdPartyId: item.track.id,
      artist: item.track.artists[0].name,
      trackDurationMS: item.track.duration_ms,
      albumArtUrl: item.track.album.images[0].url,
      fullApiResponse: item,
      provider: "spotify",
    };
  });

  const result = await Track.saveMany(tracksFormatted);

  return result;
}

// TODO: clean up dupelicaton with above
export async function _saveTracksFromTrackRecommendations(
  apiResponse: SpotifyApi.RecommendationsFromSeedsResponse
) {
  const tracksFormatted = apiResponse.tracks.map((track) => {
    return {
      name: track.name,
      thirdPartyId: track.id,
      artist: track.artists[0].name,
      trackDurationMS: track.duration_ms,
      albumArtUrl: track.album.images[0].url,
      fullApiResponse: { track },
      provider: "spotify",
    };
  });

  const result = await Track.saveMany(tracksFormatted);

  return result;
}

async function _saveUserListens(
  apiResponseItems: any[],
  uid: string,
  savedTracks: ITrackDocument[]
) {
  const mongoDBWriteObjs: IUserListen[] = [];
  for (const item of apiResponseItems) {
    const trackId = savedTracks.find(
      (track) => track.thirdPartyId === item.track.id
    )?._id;

    if (!trackId) {
      console.warn("unable to find trackdId", trackId);
    }

    const userListen = new UserListen({
      track: trackId,
      listenedAt: item.played_at,
      listenType: ListenType.UNKNOWN,
      userId: uid,
    });
    mongoDBWriteObjs.push(userListen);
  }

  try {
    await UserListen.insertMany(mongoDBWriteObjs, { ordered: false });
  } catch (error) {
    console.log("error insertMany(mongoDBWriteObjs)", error);
  }
}
