import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { GoogleAuth } from "google-auth-library";
import { Request } from "firebase-functions/v2/tasks";
import { connectToDB } from "../mongo";

export const DEFAULT_MAX_RETRY_COUNT = 1;
const DEFAULT_MIN_BACK_OFF_SECONDS = 1;
const DEFAULT_MAX_CONCURRENT_DISPATCHES = 1;
const DEFAULT_DISPATCHES_PER_SECOND = 1;

export type TaskFunctionRequest = Request;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
// for now use any. longer term, we should figure out a way to nicely type job params
type WorkerFunction = (req: TaskFunctionRequest) => Promise<void>;

export const createCloudJob = (workFn: WorkerFunction) => {
  return onTaskDispatched(
    {
      retryConfig: {
        maxAttempts: DEFAULT_MAX_RETRY_COUNT,
        minBackoffSeconds: DEFAULT_MIN_BACK_OFF_SECONDS,
      },
      rateLimits: {
        maxConcurrentDispatches: DEFAULT_MAX_CONCURRENT_DISPATCHES,
        maxDispatchesPerSecond: DEFAULT_DISPATCHES_PER_SECOND,
      },
    },
    async (req) => {
      await connectToDB();
      const retryCount = Number(
        req.headers?.["x-cloudtasks-taskretrycount"] ?? 0
      );

      try {
        await workFn(req);
      } catch (error) {
        // if we're only retrying once, then skip throwing error bc the job error will be thrown. if we improve retry logic and make DEFAULT_MAX_RETRY_COUNT > 1 then revisit i think.
        if (retryCount > 0 && retryCount === DEFAULT_MAX_RETRY_COUNT - 1) {
          throw new Error(
            `Max retry for job ${req.queueName} with req.data: ${req.data}`
          );
        }
        throw error;
      }
    }
  );
};

// cache this auth object bc it is called in serverless fn which will generally persist object between runs.
// see: https://firebase.google.com/docs/functions/tips#use_global_variables_to_reuse_objects_in_future_invocations
let auth;
export async function getAsyncJobFunctionUrl(name, location = "us-central1") {
  if (!auth) {
    auth = new GoogleAuth();
  }
  const projectId = await auth.getProjectId();
  const url =
    "https://cloudfunctions.googleapis.com/v2beta/" +
    `projects/${projectId}/locations/${location}/functions/${name}`;

  const client = await auth.getClient();
  const res = await client.request({ url });
  const uri = res.data?.serviceConfig?.uri;
  if (!uri) {
    throw new Error(`Unable to retreive uri for function at ${url}`);
  }
  return uri;
}
