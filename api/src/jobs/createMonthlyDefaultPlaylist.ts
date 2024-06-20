import { archivePreviousAndCreateNewDefaultPlaylist } from "../services/userPlaylistService";
import { fetchUserSpotifyAuth } from "../services/spotifyAuthService";
import { UserWorkout } from "../models/UserWorkout";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export async function createMonthlyDefaultPlaylist() {
  const userIds = await UserWorkout.findUniqueUsersWithWorkouts();
  for (const userId of userIds) {
    const { accessToken } = await fetchUserSpotifyAuth(userId);
    await archivePreviousAndCreateNewDefaultPlaylist(accessToken, userId);
  }
}
