import { HydratedDocument, model, Model, Schema } from "mongoose";

interface IHeartRateInfo {
  startDate: Date;
  endDate: Date;
  value: number;
}

export enum WorkoutType {
  Lifting = "lifting",
  Running = "running",
  Walking = "walking",
  Cycling = "cycling",
  Other = "other",
}

export enum WorkoutUserSource {
  UserDevice = "userDevice",
  Virtual = "virtual",
}

export interface IUserWorkout {
  totalHeartbeats: number;
  heartRateInfo: IHeartRateInfo[];
  startDate: Date;
  endDate: Date;
  userId: string;
  workoutType: WorkoutType;
  workoutUserSource: WorkoutUserSource;
}

const heartRateInfoSchema = new Schema(
  {
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    value: { type: Number, required: true },
  },
  { _id: false }
);

const userWorkoutSchema = new Schema<IUserWorkout>(
  {
    totalHeartbeats: { type: Number, required: true },
    heartRateInfo: { type: [heartRateInfoSchema] },
    startDate: { type: Date, required: true, index: true },
    endDate: { type: Date, required: true, index: true },
    userId: { type: String, required: true, index: true },
    workoutType: {
      type: String,
      values: Object.values(WorkoutType),
      default: WorkoutType.Other,
    },
    workoutUserSource: {
      type: String,
      values: Object.values(WorkoutUserSource),
      default: WorkoutUserSource.UserDevice,
    },
  },
  { timestamps: true }
);

userWorkoutSchema.index(
  { startDate: 1, endDate: 1, userId: 1 },
  { unique: true }
);

userWorkoutSchema.index({ userId: 1, startDate: -1 }, { unique: true });
userWorkoutSchema.index({ workoutUserSource: 1, startDate: -1 });

// statics
interface UserWorkoutModel extends Model<IUserWorkout> {
  findWorkout(
    startDate: Date,
    endDate: Date,
    userId: string
  ): Promise<HydratedDocument<IUserWorkout>>;
  findUniqueUsersWithWorkouts(): Promise<string[]>;
}

userWorkoutSchema.static(
  "findWorkout",
  function findWorkout(startDate: Date, endDate: Date, userId: string) {
    return this.findOne({
      startDate,
      endDate,
      userId,
    });
  }
);

userWorkoutSchema.static(
  "findUniqueUsersWithWorkouts",
  async function findUniqueUsersWithWorkouts() {
    const uniqueIds: { userId: string }[] = await this.aggregate([
      { $match: { workoutUserSource: WorkoutUserSource.UserDevice } },
      { $group: { _id: "$userId", count: { $sum: 1 } } },
      { $project: { _id: 0, userId: "$_id" } },
    ]);

    return uniqueIds.map((uId) => uId.userId);
  }
);

export const UserWorkout = model<IUserWorkout, UserWorkoutModel>(
  "UserWorkout",
  userWorkoutSchema
);
