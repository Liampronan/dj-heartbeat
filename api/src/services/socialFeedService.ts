import { IUserListen, UserListen } from "../models/UserListen";
import { IUserWorkout, UserWorkout, WorkoutType } from "../models/UserWorkout";

interface FeedItem {
  userListens: IUserListen[];
  userName: string;
  username: string;
  workoutEndDate: Date;
  workoutType: WorkoutType;
}

export async function fetchTodayYesterdaySocialFeed() {
  const userWorkouts = await UserWorkout.find().sort({ endDate: -1 }).limit(10);

  const fetchUserListenPromises = userWorkouts.map((workout) =>
    UserListen.findTracksForUserWorkout(workout)
  );

  const userListensResults = await Promise.all(fetchUserListenPromises);
  const feedItems: FeedItem[] = [];
  userListensResults.forEach((userListens, i) => {
    // only include workouts with associated music.
    if (userListens.length == 0) {
      return;
    }
    feedItems.push({
      userListens,
      userName: getUserName(userWorkouts[i]), // cleanup: remove may after first release of may
      username: getUserName(userWorkouts[i]),
      workoutEndDate: userWorkouts[i].endDate,
      workoutType: userWorkouts[i].workoutType,
    });
  });

  return {
    today: { feedItems },
    yesterday: { feedItems }, // TODO: replaceme with yesterday
  };
}

function getUserName(userWorkout: IUserWorkout) {
  const baseUserName = userWorkout.userId.replace("spotify:", "");
  return `@${baseUserName}`;
}
