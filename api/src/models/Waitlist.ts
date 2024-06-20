import { Schema, model } from "mongoose";

export interface IWaitlist {
  email: string;
}

const waitlistSchema = new Schema<IWaitlist>(
  {
    email: { type: String, required: true },
  },
  { timestamps: true }
);

export const Waitlist = model<IWaitlist>("Waitlist", waitlistSchema);
