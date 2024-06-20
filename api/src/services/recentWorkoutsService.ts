import { UserWorkout } from "../models/UserWorkout";

export async function fetchRecentWorkouts(userId: string) {
  const workouts = await UserWorkout.find({ userId })
    .sort({ startDate: "desc" })
    .limit(15);

  return workouts;
}
