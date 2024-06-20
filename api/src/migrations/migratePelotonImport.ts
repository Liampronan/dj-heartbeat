import { peloton } from "peloton-client-node";
import { RideDetailsResponse } from "peloton-client-node/dist/interfaces/responses";
import dotenv from "dotenv";
import { PelotonInfo } from "../models/PelotonInfo";
import { ClassCategory } from "peloton-client-node/dist/interfaces/options";
import { DebugLog } from "../models/DebugLog";
dotenv.config();

import { connectToDB, disconnectFromDB } from "../mongo";
import { PelotonRideDetails } from "../models/PelotonRideDetails";
import { spotifyQueryForTrack } from "../services/spotifyAPIService";
import { fetchUserSpotifyAuth } from "../services/spotifyAuthService";
import { Track } from "../models/Track";

const authenticate = async () => {
  await peloton.authenticate({
    username: process.env.PELOTON_USERNAME || "",
    password: process.env.PELOTON_PASSWORD || "",
  });
};

const fetchLatestClasses = async (classType: ClassCategory) => {
  const nextPageToFetch = await fetchNextClassPage();
  console.log("fetching class page", nextPageToFetch);
  const classesResult = await peloton.browseClasses(classType, nextPageToFetch);
  if (!classesResult.data || classesResult.data.length == 0) {
    await DebugLog.create({ type: "???", data: classesResult });
    console.log("classesResult", classesResult);
    throw new Error("empty classes result data");
  }

  for (const classResult of classesResult.data) {
    await PelotonInfo.create({
      type: "classDetails",
      classDetailsApiResponse: classResult,
    });
  }

  await DebugLog.findOneAndUpdate(
    { type: "peloton-class-page" },
    {
      data: {
        lastPageFetched: classesResult.page,
        totalPages: classesResult.page_count,
      },
    },
    {
      upsert: true,
    }
  );
};

// todo remove export
export const fetchAndSaveRideDetailsResponse = async (rideId) => {
  const result: RideDetailsResponse = await peloton.rideDetails({ rideId });
  await PelotonInfo.create({
    type: "rideDetails",
    rideDetailsApiResponse: result,
  });

  // await PelotonRideDetails.create({ fullApiResponse: result });
};

const runImportFromPeloton = async () => {
  await connectToDB();
  await authenticate();

  // eslint-disable-next-line no-constant-condition
  while (true) {
    console.log(fetchLatestClasses);
    // await fetchLatestClasses(ClassCategory.OUTDOOR);
    console.log("fetching next ride details");
    await fetchAndSaveNextRideDetails();
    console.log("backing off for a bit....");
    await delay(15000); // Wait for 15 seconds
  }

  await disconnectFromDB();
};

function getRandomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// note: import complete for now. >9k ridedetails so that's enough for like a year, nice. just keeping these functions around for posterity
async function fetchAndSaveNextRideDetails() {
  console.log(runImportFromPeloton);
  const classCategory: ClassCategory = getRandomElement([
    ClassCategory.RUNNING,
    ClassCategory.CYCLING,
    ClassCategory.STENGTH,
    ClassCategory.OUTDOOR,
  ]);
  // console.log("fetching details for rideId", rideId);
  console.log("classCategory", classCategory);
  const rideId = await PelotonInfo.findOneUnfetchedRideId(classCategory);
  console.log("fetching details for rideId", rideId);
  await fetchAndSaveRideDetailsResponse(rideId);
  await PelotonInfo.markRideClassDetailsAsFetched(rideId);
}

