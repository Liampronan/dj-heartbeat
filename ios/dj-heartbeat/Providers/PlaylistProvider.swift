import Foundation

typealias PlaylistDataState = FetchableDataState<FetchDefaultPlaylistResponse>
/// keeps state for updating individual tracks to playlist, like adding to playlist.
/// helps differentiate when a single track is being adding vs. entire playlist is fetching
typealias TrackPlaylistUpdatesInProgress = [Track_DEPRECATED: PlaylistTrackState]

extension PlaylistDataState {
    func playlistTrackState(for track: Track_DEPRECATED, with updatesInProgress: TrackPlaylistUpdatesInProgress) -> PlaylistTrackState {
        // example: we're adding a track to playlist, we want UI to be able to reflect that single track is being adding (vs. entire playlist is updating)
        if let trackUpdateInProgress = updatesInProgress[track] {
            return trackUpdateInProgress
        }
        
        switch self {
        case .fetched(let playlistResponse):
            guard playlistResponse.playlist.contains(track: track) else { return .notAddedToPlaylist }
            return .addedToPlaylist
        case .error:
            return .error
        case .loading:
            return .loading
        }
    }
}

protocol PlaylistProvider {
    var state: PlaylistDataState { get }
    var authProvider: AuthProvider { get }
    func fetchDefaultPlaylist() async
    
    func playlistTrackState(for track: Track_DEPRECATED) -> PlaylistTrackState
    func addToDefaultPlaylist(track: Track_DEPRECATED) async throws
}

enum PlaylistTrackState {
    case notAddedToPlaylist
    case loading
    case error
    case addedToPlaylist
}

@Observable class PlaylistDataModel: PlaylistProvider {
    var state = PlaylistDataState.loading
    var authProvider: AuthProvider
    var trackUpdatingStates = [Track_DEPRECATED: PlaylistTrackState]()
    
    init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }
    
    func playlistTrackState(for track: Track_DEPRECATED) -> PlaylistTrackState {
        state.playlistTrackState(for: track, with: trackUpdatingStates)
    }
    
    func fetchDefaultPlaylist() async {
        do {
            let req = FetchDefaultPlaylistRequest(
                userAuthToken: authProvider.userAuthToken
            )
            let response = try await PlaylistAPI.fetchDefaultPlaylist(req: req)
            state = .fetched(response)
        } catch {
            print("error", error)
        }
    }
    
    func addToDefaultPlaylist(track: Track_DEPRECATED) async throws {
        trackUpdatingStates[track] = .loading
        
        let req = AddToPlaylistRequest(
            userAuthToken: authProvider.userAuthToken,
            trackId: track.id
        )
        let updatedPlayist = try await PlaylistAPI.addToPlaylist(
            req: req
        )
        state = .fetched(updatedPlayist)
        
        trackUpdatingStates[track] = nil
    }
}

@Observable class PreviewPlaylistProvider: PlaylistProvider {
    var state: PlaylistDataState
    var authProvider: AuthProvider
    var trackUpdatingStates = [Track_DEPRECATED: PlaylistTrackState]()
    
    init(state: PlaylistDataState, authProvider: AuthProvider = PreviewAuthProvider.isLoggedIn) {
        self.state = state
        self.authProvider = authProvider
    }
    
    func fetchDefaultPlaylist() async {}
    
    func playlistTrackState(for track: Track_DEPRECATED) -> PlaylistTrackState {
        state.playlistTrackState(for: track, with: trackUpdatingStates)
    }
    
    func addToDefaultPlaylist(track: Track_DEPRECATED) async throws {
        trackUpdatingStates[track] = .loading
        let updatedPlayist = FetchDefaultPlaylistResponse.mockAddToPlaylist(newTrack: track)
        state = .fetched(updatedPlayist)
        trackUpdatingStates[track] = nil
    }
}

extension PlaylistProvider where Self == PreviewPlaylistProvider {
    static var loading: Self {
        PreviewPlaylistProvider(state: .loading)
    }
    
    static var error: Self {
        PreviewPlaylistProvider(state: .error)
    }
    
    static var fetchedManyResults: Self {
        PreviewPlaylistProvider(
            state: .fetched(FetchDefaultPlaylistResponse.mockManyResults())
        )
    }
    
    static var fetchedNoResults: Self {
        PreviewPlaylistProvider(
            state: .fetched(FetchDefaultPlaylistResponse.mockNoResults())
        )
    }
}
