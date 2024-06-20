import { SignupCode } from "../models/SignupCode";

export async function validateSignupCode(code) {
  const foundCode = await SignupCode.findOne({ code });
  return !!foundCode;
}
