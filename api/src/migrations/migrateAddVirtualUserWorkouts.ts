import { config } from "../config";
config.ensureInitialConfig();
import { connectToDB, disconnectFromDB } from "../mongo";
import { createVirtualWorkout } from "../services/virtualWorkoutCreationService";

async function run() {
  await connectToDB();
  await createVirtualWorkout();
  await disconnectFromDB();
}

void run();
