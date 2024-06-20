import { Schema, model } from "mongoose";

export interface IDebugLog {
  type: string;
  data: object;
}

const debugLogSchema = new Schema<IDebugLog>(
  {
    type: { type: String, required: true },
    data: { type: Schema.Types.Mixed, required: true },
  },
  { timestamps: true }
);

export const DebugLog = model<IDebugLog>("DebugLog", debugLogSchema);
