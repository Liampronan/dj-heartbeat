import { fetchUserSpotifyAuth } from "./spotifyAuthService";
import { pullDefaultPlaylistFromSpotify } from "./userPlaylistService";

export async function handleAppOpened(uid: string) {
  if (!uid) {
    return;
  }

  const auth = await fetchUserSpotifyAuth(uid);
  await pullDefaultPlaylistFromSpotify(auth.accessToken, uid);
}
