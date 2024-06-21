import { handleAppOpened } from "../../services/appOpenedService";
import { fetchUserSpotifyAuth } from "../../services/spotifyAuthService";
import { pullDefaultPlaylistFromSpotify } from "../../services/userPlaylistService";

jest.mock("../../services/spotifyAuthService");
jest.mock("../../services/userPlaylistService");

describe("handleAppOpened", () => {
  const mockFetchUserSpotifyAuth = fetchUserSpotifyAuth as jest.Mock;
  const mockPullDefaultPlaylistFromSpotify =
    pullDefaultPlaylistFromSpotify as jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should return early if uid is not provided", async () => {
    await handleAppOpened("");
    expect(mockFetchUserSpotifyAuth).not.toHaveBeenCalled();
    expect(mockPullDefaultPlaylistFromSpotify).not.toHaveBeenCalled();
  });

  it("should fetch user Spotify auth and pull default playlist if uid is provided", async () => {
    const mockAuth = { accessToken: "mockAccessToken" };
    mockFetchUserSpotifyAuth.mockResolvedValue(mockAuth);

    await handleAppOpened("testUid");

    expect(mockFetchUserSpotifyAuth).toHaveBeenCalledWith("testUid");
    expect(mockPullDefaultPlaylistFromSpotify).toHaveBeenCalledWith(
      "mockAccessToken",
      "testUid"
    );
  });
});
