import {
  Schema,
  model,
  Model,
  HydratedDocument,
  Document,
  Types,
  ObjectId,
} from "mongoose";
import { ITrack } from "./Track";

export enum PlaylistStatus {
  ACTIVE = "active",
  INACTIVE = "inactive",
}

export interface IUserPlaylist {
  name: string;
  status: PlaylistStatus;
  userId: string;
  tracks: ITrack[];
  thirdPartyInfo: {
    url: string;
    uri: string;
  };
  createdAt: Date;

  addTrack(trackId: Types.ObjectId): void;
  getThirdPartyId(): string;
  getTotalDurationMS(): number;
}

// statics
interface UserPlaylistModel extends Model<IUserPlaylist> {
  findDefaultPlaylist(userId: string): Promise<HydratedDocument<IUserPlaylist>>;
  findPlaylistById(
    id: Types.ObjectId
  ): Promise<HydratedDocument<IUserPlaylist>>;

  createDefaultPlaylist(
    name: string,
    userId: string,
    thirdPartyUrl: string,
    thirdPartyUri: string
  ): Promise<HydratedDocument<IUserPlaylist>>;
}

const userPlaylistSchema = new Schema<IUserPlaylist, UserPlaylistModel>(
  {
    name: { type: String, default: "default" },
    tracks: [
      {
        type: Schema.Types.ObjectId,
        ref: "Track",
        required: true,
      },
    ],
    userId: { type: String, required: true, index: true },
    status: {
      type: String,
      required: true,
      enum: Object.values(PlaylistStatus),
    },
    thirdPartyInfo: {
      url: { type: String, required: true },
      uri: { type: String, required: true },
    },
    // totalHeartbeats: { type: Number }, // TODO: maybe include this? would need to consider case where user plays tracks not in slaylist
  },
  { timestamps: true }
);

userPlaylistSchema.index({ userId: 1, status: 1 });

userPlaylistSchema.static(
  "findDefaultPlaylist",
  async function findDefaultPlaylist(userId: string) {
    return this.findOne({
      userId: userId,
      status: PlaylistStatus.ACTIVE,
    }).populate({ path: "tracks", select: "-fullApiResponse" });
  }
);

userPlaylistSchema.static(
  "findPlaylistById",
  async function findPlaylistById(id: Types.ObjectId) {
    return this.findOne({
      _id: id,
    }).populate({ path: "tracks", select: "-fullApiResponse" });
  }
);

userPlaylistSchema.static(
  "createDefaultPlaylist",
  async function createDefaultPlaylist(
    name: string,
    userId: string,
    thirdPartyUrl: string,
    thirdPartyUri: string
  ) {
    return this.create({
      name,
      userId,
      status: PlaylistStatus.ACTIVE,
      thirdPartyInfo: { uri: thirdPartyUri, url: thirdPartyUrl },
    });
  }
);

userPlaylistSchema.methods.addTrack = async function (trackId: ObjectId) {
  this.tracks.push(trackId);
  await this.save();
};

userPlaylistSchema.methods.getThirdPartyId = function () {
  return this.thirdPartyInfo.uri.replace("spotify:playlist:", "");
};

userPlaylistSchema.methods.getTotalDurationMS = function () {
  return this.tracks.reduce((acc, track) => acc + track.trackDurationMS, 0);
};

export interface IUserPlaylistModel extends Document, IUserPlaylist {}
export const UserPlaylist = model<IUserPlaylist, UserPlaylistModel>(
  "UserPlaylist",
  userPlaylistSchema
);
