import { Model, Schema, model } from "mongoose";
import { IPelotonInfo } from "./PelotonInfo";

export interface IPelotonRideDetails {
  pelotonId: string;
  title: string;
  description: string;
  category: string;
  orginalAirTime: Date;
  playlist: object;
  segments: object;
  playlistFetchedTrackCount: number;
}

const pelotonRideDetailsSchema = new Schema<IPelotonRideDetails>(
  {
    pelotonId: { type: String, required: true, unique: true },
    title: { type: String, required: true },
    description: { type: String, required: true },
    category: { type: String, required: true },
    orginalAirTime: { type: Date, required: true },
    playlist: { type: Schema.Types.Mixed, required: true },
    segments: { type: Schema.Types.Mixed },
    playlistFetchedTrackCount: {
      type: Number,
      index: true,
    },
  },
  { timestamps: true }
);

pelotonRideDetailsSchema.static(
  "createFromPelotonInfo",
  async function (pelotonInfo: IPelotonInfo) {
    if (!pelotonInfo.rideDetailsApiResponse)
      throw new Error("No rideDetailsApiResponse found ");
    const rideDetails = pelotonInfo.rideDetailsApiResponse;
    return this.create({
      pelotonId: rideDetails.ride.id,
      description: rideDetails.ride.description,
      title: rideDetails.ride.title,
      category: rideDetails.ride.fitness_discipline,
      playlist: rideDetails.playlist,
      segments: rideDetails.segments,
      orginalAirTime: new Date(rideDetails.ride.original_air_time * 1000),
    });
  }
);

pelotonRideDetailsSchema.virtual("playlistTracksWithArtists").get(function () {
  return (
    this.playlist as {
      songs: { artists: { artist_name: string }[]; title: string }[];
    }
  ).songs;
});

export interface IPelotonRideDetailsDocument
  extends Document,
    IPelotonRideDetails {
  playlistTracksWithArtists: {
    artists: { artist_name: string }[];
    title: string;
  }[];
}

interface PelotonRideDetailsModel extends Model<IPelotonRideDetailsDocument> {
  createFromPelotonInfo(pelotonInfo: IPelotonInfo): Promise<string>;
}

export const PelotonRideDetails = model<
  IPelotonRideDetailsDocument,
  PelotonRideDetailsModel
>("PelotonRideDetails", pelotonRideDetailsSchema);
