import { Schema, model } from "mongoose";

interface IWeeklyTotalHeartbeatCounter {
  weekStartAt: Date;
  totalHeartbeats: number;
}

const weeklyHeartbeatCounterSchema = new Schema<IWeeklyTotalHeartbeatCounter>(
  {
    weekStartAt: { type: Date, required: true },
    totalHeartbeats: { type: Number, default: 0 },
  },
  { timestamps: true }
);

export const WeeklyTotalHeartbeatCounter = model<IWeeklyTotalHeartbeatCounter>(
  "WeeklyHeartbeatCounter",
  weeklyHeartbeatCounterSchema
);
