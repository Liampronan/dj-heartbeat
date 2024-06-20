import Foundation

struct TrackDiscoverCategoryResponse: Codable, Equatable {
    let tracks: [Track]
    let titleText: String
    let descriptionText: String
}

struct TrackDiscoverResponse: Codable {
    let recentlyPlayed: TrackDiscoverCategoryResponse
    let leastRecentlyPlayed: TrackDiscoverCategoryResponse
    let suggestedForYou: TrackDiscoverCategoryResponse
    let random: TrackDiscoverCategoryResponse
    let unheardOf: TrackDiscoverCategoryResponse
}

struct TrackDiscoverAPI {
    static func getTracksDiscover() async throws -> TrackDiscoverResponse {
        let endpoint = URL(
            string: "\(Config.apiBaseURL)/tracks/discover"
        )!
        
        #if targetEnvironment(simulator)
        do {
            return try await getTrackDiscoverMocks()
        }
        #endif
        
        guard let firebaseIdToken = try await MyUser.shared.getToken() else { throw MyUserError.noCurrentUserToken }
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: endpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(TrackDiscoverResponse.self, from: data)
                        
                        continuation.resume(with: .success(apiResponse))
                        print("successful api response!!")
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                if let err {
                    print("~~ err: \(err)")
                }
            }
            t.resume()
        }
        return res
    }
    
    static func getTrackDiscoverMocks() async throws -> TrackDiscoverResponse {
        .init(
            recentlyPlayed: .init(tracks: [mockTrack], titleText: "Just Played", descriptionText: "The tracks you've listened to while working out recently."),
            leastRecentlyPlayed: .init(tracks: [mockTrack], titleText: "Play me maybe", descriptionText: "The tracks you have listened to in the past... but not recently."),
            suggestedForYou: .init(tracks: [mockTrack], titleText: "Suggested for you", descriptionText: "Some recs based on some workout tracks you like."),
            random: .init(tracks: [mockTrack], titleText: "Random", descriptionText: "Tracks that others have worked out to."),
            unheardOf: .init(tracks: [mockTrack], titleText: "unheardOf", descriptionText: "Workout hits that you haven't listened to.")
        )
    }
}
