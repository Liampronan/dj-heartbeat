import { getFunctions } from "firebase-admin/functions";
import { TaskFunctionRequest, getAsyncJobFunctionUrl } from "../lib/queue";
import { getRandomNumberBetween } from "../lib/helpers";
import { createVirtualWorkout } from "../services/virtualWorkoutCreationService";

const JOB_NAME = "createOneVirtualWorkout";

const VIRTUAL_WORKOUT_TIME_RANGE_MINUTES = 14 * 60; // 14 hours * 60 minutes
const VIRTUAL_WORKOUT_BASE_DATE = new Date();
VIRTUAL_WORKOUT_BASE_DATE.setUTCHours(13, 0, 0, 0); // Set to 5 AM Pacific assuming UTC-8 for PST;

// queues up a few virtual workout creation jobs so that we have daily new data.
export async function enqueueDailyVirtualWorkoutsCreation() {
  const queue = getFunctions().taskQueue(JOB_NAME);
  const targetUri = await getAsyncJobFunctionUrl(JOB_NAME);

  const numJobsToCreate = getRandomNumberBetween(2, 5);

  let previousMinutes = 0;

  for (let i = 1; i <= numJobsToCreate; i++) {
    const randomTimeIncrement =
      previousMinutes +
      getRandomNumberBetween(
        1,
        Math.floor(
          (VIRTUAL_WORKOUT_TIME_RANGE_MINUTES - previousMinutes) /
            (numJobsToCreate - i + 1)
        )
      );

    // Ensure each job is scheduled after the previous one
    previousMinutes = randomTimeIncrement;
    const scheduleTime = new Date(
      VIRTUAL_WORKOUT_BASE_DATE.getTime() + randomTimeIncrement * 60000
    );

    await queue.enqueue(
      {},
      {
        scheduleTime,
        uri: targetUri,
      }
    );
  }
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export async function createOneVirtualWorkout(_req: TaskFunctionRequest) {
  await createVirtualWorkout();
}
