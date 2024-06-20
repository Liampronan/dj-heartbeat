import dotenv from "dotenv";

// Initialize dotenv
dotenv.config();
export const config = {
  spotifyClientId: process.env.SPOTIFY_CLIENT_ID || "",
  spotifyClientSecret: process.env.SPOTIFY_CLIENT_SECRET || "",
  spotifyClientCallbackUrl: process.env.SPOTIFY_CLIENT_CALLBACK_URL || "",
  mongoDBConnectionUri: process.env.MONGO_DB_CXN_URI || "",
};
