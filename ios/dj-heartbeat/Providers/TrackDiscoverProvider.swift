import Foundation

typealias TrackDiscoverDataState = FetchableDataState<[TrackDiscoverCategory]>

protocol TrackDiscoverProvider {
    var state: TrackDiscoverDataState { get }
    func fetchTrackDiscover() async
}

@Observable class TrackDiscoverDataModel: TrackDiscoverProvider {
    var state = TrackDiscoverDataState.loading
    
    func fetchTrackDiscover() async {
        do {
            let trackDiscoverApiResponse = try await TrackDiscoverAPI.getTracksDiscover()
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
    
    init(state: TrackDiscoverDataState) {
        self.state = state
    }
    
    func fetchTrackDiscover() async {}
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
