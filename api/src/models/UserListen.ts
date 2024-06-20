import { Schema, model, Model, HydratedDocument } from "mongoose";
import { IUserWorkout } from "./UserWorkout";
import { Track } from "./Track";

export enum ListenType {
  WORKOUT = "workout",
  UNKNOWN = "unknown",
}

export interface IUserListen {
  id: Schema.Types.ObjectId;
  track: Schema.Types.ObjectId;
  listenedAt: Date;
  userId: string;
  listenType: ListenType;
  totalHeartbeats: number;
}

// statics
interface UserListenModel extends Model<IUserListen> {
  findRecentlyPlayed(userId: string): Promise<HydratedDocument<IUserListen>[]>;
  findLeastRecentlyPlayed(
    userId: string
  ): Promise<HydratedDocument<IUserListen>[]>;
  findTracksForUserWorkout(
    workout: IUserWorkout
  ): Promise<HydratedDocument<IUserListen[]>>;
  findUnprocessedTracksForUserWorkout(
    workout: IUserWorkout
  ): Promise<HydratedDocument<IUserListen[]>>;

  findRandomWorkoutTracks(): Promise<HydratedDocument<IUserListen[]>>;
  findUserIdForMostRecentListen(trackId: string): Promise<string | undefined>;
  findTrackIdsThatHaveMatchingRelatedTracks(
    userId: string,
    limit?: number
  ): Promise<string[]>;
}

const userListenSchema = new Schema<IUserListen, UserListenModel>(
  {
    track: {
      type: Schema.Types.ObjectId,
      ref: "Track",
      required: true,
      index: true,
    },
    listenedAt: { type: Date, required: true, index: true },
    userId: { type: String, required: true, index: true },
    listenType: {
      type: String,
      required: true,
      enum: Object.values(ListenType),
      index: true,
    },
    totalHeartbeats: { type: Number },
  },
  { timestamps: true }
);

userListenSchema.index({ userId: 1, listenedAt: 1 }, { unique: true });
userListenSchema.index({ track: 1, listenedAt: 1 }, { unique: true });
userListenSchema.index({
  userId: 1,
  listenedAt: 1,
  listenType: 1,
  totalHeartbeats: 1,
});

userListenSchema.static(
  "findRecentlyPlayed",
  function findRecentlyPlayed(userId: string) {
    return this.find({
      userId: userId,
      listenType: ListenType.WORKOUT,
      totalHeartbeats: { $exists: true },
    })

      .populate({ path: "track", select: "-fullApiResponse" })
      .sort({ listenedAt: "descending" })
      .limit(20);
  }
);

userListenSchema.static(
  "findLeastRecentlyPlayed",
  function findLeastRecentlyPlayed(userId: string) {
    return this.find({
      userId: userId,
      listenType: ListenType.WORKOUT,
      totalHeartbeats: { $exists: true },
    })
      .populate({ path: "track", select: "-fullApiResponse" })
      .sort({ listenedAt: "ascending" })
      .limit(20);
  }
);

userListenSchema.static(
  "findTracksForUserWorkout",
  function findTracksForUserWorkout(userWorkout: IUserWorkout) {
    return this.find({
      userId: userWorkout.userId,
      listenType: ListenType.WORKOUT,
      listenedAt: { $gte: userWorkout.startDate, $lte: userWorkout.endDate },
    })
      .populate({ path: "track", select: "-fullApiResponse" })
      .sort({ listenedAt: "ascending" });
  }
);

userListenSchema.static(
  "findUnprocessedTracksForUserWorkout",
  function findUnprocessedTracksForUserWorkout(userWorkout: IUserWorkout) {
    return this.find({
      userId: userWorkout.userId,
      listenedAt: { $gte: userWorkout.startDate, $lte: userWorkout.endDate },
    })
      .populate({ path: "track", select: "-fullApiResponse" })
      .sort({ listenedAt: "descending" });
  }
);

userListenSchema.static(
  "findRandomWorkoutTracks",
  async function findRandomWorkoutTracks() {
    const matchFilter = { listenType: ListenType.WORKOUT };
    const sampleParams = { size: 25 };
    const lookupParams = {
      from: "tracks",
      localField: "track",
      foreignField: "_id",
      as: "track",
    };
    const projectParmas = {
      "track.fullApiResponse": 0,
    };
    const unwindParams = {
      path: "$track",
      preserveNullAndEmptyArrays: true,
    };

    interface AggregatedTrackResult {
      _id: Schema.Types.ObjectId;
      track: {
        _id: Schema.Types.ObjectId;
        thirdPartyId: string;
      };
    }

    const results: AggregatedTrackResult[] = await this.aggregate([
      { $match: matchFilter },
      { $sample: sampleParams },
      { $lookup: lookupParams },
      { $unwind: unwindParams },
      { $project: projectParmas },
    ]);

    const uniqueTracks = Array.from(
      new Map(
        results.map((item) => [item.track._id.toString(), item.track])
      ).values()
    );

    return uniqueTracks.map((track) => new Track(track));
  }
);

userListenSchema.static(
  "findUserIdForMostRecentListen",
  async function findUserIdForMostRecentListen(
    trackId: string
  ): Promise<string | undefined> {
    const result = await this.findOne({
      track: trackId,
    }).sort({ listenedAt: "descending" });

    return result?.userId;
  }
);

userListenSchema.static(
  "findTrackIdsThatHaveMatchingRelatedTracks",
  async function findTrackIdsThatHaveMatchingRelatedTracks(
    userId: string,
    limit = 30
  ): Promise<string[]> {
    const largerSampleSize = 100;

    const userListens = await this.aggregate([
      {
        $match: {
          userId: userId,
        },
      },
      {
        $sample: { size: largerSampleSize },
      },
      {
        $lookup: {
          from: "relatedtracks",
          localField: "track",
          foreignField: "originalTrack",
          as: "related",
        },
      },
      {
        $match: {
          "related.0": { $exists: true },
        },
      },
      {
        $limit: limit,
      },
      {
        $project: { _id: 1, track: 1 },
      },
    ]);
    return userListens.map((track) => track.track);
  }
);

export const UserListen = model<IUserListen, UserListenModel>(
  "UserListen",
  userListenSchema
);
