import { config } from "../config";
import { db } from "../firebaseConfig";
import { storeAuth } from "./firebaseAuthService";

const spotifyClientId = config.spotifyClientId;
const spotifyClientSecret = config.spotifyClientSecret;
const clientCallbackUri = config.spotifyClientCallbackUrl;

export async function fetchUserSpotifyAuth(uid: string) {
  const authDocRef = db.collection("spotifyAuth").doc(uid);
  const info = await authDocRef.get();
  const authData = {
    id: "",
    accessToken: "",
    refreshToken: "",
    expiresAt: new Date(),
  };

  const docData = info.data();

  if (!docData) throw new Error("missing docData");
  authData.id = info.id;
  authData.accessToken = docData.accessToken;
  authData.refreshToken = docData.refreshToken;
  authData.expiresAt = docData.expiresAt.toDate();
  await refreshSpotifyAccessTokenIfNeeded(authData);
  return authData;
}

// we pass this object back to Spotify iOS client, which expects this snake casing
interface SpotifyAPITokenResponse {
  access_token: string;
  expires_in: number;
  refresh_token: string;
  scope: string;
  token_type: string;
}

export async function handlePostAPIToken(code: string) {
  const params = new URLSearchParams();
  params.append("client_id", spotifyClientId);
  params.append("code", code);
  params.append("grant_type", "authorization_code");
  params.append("redirect_uri", clientCallbackUri);

  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    body: params,
    headers: {
      "content-type": "application/x-www-form-urlencoded",
      Authorization:
        "Basic " +
        Buffer.from(`${spotifyClientId}:${spotifyClientSecret}`).toString(
          "base64"
        ),
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching tokens: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  return (await response.json()) as SpotifyAPITokenResponse;
}

export async function refreshApiToken(existingRefreshToken: string) {
  // TODO: encrypt/decrpyt token. see: https://github.com/rorygilchrist/node-spotify-token-swap/blob/master/app.js
  const params = new URLSearchParams();
  params.append("refresh_token", existingRefreshToken);
  params.append("grant_type", "refresh_token");

  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    body: params,
    headers: {
      "content-type": "application/x-www-form-urlencoded",
      Authorization:
        "Basic " +
        Buffer.from(`${spotifyClientId}:${spotifyClientSecret}`).toString(
          "base64"
        ),
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching tokens: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  return {
    status: response.status,
  };
}

async function refreshSpotifyAccessTokenIfNeeded(authData) {
  const currentTime = Date.now();
  const timeIn20Seconds = currentTime + 20 * 1000;

  // Check if the Firebase timestamp is before 20 seconds in the future
  if (authData.expiresAt.getTime() < timeIn20Seconds) {
    authData.accessToken = await fetchRefreshAndUpdateToken(
      authData.refreshToken,
      authData.id
    );
  } else {
    console.log(
      "The Firebase timestamp is not before 20 seconds in the future."
    );
  }
}

async function fetchRefreshAndUpdateToken(
  existingRefreshToken,
  spotifyAuthFirestoreId
) {
  const params = new URLSearchParams();
  params.append("refresh_token", existingRefreshToken);
  params.append("grant_type", "refresh_token");

  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    body: params,
    headers: {
      "content-type": "application/x-www-form-urlencoded",
      Authorization:
        "Basic " +
        Buffer.from(`${spotifyClientId}:${spotifyClientSecret}`).toString(
          "base64"
        ),
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching tokens: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  const responseJSON = await response.json();
  const accessToken = responseJSON.access_token;
  const refreshToken = responseJSON.refresh_token;
  const expiresIn = responseJSON.expires_in;
  await storeAuth(accessToken, refreshToken, expiresIn, spotifyAuthFirestoreId);
  return accessToken;
}
