import { RelatedTrack } from "../models/RelatedTrack";
import { Track } from "../models/Track";
import { UserListen } from "../models/UserListen";
import { fetchRelatedTracks } from "./spotifyAPIService";
import { fetchUserSpotifyAuth } from "./spotifyAuthService";
import { _saveTracksFromTrackRecommendations } from "./userListensService";

const FALLBACK_USER_ID = "spotify:liampronan";

export async function generateRelatedTracks(trackId: string) {
  const existingRelatedTracks = await RelatedTrack.find({
    originalTrack: trackId,
  });
  // for now, we only fetch recommondations once. probs will revisit them
  if (existingRelatedTracks.length > 0) {
    return existingRelatedTracks;
  }
  // we use most recent user to get recs. this will mostly be liam to start but others could add variety as ppl join. from there, we can consider user-specific receommendations.
  let mostRecentListenUserId = await UserListen.findUserIdForMostRecentListen(
    trackId
  );
  if (!mostRecentListenUserId) {
    console.log(
      "mostRecentListenUserId is undefined... falling back to FALLBACK_USER_ID"
    );
    mostRecentListenUserId = FALLBACK_USER_ID;
  }

  const { accessToken } = await fetchUserSpotifyAuth(mostRecentListenUserId);

  const track = await Track.findById(trackId);
  if (!track) throw new Error(`Missing track for trackId: ${trackId}`);
  const relatedTracksResponse = await fetchRelatedTracks(
    accessToken,
    track.thirdPartyId
  );

  const relatedTrackThirdPartyIds = relatedTracksResponse.tracks.map(
    (track) => track.id
  );
  // TODO: consider storing state in db to handle edge case of api returning 0 matches. in that case, we we'd potentially check this api again in the future indefinitely. maybe not a big deal
  if (relatedTrackThirdPartyIds.length === 0) {
    return;
  }

  await _saveTracksFromTrackRecommendations(relatedTracksResponse);

  const savedRelatedTracks = await Track.find({
    thirdPartyId: { $in: relatedTrackThirdPartyIds },
  });
  const objsToSave = savedRelatedTracks.map((savedRelatedTrack) => {
    return { originalTrack: track._id, relatedTrack: savedRelatedTrack._id };
  });

  return RelatedTrack.insertRelatedTracks(objsToSave);
}