async function fetchNextClassPage() {
  const pageInfo = await DebugLog.findOne({ type: "peloton-class-page" });
  const lastPageFetched = (pageInfo as any).data.lastPageFetched;
  const totalPages = (pageInfo as any).data.totalPages;
  if (lastPageFetched === undefined)
    throw new Error("couldn't find lastPageFetched");
  const nextPage = lastPageFetched + 1;

  if (nextPage > totalPages) {
    throw new Error("can't find total pages");
  }
  return nextPage;
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function cleanup() {
  console.log(runImportFromPeloton);
  await connectToDB();
  console.log(await PelotonInfo.deleteAllClassDetails());
}

async function migrateOneRideDetailsToNewCollection() {
  await connectToDB();
  const rideDetailsPelotonInfo = await PelotonInfo.findOne({
    type: "rideDetails",
  });
  if (!rideDetailsPelotonInfo)
    throw new Error("no rideDetailsPelotonInfo found !!");
  console.log(
    "migrating: ridedetails ",
    rideDetailsPelotonInfo.rideDetailsApiResponse.ride.id
  );
  await PelotonRideDetails.createFromPelotonInfo(rideDetailsPelotonInfo);

  const newObj = await PelotonRideDetails.findOne({
    pelotonId: rideDetailsPelotonInfo.rideDetailsApiResponse.ride.id,
  });

  if (newObj) {
    console.log(
      "created obj for ride: ",
      newObj.pelotonId,
      " proceeding to delete pelotoninfo for that ride"
    );

    await PelotonInfo.findByIdAndDelete(rideDetailsPelotonInfo.id);

    const extraInDB = await PelotonInfo.deleteMany({
      "rideDetailsApiResponse.ride.id":
        rideDetailsPelotonInfo.rideDetailsApiResponse.ride.id,
    });

    console.log("extra cleaned up: ", extraInDB);
  }
}

async function migrateManyRideDetailsToNewColletion() {
  while (true) {
    await migrateOneRideDetailsToNewCollection();
  }
}

// this is just to get around ts / eslint issue with unused. probs a better way to ignore but this works atm.
console.log(
  cleanup,
  migrateManyRideDetailsToNewColletion,
  runImportFromPeloton
);

const DJ_HEARTBEAT_SPOTIFY_ID = "spotify:3137zfzo7puj4dar5sef2w52k4s4";
async function pullPlaylistFromSpotifyForOneRideDetails() {
  await connectToDB();
  const auth = await fetchUserSpotifyAuth(DJ_HEARTBEAT_SPOTIFY_ID);

  const rideDetails = await PelotonRideDetails.findOne({
    platlistFetchState: undefined,
  });
  if (!rideDetails) throw new Error("no ride details found");
  console.log(
    "fetching playlist tracks for pelotonRideDetails: ",
    rideDetails.id
  );
  let fetchCounter = 0;
  const songs = (
    rideDetails.playlist as {
      songs: { title: string; artists: { artist_name: string }[] }[];
    }
  ).songs;

  // Map each song to a promise representing the asynchronous operation
  const promises = songs.map(async (playlistSong) => {
    const title = (playlistSong as { title: string }).title;
    const firstArtist = (playlistSong as { artists: { artist_name: string }[] })
      .artists[0].artist_name;

    try {
      const trackResults = await spotifyQueryForTrack(title, auth.accessToken);
      if (!trackResults?.tracks)
        throw new Error("no tracks found in search results");
      // console.log(trackResults);
      console.log(trackResults.tracks.items[0].artists[0].name);
      console.log(trackResults.tracks.items[0].artists[0].name === firstArtist);

      const foundTrackWithMatchingArtist = trackResults.tracks.items.find(
        (item) => item.artists[0].name === firstArtist
      );

      if (foundTrackWithMatchingArtist) {
        try {
          await _saveTrackFromPeloton(foundTrackWithMatchingArtist);
          console.log("Track saved successfully.");
        } catch (error) {
          // Check if it's a duplicate key error
          if (error.code === 11000 || error.code === 11001) {
            console.error("Duplicate key error:", error.message);
          } else {
            throw error; // Rethrow other errors to be caught by the outer catch
          }
        }
        console.log("track saved");
        fetchCounter += 1; // Ensure fetchCounter is declared and managed properly outside this scope
      } else {
        console.log("error finding track ", title, " ", firstArtist);
      }
    } catch (error) {
      console.error(`Error processing song ${title}:`, error);
    }
  });

  // Wait for all the promises to resolve
  await Promise.all(promises);
  console.log(
    "fetchcounter: ",
    fetchCounter,
    "rideDetails.playlist.songs.length",
    (rideDetails.playlist as { songs: object[] }).songs.length
  );
  // removed
  // if (
  //   fetchCounter == (rideDetails.playlist as { songs: object[] }).songs.length
  // ) {
  //   rideDetails.platlistFetchState = PelotonPlaylistFetchState.FETCHED;
  // } else {
  //   rideDetails.platlistFetchState = PelotonPlaylistFetchState.ERRORFETCHING;
  // }
  await rideDetails.save();
  console.log("ride details updated");
}

async function _saveTrackFromPeloton(track: object) {
  const result = await Track.create({
    name: (track as { name: string }).name,
    thirdPartyId: (track as { id: string }).id,
    artist: (track as { artists: { name: string }[] }).artists[0].name,
    trackDurationMS: (track as { duration_ms: string }).duration_ms,
    albumArtUrl: (track as { album: { images: { url: string }[] } }).album
      .images[0].url,
    fullApiResponse: { track: track },
    provider: "spotify",
  });

  return result;
}

async function fetchPlaylistTracks() {
  while (true) {
    await pullPlaylistFromSpotifyForOneRideDetails();
    await delay(20000); // Wait for 20 seconds
  }
}

console.log(fetchPlaylistTracks);
