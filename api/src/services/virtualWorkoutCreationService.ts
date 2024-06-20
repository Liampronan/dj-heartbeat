import { ClassCategory } from "peloton-client-node/dist/interfaces/options";
import { PelotonRideDetails } from "../models/PelotonRideDetails";
import { ITrackDocument, Track } from "../models/Track";
import {
  UserWorkout,
  WorkoutType,
  WorkoutUserSource,
} from "../models/UserWorkout";
import { getStartOfTodayPacific } from "../time";
import { IUserListen, ListenType, UserListen } from "../models/UserListen";
import {
  calculateAndUpdateTotalWeeklyHeartbeats,
  incrementWeeklyTrackHeartbeatCounter,
  updateTracksLastListenedAt,
} from "./handleWorkoutService";
import { enqueueUpdateSpotifyDJHeartbeatPlaylistJob } from "../jobs/updateSpotifyDJHeartbeatPlaylist";
import { getRandomElement, getRandomNumberBetween } from "../lib/helpers";
import { addSecondsToDate } from "../lib/date";

const allVirtualUserIds = [
  "mileystan",
  "bikesavage",
  "runningtoeat",
  "pumpfiend",
  "litlifts",
];

const VIRTUAL_AVG_HR_MIN = 110;
const VIRTUAL_AVG_HR_MAX = 170;

export async function createVirtualWorkout() {
  const virtualUserId = await findNextVirtualUser();
  if (!virtualUserId)
    throw new Error("no virtualUserId found for createVirtualWorkout");
  const { foundTracks, workoutType, pelotonRideDetailsId } =
    await getNextPelotonWorkoutPlaylist();

  const startHeartRate = 105;
  const virtualAvgHR = getRandomNumberBetween(
    VIRTUAL_AVG_HR_MIN,
    VIRTUAL_AVG_HR_MAX
  );

  const userListens = await createUserListenForTracks(
    foundTracks,
    startHeartRate,
    virtualAvgHR,
    virtualUserId
  );
  const userWorkout = await createVirtualUserWorkout(
    userListens,
    workoutType,
    virtualUserId
  );
  await handleCalculations(userListens);
  console.log("deleting pelotonRideDetailsId: ", pelotonRideDetailsId);
  await PelotonRideDetails.findByIdAndDelete(pelotonRideDetailsId);
  return userWorkout;
}

async function handleCalculations(userListens: IUserListen[]) {
  const totalHeartbeats = userListens.reduce(
    (acc, listen) => acc + listen.totalHeartbeats,
    0
  );
  await calculateAndUpdateTotalWeeklyHeartbeats(totalHeartbeats);
  for (const listen of userListens) {
    await incrementWeeklyTrackHeartbeatCounter(
      listen.totalHeartbeats,
      listen.track
    );
  }

  await updateTracksLastListenedAt(userListens);
  await enqueueUpdateSpotifyDJHeartbeatPlaylistJob();
}
async function createUserListenForTracks(
  tracks: ITrackDocument[],
  startingHeartRate: number,
  maxHeartRate: number,
  userId: string
) {
  // Calculate the total duration of all tracks in seconds
  const totalDurationSeconds = tracks.reduce(
    (sum, track) => sum + track.trackDurationMS / 1000,
    0
  );
  const endDate = new Date();
  const workoutStartDate = new Date(
    endDate.getTime() - totalDurationSeconds * 1000
  );

  // Define the peak time at 75% of the total duration
  const peakTimeSeconds = totalDurationSeconds * 0.75;

  let currentTime = 0; // Start at the beginning of the workout

  const userListens = tracks.map(async (track) => {
    const durationInSeconds = track.trackDurationMS / 1000;
    const startTrackTime = currentTime;
    const endTrackTime = currentTime + durationInSeconds;

    // Calculate average heart rate for the track
    const avgHeartRate = calculateHeartRateForTrack(
      currentTime,
      endTrackTime,
      peakTimeSeconds,
      startingHeartRate,
      maxHeartRate
    );

    // Update current time to the end of this track
    currentTime = endTrackTime;

    return UserListen.create({
      track: track,
      totalHeartbeats: (avgHeartRate * durationInSeconds) / 60,
      listenedAt: addSecondsToDate(workoutStartDate, startTrackTime),
      userId,
      listenType: ListenType.WORKOUT,
    });
  });

  return Promise.all(userListens);
}

