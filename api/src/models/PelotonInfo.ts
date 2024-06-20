import { Model, Schema, model } from "mongoose";
import { ClassCategory } from "peloton-client-node/dist/interfaces/options";

export interface IPelotonInfo {
  rideDetailsApiResponse: {
    ride: {
      id: string;
      description: string;
      title: string;
      fitness_discipline: string;
      original_air_time: number;
    };
    playlist: object;
    segments: object[];
  };

  classDetailsApiResponse: {
    title: string;
    fitness_discipline: string;
    ride_type_id: string;
    hasFetchedDetails: boolean;
  };

  type: "rideDetails" | "classDetails";
}

const pelotonInfoSchema = new Schema<IPelotonInfo>(
  {
    rideDetailsApiResponse: {
      type: Schema.Types.Mixed,
    },
    classDetailsApiResponse: {
      type: Schema.Types.Mixed,
    },
    type: {
      type: String,
      required: true,
      enum: ["rideDetails", "classDetails"],
    },
  },
  { timestamps: true }
);

// Custom validation for conditional requirements
pelotonInfoSchema.pre("validate", function (next) {
  if (this.type === "rideDetails") {
    if (
      !this.rideDetailsApiResponse ||
      !this.rideDetailsApiResponse.ride ||
      !this.rideDetailsApiResponse.ride.id
    ) {
      this.invalidate(
        "rideDetailsApiResponse.ride.id",
        "Required for rideDetails type"
      );
    }
    // Add more fields as necessary
  } else if (this.type === "classDetails") {
    if (
      !this.classDetailsApiResponse ||
      !this.classDetailsApiResponse.ride_type_id
    ) {
      this.invalidate(
        "classDetailsApiResponse.ride_type_id",
        "Required for classDetails type"
      );
    }
    // Validate other necessary fields for classDetails
  }
  next();
});

// statics
interface PelotonInfoModel extends Model<IPelotonInfo> {
  findOneUnfetchedRideId(category: ClassCategory): Promise<string>;
  markRideClassDetailsAsFetched(rideId: string);
  countFindFetchedClasses(): Promise<number>;
  countFetchedRideDetails(): Promise<number>;
  deleteAllClassDetails();
  deleteFetchedClassDetails();
}

pelotonInfoSchema.static(
  "findOneUnfetchedRideId",
  async function (category: ClassCategory) {
    const result = await this.findOne({
      type: "classDetails",
      "classDetailsApiResponse.fitness_discipline": category,
      "classDetailsApiResponse.hasFetchedDetails": { $ne: true },
    });
    return result.classDetailsApiResponse.id;
  }
);

pelotonInfoSchema.static("countFindFetchedClasses", async function () {
  const result = await this.countDocuments({
    type: "classDetails",
    "classDetailsApiResponse.hasFetchedDetails": true,
  });
  return result;
});

pelotonInfoSchema.static("deleteFetchedClassDetails", async function () {
  const result = await this.deleteMany({
    type: "classDetails",
    "classDetailsApiResponse.hasFetchedDetails": true,
  });
  return result;
});

pelotonInfoSchema.static("deleteAllClassDetails", async function () {
  const result = await this.deleteMany({
    type: "classDetails",
  });
  return result;
});

pelotonInfoSchema.static("countFetchedRideDetails", async function () {
  const result = await this.countDocuments({
    type: "rideDetails",
  });
  return result;
});

pelotonInfoSchema.static(
  "markRideClassDetailsAsFetched",
  async function (rideId: string) {
    const result = await this.findOne({
      type: "classDetails",
      "classDetailsApiResponse.id": rideId,
      "classDetailsApiResponse.hasFetchedDetails": { $ne: true },
    });
    result.classDetailsApiResponse.hasFetchedDetails = true;
    result.markModified("classDetailsApiResponse");
    await result.save();
  }
);

export const PelotonInfo = model<IPelotonInfo, PelotonInfoModel>(
  "PelotonInfo",
  pelotonInfoSchema
);
