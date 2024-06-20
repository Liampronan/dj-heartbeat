import { Schema, model, Model, HydratedDocument, ObjectId } from "mongoose";
import { getLastSunday, getTwoSundaysAgo } from "../time";

interface IWeeklyTrackHeartbeatCounter {
  weekStartAt: Date;
  track: ObjectId;
  totalHeartbeats: number;
}
// statics
interface IWeeklyTrackHeartbeatCounterModel
  extends Model<IWeeklyTrackHeartbeatCounter> {
  findThisWeeksTopTracks(): Promise<
    HydratedDocument<IWeeklyTrackHeartbeatCounter>[]
  >;
  findLastWeeksTopTracks(): Promise<
    HydratedDocument<IWeeklyTrackHeartbeatCounter>[]
  >;
}

const weeklyTrackHeartbeatCounterSchema = new Schema<
  IWeeklyTrackHeartbeatCounter,
  IWeeklyTrackHeartbeatCounterModel
>(
  {
    weekStartAt: { type: Date, required: true },
    track: { type: Schema.Types.ObjectId, ref: "Track", required: true },
    totalHeartbeats: { type: Number, default: 0 },
  },
  { timestamps: true }
);

weeklyTrackHeartbeatCounterSchema.static(
  "findThisWeeksTopTracks",
  function findThisWeeksTopTracks() {
    return this.find({
      weekStartAt: getLastSunday(),
    })
      .populate({ path: "track", select: "-fullApiResponse" })
      .sort({ totalHeartbeats: "desc" })
      .limit(20);
  }
);

weeklyTrackHeartbeatCounterSchema.static(
  "findLastWeeksTopTracks",
  function findLastWeeksTopTracks() {
    return this.find({
      weekStartAt: getTwoSundaysAgo(),
    })
      .populate({ path: "track", select: "-fullApiResponse" })
      .sort({ totalHeartbeats: "desc" })
      .limit(20);
  }
);

export const WeeklyTrackHeartbeatCounter = model<
  IWeeklyTrackHeartbeatCounter,
  IWeeklyTrackHeartbeatCounterModel
>("WeeklyTrackHeartbeatCounter", weeklyTrackHeartbeatCounterSchema);
