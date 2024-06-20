import { config } from "../config";
config.ensureInitialConfig();

import { connectToDB, disconnectFromDB } from "../mongo";
import { IUserListen, UserListen } from "../models/UserListen";
import { Track } from "../models/Track";

async function run() {
  await connectToDB();
  const userListens = await UserListen.find().populate({
    path: "track",
    select: "-fullApiResponse",
  });
  if (!userListens) throw new Error("no userlisten found");

  console.log("updating for numUserListens: ", userListens.length);
  let updateCount = 0;
  for (const userListen of userListens) {
    await updateTrack(userListen);
    console.log(
      `updated ${++updateCount} of ${userListens.length} userListens`
    );
  }

  await disconnectFromDB();
}

async function updateTrack(userListen: IUserListen) {
  console.log(run); // just including this to quickfix ts build error for unused var. inline comment disable doesn't seem to work.
  if ((userListen.track as any).lastUserListenedAt >= userListen.listenedAt) {
    console.log(
      "track.lastUserListenedAt is after or equal to userListen ... skipping "
    );
    return;
  }
  await Track.findOneAndUpdate(
    { _id: (userListen.track as any)._id },
    { $set: { lastUserListenedAt: userListen.listenedAt } }
  );
}
