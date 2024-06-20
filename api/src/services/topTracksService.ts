import { WeeklyTotalHeartbeatCounter } from "../models/WeeklyTotalHeartbeatCounter";
import { WeeklyTrackHeartbeatCounter } from "../models/WeeklyTrackHeartbeatCounter";
import { getLastSunday, getTwoSundaysAgo } from "../time";

export async function getTopTracks() {
  const thisWeek = {
    topTracks: await WeeklyTrackHeartbeatCounter.findThisWeeksTopTracks(),
    sumOfAllCountedHearbeats: await getThisWeeksTotalHeartbeats(),
  };
  const lastWeek = {
    topTracks: await WeeklyTrackHeartbeatCounter.findLastWeeksTopTracks(),
    sumOfAllCountedHearbeats: await getLastWeeksTotalHeartbeats(),
  };

  return { thisWeek, lastWeek };
}

async function getLastWeeksTotalHeartbeats() {
  let counter = await WeeklyTotalHeartbeatCounter.findOne({
    weekStartAt: getTwoSundaysAgo(),
  });

  if (!counter) {
    counter = new WeeklyTotalHeartbeatCounter({
      weekStartAt: getTwoSundaysAgo(),
    });
    await counter.save();
  }

  return Math.round(counter.totalHeartbeats);
}

async function getThisWeeksTotalHeartbeats() {
  let counter = await WeeklyTotalHeartbeatCounter.findOne({
    weekStartAt: getLastSunday(),
  });
  if (!counter) {
    counter = new WeeklyTotalHeartbeatCounter({
      weekStartAt: getLastSunday(),
    });
    await counter.save();
  }

  return Math.round(counter.totalHeartbeats);
}
