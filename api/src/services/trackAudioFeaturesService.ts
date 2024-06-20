import { Track } from "../models/Track";
import { UserListen } from "../models/UserListen";
import { fetchAudioFeatures } from "./spotifyAPIService";
import { fetchUserSpotifyAuth } from "./spotifyAuthService";

const FALLBACK_USER_ID = "spotify:liampronan";

export async function updateTrackAudioFeatures(trackId: string) {
  const { track, hasAudioFeatures } = await Track.doesTrackHaveAudioFeatures(
    trackId
  );
  console.log(
    "[updateTrackAudioFeatures] track with id ",
    trackId,
    "hasAudioFeatures",
    hasAudioFeatures
  );

  if (hasAudioFeatures) {
    return track;
  }
  let mostRecentListenUserId = await UserListen.findUserIdForMostRecentListen(
    track._id
  );
  if (!mostRecentListenUserId) {
    console.log(
      "mostRecentListenUserId is undefined... falling back to FALLBACK_USER_ID"
    );
    mostRecentListenUserId = FALLBACK_USER_ID;
  }
  console.log(
    "[updateTrackAudioFeatures] mostRecentListenUserId: ",
    mostRecentListenUserId
  );
  const { accessToken } = await fetchUserSpotifyAuth(mostRecentListenUserId);

  const audioFeatures = await fetchAudioFeatures(
    accessToken,
    track.thirdPartyId
  );

  const result = await Track.findOneAndUpdate(
    { _id: trackId },
    { audioFeatures }
  );

  return result;
}
