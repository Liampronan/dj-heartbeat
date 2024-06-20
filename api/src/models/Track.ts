import { Schema, model, HydratedDocument, Document, Model } from "mongoose";

export interface ITrack {
  thirdPartyId: string;
  provider: string;
  name: string;
  artist: string;
  trackDurationMS: number;
  albumArtUrl: string;
  fullApiResponse: { track: { uri: string } };
  audioFeatures?: { tempo: number };
  audioFeaturesFetched?: boolean;
  lastFetchedRelatedTracksAt?: Date;
  lastUserListenedAt?: Date;
}

const trackSchema = new Schema<ITrack>(
  {
    thirdPartyId: { type: String, required: true, unique: true },
    provider: { type: String, default: "spotify" },
    name: { type: String, required: true },
    artist: { type: String, required: true },
    trackDurationMS: { type: Number, required: true },
    albumArtUrl: { type: String, required: true },
    fullApiResponse: { type: Schema.Types.Mixed, required: true },
    audioFeaturesFetched: {
      type: Boolean,
      required: true,
      default: false,
      index: true,
    },
    audioFeatures: { type: Schema.Types.Mixed },
    lastFetchedRelatedTracksAt: { type: Date, sparse: true },
    lastUserListenedAt: { type: Date, sparse: true },
  },
  { timestamps: true }
);

trackSchema.index({ audioFeaturesFetched: 1, lastUserListenedAt: 1 });
trackSchema.index({ lastFetchedRelatedTracksAt: 1, lastUserListenedAt: 1 });

trackSchema.static(
  "saveMany",
  async function saveMany(tracks: Exclude<ITrack, "_id">[]) {
    const mongoDBWriteObjs: Promise<ITrackDocument>[] = [];
    for (const track of tracks) {
      const findOrCreatePromise = Track.findOneAndUpdate(
        { thirdPartyId: track.thirdPartyId },
        {
          $setOnInsert: track,
        },
        { upsert: true, new: true, runValidators: true }
      );
      mongoDBWriteObjs.push(findOrCreatePromise);
    }

    return await Promise.all(mongoDBWriteObjs);
  }
);

trackSchema.static(
  "doesTrackHaveAudioFeatures",
  async function doesTrackHaveAudioFeatures(
    trackId: string
  ): Promise<{ track: ITrack; hasAudioFeatures: boolean }> {
    const track = await this.findById(trackId);

    if (!track) throw new Error(`missing track with trackId ${trackId}`);

    return { track: track, hasAudioFeatures: !!track.features };
  }
);

trackSchema.static(
  "findTracksIdsWithoutRelatedTracks",
  async function findTracksIdsWithoutRelatedTracks(limit = 15) {
    const tracks = await Track.aggregate([
      {
        $lookup: {
          from: "relatedtracks",
          localField: "_id",
          foreignField: "originalTrack",
          as: "related",
        },
      },
      {
        $match: {
          related: { $size: 0 },
        },
      },
      { $limit: limit },
    ]);

    return tracks.map((t) => t._id as string);
  }
);

trackSchema.virtual("spotifyUri").get(function () {
  return this.fullApiResponse.track.uri;
});

trackSchema.pre("save", function () {
  if (this.audioFeatures && !this.audioFeaturesFetched) {
    this.audioFeaturesFetched = true;
  }
});

export interface ITrackDocument extends Document, ITrack {
  spotifyUri: string;
}

interface ITrackModel extends Model<ITrackDocument> {
  saveMany(tracks: ITrack[]): Promise<HydratedDocument<ITrackDocument>[]>;
  doesTrackHaveAudioFeatures(
    trackId: string
  ): Promise<{ track: ITrackDocument; hasAudioFeatures: boolean }>;
  findTracksIdsWithoutRelatedTracks(limit?: number): Promise<string[]>;
}

export const Track = model<ITrackDocument, ITrackModel>("Track", trackSchema);
