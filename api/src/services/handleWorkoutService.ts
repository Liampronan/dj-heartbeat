import { ObjectId } from "mongoose";
import { fetchUserSpotifyAuth } from "./spotifyAuthService";
import { getRecentlyPlayed } from "./spotifyAPIService";
import { saveUserListens } from "./userListensService";
import { getLastSunday } from "../time";
import { ITrack, Track } from "../models/Track";
import { IUserListen, UserListen, ListenType } from "../models/UserListen";
import { UserWorkout, WorkoutType } from "../models/UserWorkout";
import { WeeklyTotalHeartbeatCounter } from "../models/WeeklyTotalHeartbeatCounter";
import { WeeklyTrackHeartbeatCounter } from "../models/WeeklyTrackHeartbeatCounter";
import { enqueueUpdateSpotifyDJHeartbeatPlaylistJob } from "../jobs/updateSpotifyDJHeartbeatPlaylist";

export interface HeartRateInfo {
  startDate: Date;
  endDate: Date;
  value: number;
}

interface TimelineTrack {
  userListen: IUserListen;
  endDateISO: string;
  wasFullListen: boolean;
}

interface AttributedTrack {
  heartRateInfo: HeartRateInfo[];
  timelineTrack: TimelineTrack;
}

export async function handleWorkout(
  uid: string,
  heartRateInfo: HeartRateInfo[],
  workoutType: WorkoutType
): Promise<IUserListen[]> {
  if (!heartRateInfo) {
    throw new Error("Error with request: no heart rate info in body");
  }

  const startDate = new Date(heartRateInfo[0].startDate);
  const endDate = new Date(heartRateInfo[heartRateInfo.length - 1].endDate);
  const existingHandledWorkout = await UserWorkout.findWorkout(
    startDate,
    endDate,
    uid
  );
  if (existingHandledWorkout && existingHandledWorkout.userId) {
    const userListens = await UserListen.findTracksForUserWorkout(
      existingHandledWorkout
    );

    return userListens;
  }

  const totalHeartbeats = heartRateInfo.reduce(
    (acc, hrInfo) => acc + hrInfo.value,
    0
  );
  const userWorkout = new UserWorkout({
    startDate,
    endDate,
    heartRateInfo: heartRateInfo,
    totalHeartbeats,
    userId: uid,
    workoutType,
  });
  await userWorkout.save();

  await fetchAndStoreRecentlyPlayed(uid);

  const userListenWithoutHeartbeats =
    await UserListen.findUnprocessedTracksForUserWorkout(userWorkout);

  const timeline = constructTimeline(userListenWithoutHeartbeats);
  const attributedTimeline = attributeHeartBeats(
    timeline.tracksTimeline,
    heartRateInfo
  );

  await saveAttributedHeartBeats(attributedTimeline);

  const userListens = await UserListen.findTracksForUserWorkout(userWorkout);
  await enqueueUpdateSpotifyDJHeartbeatPlaylistJob();
  await updateTracksLastListenedAt(userListens);
  return userListens;
}

async function fetchAndStoreRecentlyPlayed(userId) {
  const authData = await fetchUserSpotifyAuth(userId);
  const recentlyPlayed = await getRecentlyPlayed(authData.accessToken);
  await saveUserListens(recentlyPlayed, userId);

  return recentlyPlayed;
}

