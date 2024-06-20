import { Schema, model } from "mongoose";

export interface ISignupCode {
  code: string;
}

const signupCodeSchema = new Schema<ISignupCode>(
  {
    code: { type: String, required: true, unique: true },
  },
  { timestamps: true }
);

export const SignupCode = model<ISignupCode>("SignupCode", signupCodeSchema);
