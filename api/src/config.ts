import dotenv from "dotenv";

// Initialize dotenv
dotenv.config({ path: "functions/.env" });
let _ensureInitialConfig = false;
export const config = {
  spotifyClientId: process.env.SPOTIFY_CLIENT_ID || "",
  spotifyClientSecret: process.env.SPOTIFY_CLIENT_SECRET || "",
  spotifyClientCallbackUrl: process.env.SPOTIFY_CLIENT_CALLBACK_URL || "",
  ensureInitialConfig: () => {
    if (!_ensureInitialConfig) {
      console.log("initial config setup");
      _ensureInitialConfig = true;
    }
  },
};