function calculateHeartRateForTrack(
  startTime: number,
  endTime: number,
  peakTime: number,
  startHR: number,
  maxHR: number
): number {
  // Create a simple linear increase to peak, and then decrease
  const heartRateStart = linearHeartRate(startTime, peakTime, startHR, maxHR);
  const heartRateEnd = linearHeartRate(endTime, peakTime, startHR, maxHR);

  // Average heart rate over the duration of the track
  return (heartRateStart + heartRateEnd) / 2;
}

function linearHeartRate(
  time: number,
  peakTime: number,
  startHR: number,
  maxHR: number
): number {
  if (time <= peakTime) {
    // Linear increase from startHR to maxHR
    return startHR + (maxHR - startHR) * (time / peakTime);
  } else {
    // Linear decrease from maxHR back towards startHR
    return (
      maxHR -
      (maxHR - startHR) *
        ((time - peakTime) / ((peakTime * 1) / 0.75 - peakTime))
    );
  }
}

async function createVirtualUserWorkout(
  userListens: IUserListen[],
  workoutType: WorkoutType,
  virtualUserId: string
) {
  userListens.sort(
    (listenA, listenB) =>
      listenA.listenedAt.getTime() - listenB.listenedAt.getTime()
  );
  const startDate = userListens[0].listenedAt;
  const lastListen = userListens[userListens.length - 1];
  const endDate = addSecondsToDate(
    lastListen.listenedAt,
    (lastListen.track as unknown as ITrackDocument).trackDurationMS / 1000
  );
  const totalHeartbeats = userListens.reduce(
    (acc, listen) => acc + listen.totalHeartbeats,
    0
  );
  const userWorkout = new UserWorkout({
    startDate,
    endDate,
    totalHeartbeats,
    userId: virtualUserId,
    workoutType,
    workoutUserSource: WorkoutUserSource.Virtual,
  });
  await userWorkout.save();
  return userWorkout;
}

const MINIMUM_FETCHED_TRACKS_FOR_USABLE_PLAYLIST = 5;
async function getNextPelotonWorkoutPlaylist() {
  const pelotonRideDetails = await PelotonRideDetails.findOne({
    playlistFetchedTrackCount: {
      $gt: MINIMUM_FETCHED_TRACKS_FOR_USABLE_PLAYLIST,
    },
  });
  if (!pelotonRideDetails) {
    throw new Error("error finding next PelotonRideDetails");
  }
  const foundTracks: ITrackDocument[] = [];
  for (const item of pelotonRideDetails.playlistTracksWithArtists) {
    const track = await Track.findOne({
      // for now, just match on title. adds a little chaos into the system but gets a higher hit rate.
      //   artist: item.artists[0].artist_name,
      name: item.title,
    });
    if (track) {
      foundTracks.push(track);
    }
  }

  console.log("pelotonRideDetails id", pelotonRideDetails.id);
  console.log("found tracks length", foundTracks.length);
  const workoutType: WorkoutType = getWorkoutTypeFromPelotonCategory(
    pelotonRideDetails.category as ClassCategory
  );
  return {
    foundTracks,
    workoutType,
    pelotonRideDetailsId: pelotonRideDetails._id,
  };
}

function getWorkoutTypeFromPelotonCategory(pelotonCategory: ClassCategory) {
  let workoutType: WorkoutType;
  switch (pelotonCategory) {
    case ClassCategory.CYCLING:
      workoutType = WorkoutType.Cycling;
      break;
    case ClassCategory.RUNNING:
      workoutType = WorkoutType.Running;
      break;
    case ClassCategory.STENGTH:
      workoutType = WorkoutType.Lifting;
      break;
    default:
      workoutType = WorkoutType.Other;
  }

  return workoutType;
}

async function findNextVirtualUser() {
  const todaysVirtualWorkouts = await UserWorkout.find({
    workoutUserSource: WorkoutUserSource.Virtual,
    startDate: { $gte: getStartOfTodayPacific() },
  }).select("userId");

  const todaysVirtualUserIds = todaysVirtualWorkouts.map(
    (result) => result.userId
  );

  const remainingVirtualUIDsForToday = allVirtualUserIds.filter(
    (virtualUID) => !todaysVirtualUserIds.includes(virtualUID)
  );

  return getRandomElement(remainingVirtualUIDsForToday);
}
