import Foundation

typealias SocialFeedDataState = FetchableDataState<FetchSocialFeedResponse>

protocol SocialFeedProvider {
    var state: SocialFeedDataState { get }
    func fetchSocialFeed() async
}

@Observable class SocialFeedDataModel: SocialFeedProvider {
    var state = SocialFeedDataState.loading
    
    func fetchSocialFeed() async {
        do {
            let response = try await SocialFeedAPI.fetchSocialFeed()
            state = .fetched(response)
        } catch {
            print("error", error)
        }
    }
}

struct PreviewSocialFeedProvider: SocialFeedProvider {
    var state: SocialFeedDataState
    func fetchSocialFeed() async {}
}

extension SocialFeedProvider where Self == PreviewSocialFeedProvider {
    static var loading: Self {
        PreviewSocialFeedProvider(state: .loading)
    }
    
    static var fetchedManyResults: Self {
        PreviewSocialFeedProvider(
            state: .fetched(FetchSocialFeedResponse.mockManyResults())
        )
    }
    
    static var fetchedNoResults: Self {
        PreviewSocialFeedProvider(
            state: .fetched(FetchSocialFeedResponse.mockNoResults())
        )
    }
}
