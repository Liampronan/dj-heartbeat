import Foundation

typealias PlaylistDataState = FetchableDataState<FetchPlaylistResponse>
/// keeps state for updating individual tracks to playlist, like adding to playlist.
/// helps differentiate when a single track is being adding vs. entire playlist is fetching
typealias TrackPlaylistUpdatesInProgress = [Track: PlaylistTrackState]

extension PlaylistDataState {
    func playlistTrackState(for track: Track, with updatesInProgress: TrackPlaylistUpdatesInProgress) -> PlaylistTrackState {
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
    func fetchDefaultPlaylist() async
    
    func playlistTrackState(for track: Track) -> PlaylistTrackState
    func addToDefaultPlaylist(track: Track) async throws
}

enum PlaylistTrackState {
    case notAddedToPlaylist
    case loading
    case error
    case addedToPlaylist
}

@Observable class PlaylistDataModel: PlaylistProvider {
    var state = PlaylistDataState.loading
    var trackUpdatingStates = [Track: PlaylistTrackState]()
    
    func playlistTrackState(for track: Track) -> PlaylistTrackState {
        state.playlistTrackState(for: track, with: trackUpdatingStates)
    }
    
    func fetchDefaultPlaylist() async {
        do {
            let response = try await PlaylistAPI.fetchDefaultPlaylist()
            state = .fetched(response)
        } catch {
            print("error", error)
        }
    }
    
    func addToDefaultPlaylist(track: Track) async throws {
        trackUpdatingStates[track] = .loading
        
        let updatedPlayist = try await PlaylistAPI.addToPlaylist(req: .init(trackId: track.id))
        state = .fetched(updatedPlayist)
        
        trackUpdatingStates[track] = nil
    }
}

@Observable class PreviewPlaylistProvider: PlaylistProvider {
    var state: PlaylistDataState
    var trackUpdatingStates = [Track: PlaylistTrackState]()
    
    init(state: PlaylistDataState) {
        self.state = state
    }
    
    func fetchDefaultPlaylist() async {}
    
    func playlistTrackState(for track: Track) -> PlaylistTrackState {
        state.playlistTrackState(for: track, with: trackUpdatingStates)
    }
    
    func addToDefaultPlaylist(track: Track) async throws {
        trackUpdatingStates[track] = .loading
        let updatedPlayist = FetchPlaylistResponse.mockAddToPlaylist(newTrack: track)
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
            state: .fetched(FetchPlaylistResponse.mockManyResults())
        )
    }
    
    static var fetchedNoResults: Self {
        PreviewPlaylistProvider(
            state: .fetched(FetchPlaylistResponse.mockNoResults())
        )
    }
}
