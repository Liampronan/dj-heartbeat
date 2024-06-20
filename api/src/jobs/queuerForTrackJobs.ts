import { Track } from "../models/Track";
import { UserListen } from "../models/UserListen";
import { enqueueAddRelatedTracksSpotifyJob } from "./addRelatedTracks";
import { enqueueEnrichAudioFeaturesJobs } from "./enrichTrackAudioFeatures";

export async function enqueueTracksToEnrich() {
  const tracksToQueue = await Track.find({
    audioFeaturesFetched: false,
    lastUserListenAt: { $ne: undefined },
  })
    .sort({
      lastUserListenAt: 1,
    })
    .limit(25);

  if (tracksToQueue.length === 0) return;
  const trackIds = tracksToQueue.map((t) => t.id);
  await enqueueEnrichAudioFeaturesJobs(trackIds);
}

export async function enqueueTracksForFindingRelatedTracks() {
  const tracksToQueue = await UserListen.aggregate([
    {
      $lookup: {
        from: "tracks",
        localField: "track",
        foreignField: "_id",
        as: "trackDetails",
      },
    },
    {
      $unwind: "$trackDetails",
    },
    {
      $match: {
        "trackDetails.lastFetchedRelatedTracksAt": { $exists: false },
      },
    },
    {
      $sort: {
        "trackDetails.lastUserListenedAt": 1,
      },
    },
    {
      $limit: 10,
    },
    {
      $project: {
        _id: 0, // Exclude the _id field
        trackId: "$trackDetails._id", // Include only the track ID, aliased as trackId
      },
    },
  ]);
  const trackIds = tracksToQueue.map((t) => t.trackId);

  await enqueueAddRelatedTracksSpotifyJob(trackIds);
}