// [MONGO MIGRATION] - it may be helpful to store this in db for debugging purposes. but for now, we can just use heartbeat count and save that.
function constructTimeline(userListens: IUserListen[]) {
  userListens = userListens.sort(
    (a, b) => a.listenedAt.getTime() - b.listenedAt.getTime()
  );
  const tracksTimeline: TimelineTrack[] = [];
  userListens.forEach((userListen, index) => {
    const additionalAttrs: { endDateISO?: string; wasFullListen?: boolean } =
      {};
    const listenedAtPlusTrackDuration = new Date(
      userListen.listenedAt.getTime() +
        //?? how to handle type for id which can then be populated?
        (userListen.track as unknown as ITrack).trackDurationMS
    );

    if (index >= userListens.length - 1) {
      additionalAttrs.endDateISO = listenedAtPlusTrackDuration.toISOString();
      additionalAttrs.wasFullListen = false; // this is maybe false... maybe true
    } else {
      // if the user's next listened overlaps with full-play duration of this track, then this track was cut short
      if (userListens[index + 1].listenedAt < listenedAtPlusTrackDuration) {
        additionalAttrs.endDateISO =
          userListens[index + 1].listenedAt.toISOString();
        additionalAttrs.wasFullListen = false;
      } else {
        additionalAttrs.endDateISO = listenedAtPlusTrackDuration.toISOString();
        additionalAttrs.wasFullListen = true;
      }
    }
    const timelineTrack = {
      userListen: userListen,
      endDateISO: additionalAttrs.endDateISO,
      wasFullListen: additionalAttrs.wasFullListen,
    };
    tracksTimeline.push(timelineTrack);
  });

  return { tracksTimeline };
}

export async function updateTracksLastListenedAt(userListens: IUserListen[]) {
  const updatePromises = userListens.map(_updateTrackLastListenedAt);
  try {
    await Promise.all(updatePromises);
  } catch (e) {
    console.log("error updateTracksLastListenedAt");
  }
}

function _updateTrackLastListenedAt(userListen: IUserListen): Promise<void> {
  return Track.findById(userListen.track).then((track) => {
    let promise;
    if (!track) {
      console.log(
        "_updateTrackLastListenedAt no track found for userListen ",
        userListen.id
      );
      promise = Promise.resolve();
    } else if (
      track.lastUserListenedAt &&
      track.lastUserListenedAt < userListen.listenedAt
    ) {
      console.log(
        "track.lastUserListenedAt < userListen.listenedAt ",
        userListen.id
      );
      promise = Promise.resolve();
    } else {
      console.log("track.lastUserListenedAt updating for ", userListen.id);
      track.lastUserListenedAt = userListen.listenedAt;
      promise = track?.save();
    }
    return promise;
  });
}

function attributeHeartBeats(
  tracks: TimelineTrack[],
  heartRateInfo: HeartRateInfo[]
) {
  const attributedTracks: AttributedTrack[] = [];
  tracks.forEach((track, index) => {
    tracks[index].userListen.totalHeartbeats = 0;
    attributedTracks.push({
      timelineTrack: track,
      heartRateInfo: [],
    });
    const heartbeatSamplesDuringTrack = heartRateInfo.filter(
      (hrSample: { startDate: Date }) => {
        return (
          new Date(hrSample.startDate) >= track.userListen.listenedAt &&
          new Date(hrSample.startDate).toISOString() <= track.endDateISO
        );
      }
    );

    heartbeatSamplesDuringTrack.forEach((hrSample, hrSampleIndex) => {
      if (hrSampleIndex == 0) {
        const sampleTimeMS =
          new Date(hrSample.startDate).getTime() -
          track.userListen.listenedAt.getTime();

        const sampleTimeSeconds = sampleTimeMS / 1000;
        const sampleTimeMinutes = sampleTimeSeconds / 60;
        const avgHRDuringThisPeriod = hrSample.value;
        tracks[index].userListen.totalHeartbeats +=
          avgHRDuringThisPeriod * sampleTimeMinutes;
        const formattedHRSample = {
          startDate: track.userListen.listenedAt,
          endDate: new Date(hrSample.startDate),
          value: hrSample.value,
        };
        attributedTracks[index].heartRateInfo.push(formattedHRSample);
      } else {
        const prevHRSample = heartbeatSamplesDuringTrack[hrSampleIndex - 1];
        const sampleTimeMS =
          new Date(hrSample.startDate).getTime() -
          new Date(prevHRSample.startDate).getTime();
        const sampleTimeSeconds = sampleTimeMS / 1000;
        const sampleTimeMinutes = sampleTimeSeconds / 60;

        const avgHRDuringThisPeriod = (hrSample.value + prevHRSample.value) / 2;
        tracks[index].userListen.totalHeartbeats +=
          avgHRDuringThisPeriod * sampleTimeMinutes;
        const formattedHRSample = {
          startDate: new Date(prevHRSample.startDate),
          endDate: new Date(hrSample.endDate),
          value: hrSample.value,
        };
        attributedTracks[index].heartRateInfo.push(formattedHRSample);
      }

      if (hrSampleIndex == heartbeatSamplesDuringTrack.length - 1) {
        const sampleTimeMS =
          new Date(track.endDateISO).getTime() -
          new Date(hrSample.startDate).getTime();
        const sampleTimeSeconds = sampleTimeMS / 1000;
        const sampleTimeMinutes = sampleTimeSeconds / 60;
        const avgHRDuringThisPeriod = hrSample.value;
        tracks[index].userListen.totalHeartbeats +=
          avgHRDuringThisPeriod * sampleTimeMinutes;
        const formattedHRSample = {
          startDate: new Date(hrSample.startDate),
          endDate: new Date(track.endDateISO),
          value: hrSample.value,
        };
        attributedTracks[index].heartRateInfo.push(formattedHRSample);
      }
    });
  });

  return attributedTracks;
}

