import { Waitlist } from "../models/Waitlist";

export async function addToWaitlist(email: string) {
  await Waitlist.create({ email });
}
