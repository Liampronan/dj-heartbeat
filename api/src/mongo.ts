import { connect, disconnect } from "mongoose";
import { config } from "./config";

export const mongoConnectionString = config.mongoDBConnectionUri;

export async function connectToDB() {
  await connect(mongoConnectionString);
}

export function disconnectFromDB() {
  return disconnect();
}
