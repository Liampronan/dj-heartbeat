import { UserFeedback } from "../models/UserFeedback";

export async function handleUserFeedback(
  feedback: string,
  userId: string,
  contact: string
) {
  await UserFeedback.create({ feedback, userId, contact });
}
