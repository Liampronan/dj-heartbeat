import { config } from "./config";
config.ensureInitialConfig();

import { onRequest } from "firebase-functions/v2/https";
import express, { Request, Response } from "express";
import {
  fetchUserSpotifyAuth,
  handlePostAPIToken,
  refreshApiToken,
} from "./services/spotifyAuthService";
import {
  findOrCreateCustomClientToken,
  verifyTokenAndGetUid,
} from "./services/firebaseAuthService";
import { handleWorkout } from "./services/handleWorkoutService";
import { UserListen } from "./models/UserListen";
import { connectToDB } from "./mongo";
import {
  addTrackToDefaultPlaylist,
  clearDefaultPlaylist,
  findAllPlaylistsForUser,
  getDefaultPlaylistAndDuration,
} from "./services/userPlaylistService";
import { enrichTrackAudioFeatureSpotify } from "./jobs/enrichTrackAudioFeatures";
import { addRelatedTracksSpotify } from "./jobs/addRelatedTracks";
import {
  suggestTracksForUser,
  unheardOfTracksForUser,
} from "./services/suggestedTrackService";
import { createCloudJob } from "./lib/queue";
import { getTopTracks } from "./services/topTracksService";
import { updateSpotifyDJHeartbeatPlaylist } from "./jobs/updateSpotifyDJHeartbeatPlaylist";
import { DebugLog } from "./models/DebugLog";
import { fetchTodayYesterdaySocialFeed } from "./services/socialFeedService";
import {
  enqueueTracksToEnrich,
  enqueueTracksForFindingRelatedTracks,
} from "./jobs/queuerForTrackJobs";
import {
  createDailyScheduledJob,
  createHourlyScheduledJob,
} from "./lib/scheduler";
import { addToWaitlist } from "./services/waitlistService";
import { fetchRecentWorkouts } from "./services/recentWorkoutsService";
import { handleUserFeedback } from "./services/userFeedbackService";
import { validateSignupCode } from "./services/signupCodeService";
import {
  createOneVirtualWorkout,
  enqueueDailyVirtualWorkoutsCreation,
} from "./jobs/queuerForVirtualWorkouts";
import { createMonthlyDefaultPlaylist } from "./jobs/createMonthlyDefaultPlaylist";
import { handleAppOpened } from "./services/appOpenedService";

const app = express();

app.use(async (req, res, next) => {
  try {
    await connectToDB();
    next();
  } catch (error) {
    res.status(500).send("Database connection error.");
  }
});

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "https://heycommit.com"); // for commit waitlist. can remove once we move that to own project
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );
  next();
});

app.post("/generateClientToken", async (req, res) => {
  const { spotifyAccessToken, spotifyRefreshToken, expiresAt } = req.body;
  if (!spotifyAccessToken || !spotifyRefreshToken || !expiresAt) {
    throw new Error("Error: missing client token params in req.body");
  }

  try {
    const customToken = await findOrCreateCustomClientToken(
      spotifyAccessToken,
      spotifyRefreshToken,
      expiresAt
    );
    res.send({ customToken });
  } catch (error) {
    console.log("Error creating custom token:", error);
    res.status(400);
  }
});

app.get("/", (req: Request, res: Response) => {
  res.send(`hellooo world`);
});

app.post("/apiToken", async (req, res) => {
  console.log("incoming apiToken ~~~");
  const code = req.body.code || null;
  const authData = await handlePostAPIToken(code);
  res.set("Content-Type", "text/json").status(200).send(authData);
});

app.get("/tracks/discover", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);

  const [
    recentlyPlayed,
    leastRecentlyPlayed,
    suggestedForYou,
    random,
    unheardOf,
  ] = await Promise.all([
    UserListen.findRecentlyPlayed(uid),
    UserListen.findLeastRecentlyPlayed(uid),
    suggestTracksForUser(uid),
    UserListen.findRandomWorkoutTracks(),
    unheardOfTracksForUser(uid),
  ]);

  return res.send({
    recentlyPlayed: {
      tracks: recentlyPlayed.map((userListen) => userListen.track),
      titleText: "Just Played",
      descriptionText:
        "The tracks you've listened to while working out recently.",
    },
    leastRecentlyPlayed: {
      tracks: leastRecentlyPlayed.map((userListen) => userListen.track),
      titleText: "Play me maybe",
      descriptionText:
        "The tracks you have listened to in the past... but not recently.",
    },
    suggestedForYou: {
      tracks: suggestedForYou,
      titleText: "Suggested for you",
      descriptionText: "Some recs based on some workout tracks you like.",
    },
    random: {
      tracks: random,
      titleText: "Random",
      descriptionText: "Tracks that others have worked out to.",
    },
    unheardOf: {
      tracks: unheardOf,
      titleText: "Unheard of",
      descriptionText: "Workout hits that you haven't listened to",
    },
  });
});

// todo: chnage name after march 29 release ... just so we don't have v2 extraneous endpoints. drop v2 and delete the current "/tracks/discover" logic.
app.get("/tracks/discover-v2", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);

  const [
    recentlyPlayed,
    leastRecentlyPlayed,
    suggestedForYou,
    random,
    unheardOf,
  ] = await Promise.all([
    UserListen.findRecentlyPlayed(uid),
    UserListen.findLeastRecentlyPlayed(uid),
    suggestTracksForUser(uid),
    UserListen.findRandomWorkoutTracks(),
    unheardOfTracksForUser(uid),
  ]);

  return res.send({
    recentlyPlayed: {
      tracks: recentlyPlayed.map((userListen) => userListen.track),
      titleText: "Just Played",
      descriptionText:
        "The tracks you've listened to while working out recently.",
    },
    leastRecentlyPlayed: {
      tracks: leastRecentlyPlayed.map((userListen) => userListen.track),
      titleText: "Play me maybe",
      descriptionText:
        "The tracks you have listened to in the past... but not recently.",
    },
    suggestedForYou: {
      tracks: suggestedForYou,
      titleText: "Suggested for you",
      descriptionText: "Some recs based on some workout tracks you like.",
    },
    random: {
      tracks: random,
      titleText: "Random",
      descriptionText: "Tracks that others have worked out to.",
    },
    unheardOf: {
      tracks: unheardOf,
      titleText: "Unheard of",
      descriptionText: "Workout hits that you haven't listened to",
    },
  });
});

