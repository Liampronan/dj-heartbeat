import { Schema, model } from "mongoose";

export interface IUserFeedback {
  feedback: string;
  userId: string;
  contact: string;
}

const userFeedbackSchema = new Schema<IUserFeedback>(
  {
    feedback: { type: String, required: true },
    userId: { type: String, required: true },
    contact: { type: String },
  },
  { timestamps: true }
);

export const UserFeedback = model<IUserFeedback>(
  "UserFeedback",
  userFeedbackSchema
);
