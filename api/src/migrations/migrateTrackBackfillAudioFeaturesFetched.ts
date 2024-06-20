import { connectToDB, disconnectFromDB } from "../mongo";
import { ITrackDocument, Track } from "../models/Track";

async function run() {
  await connectToDB();
  const tracks = await Track.find().select("-fullApiResponse");
  if (!tracks) throw new Error("no tracks found");

  console.log("updating for numUserListens: ", tracks.length);
  let updateCount = 0;
  for (const track of tracks) {
    await updateTrack(track);
    console.log(`updated ${++updateCount} of ${tracks.length} userListens`);
  }

  await disconnectFromDB();
}

async function updateTrack(track: ITrackDocument) {
  console.log(run);
  console.log(
    "updating track",
    track.id,
    "track audio features",
    track.audioFeatures?.tempo
  );
  track.audioFeaturesFetched = !!track.audioFeatures;
  await track.save();
}
