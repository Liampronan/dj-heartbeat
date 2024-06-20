import { Track } from "../models/Track";
import { enqueueEnrichAudioFeaturesJob } from "../jobs/enrichTrackAudioFeatures";
import { connectToDB, disconnectFromDB } from "../mongo";

async function run() {
  await connectToDB();
  const tracks = await Track.find({ audioFeatures: undefined }).limit(30);
  const trackIds = tracks.map((t) => t.id);
  console.log("... migrating trackIds", trackIds);

  for (const trackId of trackIds) {
    await enqueueEnrichAudioFeaturesJob(trackId);
  }

  await disconnectFromDB();
}

void run();
