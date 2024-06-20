import Foundation

typealias TrackDiscoverDataState = FetchableDataState<[TrackDiscoverCategory]>

protocol TrackDiscoverProvider {
    var state: TrackDiscoverDataState { get }
    var authProvider: AuthProvider { get }
    func fetchTrackDiscover() async
}

@Observable class TrackDiscoverDataModel: TrackDiscoverProvider {
    var state = TrackDiscoverDataState.loading
    var authProvider: AuthProvider
    
    init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }
    
    func fetchTrackDiscover() async {
        do {
            let request = FetchTrackDiscoverRequest(userAuthToken: authProvider.userAuthToken)
            let trackDiscoverApiResponse = try await TrackDiscoverAPI.fetchTracksDiscover(req: request)
            self.state = .fetched(
                TrackDiscoverCategory.initCategories(from: trackDiscoverApiResponse)
            )
        } catch {
            self.state = .error
        }
    }
}

@Observable class PreviewTrackDiscoverProvider: TrackDiscoverProvider {
    var state: TrackDiscoverDataState
    var authProvider: AuthProvider
    
    init(state: TrackDiscoverDataState, authProvider: AuthProvider = PreviewAuthProvider.isLoggedIn) {
        self.state = state
        self.authProvider = authProvider
    }
    
    func fetchTrackDiscover() async {
        // mocks are injected via `state` in init so we don't need implementation here
    }
}

extension TrackDiscoverProvider where Self == PreviewTrackDiscoverProvider {
    static var loading: Self {
        PreviewTrackDiscoverProvider(state: .loading)
    }
    
    static var fetchedManyResults: Self {
        PreviewTrackDiscoverProvider(
            state: .fetched(TrackDiscoverCategory.mocks)
        )
    }
}
