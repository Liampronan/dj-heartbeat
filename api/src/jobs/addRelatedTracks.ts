import { getFunctions } from "firebase-admin/functions";

import { TaskFunctionRequest, getAsyncJobFunctionUrl } from "../lib/queue";
import { generateRelatedTracks } from "../services/trackRecommendationsService";

const JOB_NAME = "addRelatedTracksSpotify";

export async function enqueueAddRelatedTracksSpotifyJob(trackIds: string[]) {
  const queue = getFunctions().taskQueue(JOB_NAME);
  //  we could probs cache this function. for now, it maybe helps as a natural rate limiter (since it makes http request) ... maybe.
  const targetUri = await getAsyncJobFunctionUrl(JOB_NAME);

  for (const trackId of trackIds) {
    await queue.enqueue(
      { trackId },
      {
        dispatchDeadlineSeconds: 15,
        uri: targetUri,
      }
    );
  }
}

export const addRelatedTracksSpotify = async (req: TaskFunctionRequest) => {
  const trackId = req.data.trackId;

  if (!trackId) {
    throw new Error(`${JOB_NAME} error: missing trackId ${trackId}`);
  }
  await generateRelatedTracks(trackId);
};
