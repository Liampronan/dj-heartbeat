const DJ_HEARTBEAT_SPOTIFY_ID = "spotify:3137zfzo7puj4dar5sef2w52k4s4";

import { config } from "../config";
config.ensureInitialConfig();
import "../models/Track"; // there is a dependency on Track in this current file. this helps avoid errors (mainly in migrations)
import { ITrack } from "../models/Track";
import { connectToDB, disconnectFromDB } from "../mongo";
import { fetchUserSpotifyAuth } from "../services/spotifyAuthService";
import { getTopTracks } from "../services/topTracksService";
import { updateDjHeartbeatWeeklyPlaylist } from "../services/userPlaylistService";

async function run() {
  await connectToDB();
  const auth = await fetchUserSpotifyAuth(DJ_HEARTBEAT_SPOTIFY_ID);

  const { thisWeek } = await getTopTracks();
  const topTrackSpotifyIds = thisWeek.topTracks.map(
    (t) => `spotify:track:${(t.track as unknown as ITrack).thirdPartyId}`
  );
  const res = await updateDjHeartbeatWeeklyPlaylist(
    auth.accessToken,
    DJ_HEARTBEAT_SPOTIFY_ID,
    topTrackSpotifyIds,
    thisWeek.sumOfAllCountedHearbeats
  );
  console.log("res", res);
  await disconnectFromDB();
}

void run();
