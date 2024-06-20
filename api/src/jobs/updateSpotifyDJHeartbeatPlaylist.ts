const DJ_HEARTBEAT_SPOTIFY_ID = "spotify:3137zfzo7puj4dar5sef2w52k4s4";

import { config } from "../config";
config.ensureInitialConfig();
import "../models/Track"; // there is a dependency on Track in this current file. this helps avoid errors (mainly in migrations)
import { ITrack } from "../models/Track";
import { fetchUserSpotifyAuth } from "../services/spotifyAuthService";
import { getTopTracks } from "../services/topTracksService";
import { updateDjHeartbeatWeeklyPlaylist } from "../services/userPlaylistService";

import { getFunctions } from "firebase-admin/functions";

import { TaskFunctionRequest, getAsyncJobFunctionUrl } from "../lib/queue";

const JOB_NAME = "updateSpotifyDJHeartbeatPlaylist";

export async function enqueueUpdateSpotifyDJHeartbeatPlaylistJob() {
  const queue = getFunctions().taskQueue(JOB_NAME);
  //  we could probs cache this function. for now, it maybe helps as a natural rate limiter (since it makes http request) ... maybe.
  const targetUri = await getAsyncJobFunctionUrl(JOB_NAME);

  await queue.enqueue(
    {},
    {
      dispatchDeadlineSeconds: 15,
      uri: targetUri,
    }
  );
}

export const updateSpotifyDJHeartbeatPlaylist = async (
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _req: TaskFunctionRequest
) => {
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
  console.log("successfully updateDjHeartbeatWeeklyPlaylist", res);
};
