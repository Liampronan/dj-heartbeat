import { PelotonRideDetails } from "../models/PelotonRideDetails";
import { ITrackDocument, Track } from "../models/Track";
import { connectToDB, disconnectFromDB } from "../mongo";

async function runOne() {
  const { foundTracks, pelotonRideDetailsId } =
    await getNextPelotonWorkoutPlaylist();

  if (!pelotonRideDetailsId) {
    throw new Error("No pelotonRide found");
  }

  await PelotonRideDetails.findByIdAndUpdate(pelotonRideDetailsId, {
    playlistFetchedTrackCount: foundTracks.length,
  });

  console.log(
    "updated pelotonRideDetailsId: ",
    pelotonRideDetailsId,
    "with playlistFetchedTrackCount: ",
    foundTracks.length
  );
}

async function runMany() {
  await connectToDB();

  let progressCounter = 0;
  const totalItemsToMigrate = await PelotonRideDetails.countDocuments({
    playlistFetchedTrackCount: { $exists: false },
  });
  while (true) {
    await runOne();
    progressCounter += 1;
    console.log(`progress: ${progressCounter} / ${totalItemsToMigrate}`);
  }
  await disconnectFromDB();
}

async function getNextPelotonWorkoutPlaylist() {
  const pelotonRideDetails = await PelotonRideDetails.findOne({
    playlistFetchedTrackCount: { $exists: false },
  });
  if (!pelotonRideDetails) {
    throw new Error("error finding next PelotonRideDetails");
  }
  const foundTracks: ITrackDocument[] = [];
  for (const item of pelotonRideDetails.playlistTracksWithArtists) {
    const track = await Track.findOne({
      // for now, just match on title. adds a little chaos into the system but gets a higher hit rate.
      //   artist: item.artists[0].artist_name,
      name: item.title,
    });
    if (track) {
      foundTracks.push(track);
    }
  }

  console.log("pelotonRideDetails id", pelotonRideDetails.id);
  console.log("found tracks length", foundTracks.length);
  return {
    foundTracks,
    pelotonRideDetailsId: pelotonRideDetails._id,
  };
}

console.log(runMany);
