import { RelatedTrack } from "../models/RelatedTrack";
import { Track } from "../models/Track";
import { UserListen } from "../models/UserListen";

export const suggestTracksForUser = async (userId: string) => {
  const limit = 30;
  const trackIdsThatAreValid =
    await UserListen.findTrackIdsThatHaveMatchingRelatedTracks(userId);

  // consider: ensure only get one related track per seed (example: we don't want a lot of related tracks just for a single song.
  // bc spotify radio for song already does that)
  const relatedTrackIds = (
    await RelatedTrack.find({
      originalTrack: { $in: trackIdsThatAreValid },
    })
      .limit(limit)
      .select("relatedTrack")
  ).map((recentListen) => recentListen.relatedTrack);

  const tracks = await Track.find({ _id: { $in: relatedTrackIds } }).select(
    "-fullApiResponse"
  );
  return tracks;
};

// TODO: implement
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const unheardOfTracksForUser = async (uid: string) => {
  // 1. find random, recent userListens (fall tracks ... which we'll hit now bc i have listened to all tracks). not by this user/uid. sort by listenedAt
  // 2. return tracks
  // NOTE:
  return Promise.resolve([]);
};
