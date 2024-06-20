export async function fetchSpotifyProfile(
  token: string
): Promise<SpotifyApi.CurrentUsersProfileResponse> {
  const result = await fetch("https://api.spotify.com/v1/me", {
    method: "GET",
    headers: { Authorization: `Bearer ${token}` },
  });

  return await result.json();
}

// note: spotify api only returns last 50 recently played.
// so we need a job to consistently poll this or else it's subject to gaps.
export async function getRecentlyPlayed(accessToken: string) {
  const params = new URLSearchParams({ limit: "50" });
  const urlWithParams =
    "https://api.spotify.com/v1/me/player/recently-played?" + params;
  const response = await fetch(urlWithParams, {
    headers: {
      Authorization: "Bearer " + accessToken,
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching recently played: ${response.status} (${response.statusText})\n${responseText}`
    );
  }
  const responseJSON = await response.json();
  return responseJSON.items;
}

interface ICreatePlaylistRequest {
  accessToken: string;
  spotifyUserId: string;
  playlistName: string;
  playlistDescription: string;
  playistIsPublic: boolean;
}

interface ICreatePlaylistResponse {
  spotifyUrl: string;
  spotifyUri: string;
}

export async function createPlaylist(
  params: ICreatePlaylistRequest
): Promise<ICreatePlaylistResponse> {
  const url = `https://api.spotify.com/v1/users/${params.spotifyUserId}/playlists`;

  const response = await fetch(url, {
    method: "POST",
    body: JSON.stringify({
      name: params.playlistName,
      description: params.playlistDescription,
      public: params.playistIsPublic,
    }),
    headers: {
      Authorization: "Bearer " + params.accessToken,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while createPlaylist: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  const responseJSON = await response.json();
  const spotifyUrl =
    responseJSON.external_urls && responseJSON.external_urls.spotify;
  const spotifyUri = responseJSON.uri;
  if (!spotifyUrl || !spotifyUri)
    throw new Error(
      "Createplaylist resposne: malformed. Missing spotifyUrl or spotifyUri"
    );
  return {
    spotifyUrl,
    spotifyUri,
  };
}

interface IAddSingleTrackToPlaylistRequest {
  spotifyPlaylistId: string;
  spotifyTrackUri: string;
  accessToken: string;
}

interface IAddToPlaylistResponse {
  snapshotId: string;
}
export async function addToPlaylist(
  params: IAddSingleTrackToPlaylistRequest
): Promise<IAddToPlaylistResponse> {
  const url = `https://api.spotify.com/v1/playlists/${params.spotifyPlaylistId}/tracks`;

  const response = await fetch(url, {
    method: "POST",
    body: JSON.stringify({
      uris: [params.spotifyTrackUri],
    }),
    headers: {
      Authorization: "Bearer " + params.accessToken,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while addToPlaylist: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  const responseJSON = await response.json();
  const snapshotId = responseJSON.snapshot_id;
  if (!snapshotId)
    throw new Error("Add to playlist response: malformed. Missing snapshotId");
  return {
    snapshotId,
  };
}

interface IAddMultipleTracksToPlaylistRequest {
  spotifyPlaylistId: string;
  spotifyTrackUris: string[];
  accessToken: string;
}

export async function addTracksToPlaylist(
  params: IAddMultipleTracksToPlaylistRequest
): Promise<IAddToPlaylistResponse> {
  if (params.spotifyTrackUris.length === 0) {
    throw new Error("No tracks in playlist");
  }
  const url = `https://api.spotify.com/v1/playlists/${params.spotifyPlaylistId}/tracks`;
  console.log(params.spotifyTrackUris);
  console.log("spotifyPlaylistId", params.spotifyPlaylistId);
  const response = await fetch(url, {
    method: "POST",
    body: JSON.stringify({
      uris: params.spotifyTrackUris,
    }),
    headers: {
      Authorization: "Bearer " + params.accessToken,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while addToPlaylist: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  const responseJSON = await response.json();
  const snapshotId = responseJSON.snapshot_id;
  if (!snapshotId)
    throw new Error("Add to playlist response: malformed. Missing snapshotId");
  return {
    snapshotId,
  };
}

export async function editSpotifyPlaylistDescription(
  accessToken: string,
  spotifyPlaylistId: string,
  description: string
) {
  const url = `https://api.spotify.com/v1/playlists/${spotifyPlaylistId}`;

  const response = await fetch(url, {
    method: "PUT",
    body: JSON.stringify({
      description: description,
    }),
    headers: {
      Authorization: "Bearer " + accessToken,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while editSpotifyPlaylistDescription: ${response.status} (${response.statusText})\n${responseText}`
    );
  }
  // no shapshot returned here...
  return true;
}

export async function fetchPlaylist(
  accessToken: string,
  playlistId: string
): Promise<SpotifyApi.PlaylistObjectFull> {
  const url = `https://api.spotify.com/v1/playlists/${playlistId}`;
  const response = await fetch(url, {
    headers: {
      Authorization: "Bearer " + accessToken,
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching playlist: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  return await response.json();
}

export async function fetchTracks(
  accessToken: string,
  trackIds: string[]
): Promise<SpotifyApi.TrackObjectFull[]> {
  if (trackIds.length === 0) return [];
  const encodedTrackIds = encodeURIComponent(trackIds.join(","));
  const url = `https://api.spotify.com/v1/tracks/?ids=${encodedTrackIds}`;

  const response = await fetch(url, {
    headers: {
      Authorization: "Bearer " + accessToken,
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching tracks: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  return ((await response.json()) as SpotifyApi.MultipleTracksResponse).tracks;
}

interface IRemoveTracksFromPlaylistParams {
  accessToken: string;
  spotifyPlaylistId: string;
  spotifyTrackUris: string[];
}

export async function removeTracksFromPlaylist(
  params: IRemoveTracksFromPlaylistParams
) {
  const url = `https://api.spotify.com/v1/playlists/${params.spotifyPlaylistId}/tracks`;

  const tracksBodyArray = params.spotifyTrackUris.map((uri) => {
    return { uri };
  });

  const response = await fetch(url, {
    method: "DELETE",
    body: JSON.stringify({
      tracks: tracksBodyArray,
    }),
    headers: {
      Authorization: "Bearer " + params.accessToken,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while removeTracksFromPlaylist: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  const responseJSON = await response.json();
  const snapshotId = responseJSON.snapshot_id;
  if (!snapshotId)
    throw new Error(
      "removeTracksFromPlaylist response: malformed. Missing snapshotId"
    );
  return {
    snapshotId,
  };
}

export async function fetchAudioFeatures(
  accessToken: string,
  trackId: string
): Promise<SpotifyApi.AudioFeaturesResponse> {
  const url = `https://api.spotify.com/v1/audio-features/${trackId}`;
  const response = await fetch(url, {
    headers: {
      Authorization: "Bearer " + accessToken,
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching audio features: ${response.status} (${response.statusText})\n${responseText}`
    );
  }

  return await response.json();
}

export async function fetchRelatedTracks(
  accessToken: string,
  trackdId: string,
  limit = 5 // for now keep limit low to help with rate limit. can expand this if we have better api back-off support.
): Promise<SpotifyApi.RecommendationsFromSeedsResponse> {
  const encodedSeedTrackIds = encodeURIComponent(trackdId);
  // note: this is a pretty simple use of recommendations.
  // check out more options here: https://developer.spotify.com/documentation/web-api/reference/get-recommendations
  const url = `https://api.spotify.com/v1/recommendations?seed_tracks=${encodedSeedTrackIds}&limit=${limit}`;
  const response = await fetch(url, {
    headers: {
      Authorization: "Bearer " + accessToken,
    },
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching related tracks: ${response.status} (${response.statusText})\n${responseText}`
    );
  }
  const result = await response.json();
  return result;
}

export async function spotifyQueryForTrack(
  title: string,
  accessToken: string
): Promise<SpotifyApi.SearchResponse> {
  const query = `${title}`;

  const encodedQuery = encodeURIComponent(query);
  const url = `https://api.spotify.com/v1/search?q=${encodedQuery}&type=track&limit=50`;
  const response = await fetch(url, {
    headers: {
      Authorization: "Bearer " + accessToken,
    },
  });
  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `Error while fetching related tracks: ${response.status} (${response.statusText})\n${responseText}`
    );
  }
  const result = await response.json();

  return result;
}
