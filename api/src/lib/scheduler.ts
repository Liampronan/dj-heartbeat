import { ScheduledEvent, onSchedule } from "firebase-functions/v2/scheduler";
import { connectToDB, disconnectFromDB } from "../mongo";

type ScheduledJob = (event: ScheduledEvent) => void;

const HOURLY_CRON_SYNTAX = "0 * * * *";
// run at 8am UTC so it's 12am or 1am in Pacific Time (depending on DST)
const DAILY_CRON_SYNTAX = "0 8 * * *";

export function createHourlyScheduledJob(job: ScheduledJob) {
  return createScheduledJob(HOURLY_CRON_SYNTAX, job);
}

export function createDailyScheduledJob(job: ScheduledJob) {
  return createScheduledJob(DAILY_CRON_SYNTAX, job);
}

function createScheduledJob(cronSyntax: string, job: ScheduledJob) {
  return onSchedule(cronSyntax, async (event) => {
    await connectToDB();

    await job(event);
    await disconnectFromDB();
  });
}
