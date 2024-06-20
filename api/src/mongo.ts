import { connect, disconnect } from "mongoose";

export const mongoConnectionString =
  "mongodb+srv://heart-charts-api:myGrGgRSPgDlW5j7@cluster0.j8u4czk.mongodb.net/heart-charts?retryWrites=true&w=majority";

export async function connectToDB() {
  await connect(mongoConnectionString);
}

export function disconnectFromDB() {
  return disconnect();
}
