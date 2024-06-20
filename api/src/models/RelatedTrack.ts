import { Schema, model, Document, Model } from "mongoose";

interface IRelatedTrack {
  originalTrack: Schema.Types.ObjectId;
  relatedTrack: Schema.Types.ObjectId;
}
// for now, a RelatedTrack is independent of a user. we may reconsider that -- i think spotify api takes user into consideration.
const relatedTrackSchema = new Schema<IRelatedTrack>(
  {
    originalTrack: {
      type: Schema.Types.ObjectId,
      ref: "Track",
      required: true,
      index: true,
    },
    relatedTrack: {
      type: Schema.Types.ObjectId,
      ref: "Track",
      required: true,
      index: true,
    },
  },
  { timestamps: true }
);

relatedTrackSchema.index(
  { originalTrack: 1, relatedTrack: 1 },
  { unique: true }
);

export interface IRelatedTrackDocument extends Document, IRelatedTrack {}

interface IInsertRelatedTracksResult {
  success: boolean;
  error?: string;
  track?: IRelatedTrack | null;
}
relatedTrackSchema.statics.insertRelatedTracks = async function (
  tracks: IRelatedTrack[]
) {
  const insertPromises = tracks.map(async (track) => {
    try {
      const newRelation = new this(track);
      await newRelation.save();
      return { success: true, track: newRelation };
    } catch (error) {
      if (error.code === 11000) {
        return { success: false, error: "Duplicate entry", track: null };
      } else {
        return { success: false, error: error.message, track: null };
      }
    }
  });

  // Wait for all insert operations to complete
  const results = await Promise.all(insertPromises);
  return results;
};

// Extend the Model interface with the static method
interface IRelatedTrackModel extends Model<IRelatedTrack> {
  insertRelatedTracks(
    tracks: IRelatedTrack[]
  ): Promise<IInsertRelatedTracksResult[]>;
}

export const RelatedTrack = model<IRelatedTrackDocument, IRelatedTrackModel>(
  "RelatedTrack",
  relatedTrackSchema
);