async function saveAttributedHeartBeats(
  attributedHeartbeats: AttributedTrack[]
) {
  const dbUpdatePromises: Promise<void>[] = [];

  for (const attributedHeartbeat of attributedHeartbeats) {
    const promise = Track.findById(
      attributedHeartbeat.timelineTrack.userListen.track as unknown // fixme
    )
      .then(async (res) => {
        if (!res)
          throw new Error(
            `unable to find track with id: ${attributedHeartbeat.timelineTrack.userListen.track}`
          );
        const trackHeartbeats =
          attributedHeartbeat.timelineTrack.userListen.totalHeartbeats;
        const { _id: trackId } = res;
        await Promise.all([
          updateUserListenForWorkoutTrack(attributedHeartbeat, trackId),
          incrementWeeklyTrackHeartbeatCounter(trackHeartbeats, trackId),
        ]);
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .then(() => {}); // Resolve to void
    dbUpdatePromises.push(promise);
  }

  try {
    await Promise.all(dbUpdatePromises);
  } catch (e) {
    console.error("[incrementWeeklyCounter] Error adding document: ", e);
  }

  try {
    const sumOfNewHeartbeats = attributedHeartbeats.reduce(
      (acc, attrHB) => acc + attrHB.timelineTrack.userListen.totalHeartbeats,
      0
    );

    await calculateAndUpdateTotalWeeklyHeartbeats(sumOfNewHeartbeats);
  } catch (e) {
    console.error("error calculateAndUpdateTotalWeeklyHeartbeats", e);
  }
}

export async function incrementWeeklyTrackHeartbeatCounter(
  trackHeartbeats: number,
  trackId: ObjectId
) {
  const query = {
    track: trackId,
    weekStartAt: getLastSunday(),
  };
  const update = {
    $inc: {
      totalHeartbeats: trackHeartbeats,
    },
  };
  const opts = { upsert: true };
  await WeeklyTrackHeartbeatCounter.findOneAndUpdate(query, update, opts);
}

export async function updateUserListenForWorkoutTrack(
  attributedTrack: AttributedTrack,
  trackId: ObjectId
) {
  await UserListen.findOneAndUpdate(
    {
      track: trackId,
      listenedAt: attributedTrack.timelineTrack.userListen.listenedAt,
    },
    {
      totalHeartbeats: attributedTrack.timelineTrack.userListen.totalHeartbeats,
      listenType: ListenType.WORKOUT,
    }
  );
}

export async function calculateAndUpdateTotalWeeklyHeartbeats(
  sumOfNewHeartbeats: number
) {
  let counter = await WeeklyTotalHeartbeatCounter.findOne({
    weekStartAt: getLastSunday(),
  });
  if (!counter) {
    counter = new WeeklyTotalHeartbeatCounter({
      weekStartAt: getLastSunday(),
    });
  }

  counter.totalHeartbeats = counter.totalHeartbeats + sumOfNewHeartbeats;
  await counter.save();
}
