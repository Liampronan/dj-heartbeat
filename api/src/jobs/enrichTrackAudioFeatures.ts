import { getFunctions } from "firebase-admin/functions";

import { TaskFunctionRequest, getAsyncJobFunctionUrl } from "../lib/queue";
import { updateTrackAudioFeatures } from "../services/trackAudioFeaturesService";

const JOB_NAME = "enrichTrackAudioFeatureSpotify";
const SPREAD_DURATION_SECONDS = 60;

export async function enqueueEnrichAudioFeaturesJobs(trackIds: string[]) {
  const queue = getFunctions().taskQueue(JOB_NAME);
  const targetUri = await getAsyncJobFunctionUrl(JOB_NAME);

  // Calculate delay increment to spread jobs across n seconds
  const delayIncrement = SPREAD_DURATION_SECONDS / trackIds.length;
  trackIds.forEach(async (trackId, index) => {
    const delaySeconds = Math.round(delayIncrement * index);
    const scheduleTime = new Date(Date.now() + delaySeconds * 1000);

    await queue.enqueue(
      { trackId },
      {
        scheduleTime,
        uri: targetUri,
      }
    );
  });
}

export async function enqueueEnrichAudioFeaturesJob(trackId: string) {
  const queue = getFunctions().taskQueue(JOB_NAME);
  const targetUri = await getAsyncJobFunctionUrl(JOB_NAME);

  await queue.enqueue(
    { trackId },
    {
      dispatchDeadlineSeconds: 15,
      uri: targetUri,
    }
  );
}

export const enrichTrackAudioFeatureSpotify = async (
  req: TaskFunctionRequest
) => {
  const trackId = req.data.trackId;

  if (!trackId) {
    throw new Error(`${JOB_NAME} error: missing trackId ${trackId}`);
  }
  await updateTrackAudioFeatures(trackId);
};