app.post("/refreshApiToken", async (req, res) => {
  console.log("incoming refreshApiToken ~~~");

  if (!req.body.refresh_token) {
    res.status(400).json({ error: "Refresh token is missing from body" });
    return;
  }
  const existingRefreshToken = req.body.refresh_token;
  const { status } = await refreshApiToken(existingRefreshToken);

  res.status(status);
  res.send(res.json()); // ? maybe this should be response.json but atm not changing bc focused on decomp refactor
});

app.post("/debugWorkoutSamples", async (req, res) => {
  if (!req.body.samples) {
    res.status(400).json({ error: "Refresh token is missing from body" });
    return;
  }

  const debugLog = new DebugLog({
    type: "workoutsample",
    data: req.body.samples,
  });
  await debugLog.save();

  res.status(200).send({});
});

async function fetchUserFromReq(req: Request): Promise<{ uid: string }> {
  const authHeaderVal = req.get("authorization");
  if (!authHeaderVal) {
    throw new Error("missing authorization header");
  }
  const tokenId = authHeaderVal.split("Bearer ")[1];
  const uid = await verifyTokenAndGetUid(tokenId);
  return { uid };
}

app.get("/workouts", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);
  const result = await fetchRecentWorkouts(uid);

  res.json({ workouts: result });
});

app.post("/waitlist", async (req, res) => {
  console.log("Hellooo");
  const email = req.body.email || null;

  if (!email) {
    throw new Error(`Error while signing up for waitlist`);
  }

  await addToWaitlist(email);

  res.set("Content-Type", "text/json").status(200).send({});
});

app.get("/social-feed", async (req, res) => {
  console.log("Hellooo");
  const response = await fetchTodayYesterdaySocialFeed();

  res.send(response);
});

app.post("/handleWorkout", async function (req, res) {
  const { heartRateInfo, workoutType } = req.body;

  if (!heartRateInfo) {
    throw new Error("Error with request: no heart rate info in body");
  }
  const { uid } = await fetchUserFromReq(req);
  const userListens = await handleWorkout(uid, heartRateInfo, workoutType);

  res.send({ userListens });
});

app.get("/top-tracks", async (req, res) => {
  const topTracks = await getTopTracks();

  res.send(topTracks);
});

app.get("/default-playlist", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);
  const { accessToken } = await fetchUserSpotifyAuth(uid);

  const playlistAndDuration = await getDefaultPlaylistAndDuration(
    accessToken,
    uid
  );
  res.send({ playlist: playlistAndDuration });
});

app.get("/playlists", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);

  const playlistsInfo = await findAllPlaylistsForUser(uid);

  res.send(playlistsInfo);
});

app.post("/default-playlist", async (req, res) => {
  const trackId = req.body.trackId;
  if (!trackId) {
    res.status(400);
    return;
  }
  const { uid } = await fetchUserFromReq(req);
  const { accessToken } = await fetchUserSpotifyAuth(uid);
  const playlist = await addTrackToDefaultPlaylist(accessToken, uid, trackId);
  res.send({ playlist });
});

app.delete("/default-playlist", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);
  const { accessToken } = await fetchUserSpotifyAuth(uid);

  const playlist = await clearDefaultPlaylist(accessToken, uid);
  res.send({ playlist });
});

app.post("/feedback", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);

  const feedback = req.body.feedback;
  const contact = req.body.contact || "";
  if (!feedback) {
    res.status(400);
    return;
  }
  await handleUserFeedback(feedback, uid, contact);
  res.send({});
});

app.post("/app-opened", async (req, res) => {
  const { uid } = await fetchUserFromReq(req);
  await handleAppOpened(uid);

  res.send({});
});

app.post("/signup-code", async (req, res) => {
  const signupCode = req.body.signupCode;

  if (!signupCode) {
    res.send({ isCodeValid: false });
    return;
  }

  const isCodeValid = await validateSignupCode(signupCode);

  res.send({ isCodeValid });
});

export default app;

// adding these exports registers them with firebase for deployment / hosting.
exports.widgets = onRequest(app);
exports.enrichTrackAudioFeatureSpotify = createCloudJob(
  enrichTrackAudioFeatureSpotify
);
exports.addRelatedTracksSpotify = createCloudJob(addRelatedTracksSpotify);
exports.updateSpotifyDJHeartbeatPlaylist = createCloudJob(
  updateSpotifyDJHeartbeatPlaylist
);
exports.createOneVirtualWorkout = createCloudJob(createOneVirtualWorkout);

// register scheduled jobs
exports.enqueueTracksToEnrich = createHourlyScheduledJob(enqueueTracksToEnrich);
exports.enqueueTracksForFindingRelatedTracks = createHourlyScheduledJob(
  enqueueTracksForFindingRelatedTracks
);
exports.enqueueDailyVirtualWorkoutsCreation = createDailyScheduledJob(
  enqueueDailyVirtualWorkoutsCreation
);
exports.createMonthlyDefaultPlaylist = createDailyScheduledJob(
  createMonthlyDefaultPlaylist
);
