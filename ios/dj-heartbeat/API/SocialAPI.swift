import Foundation

struct FetchSocialFeedResponse: Codable {
    let today: DaySocialFeedItems
    let yesterday: DaySocialFeedItems
    
    var hasTodayData: Bool { !today.feedItems.isEmpty }
    
    static func mockManyResults() -> Self {
        .init(
            today: DaySocialFeedItems.mock(),
            yesterday: DaySocialFeedItems.mock()
        )
    }
    
    static func mockNoResults() -> Self {
        .init(
            today: DaySocialFeedItems.mockNoResults(),
            yesterday: DaySocialFeedItems.mockNoResults()
        )
    }
}

class SocialFeedAPI {
    static private let baseEndpoint = URL(
        string: "\(Config.apiBaseURL)/social-feed"
    )!

    static func fetchSocialFeed() async throws -> FetchSocialFeedResponse {
        
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: baseEndpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "GET"
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(FetchSocialFeedResponse.self, from: data)
                        continuation.resume(with: .success(apiResponse))
                    } catch {
                        print("Error decoding: \(error.localizedDescription)")
                        continuation.resume(with: .failure(error))
                    }
                }
                if let err {
                    print("~~ err: \(err)")
                    continuation.resume(with: .failure(err))
                }
            }
            t.resume()
        }
        return res
    }
    
    static func getSocialFeedResponseMocks() async throws -> FetchSocialFeedResponse {
        return .init(
            today: DaySocialFeedItems.mock(),
            yesterday: DaySocialFeedItems.mock()
        )
    }
}
