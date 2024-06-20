import Foundation

struct TopTracksResponse: Codable {
    let lastWeek: TopChartsWeekResponse
    let thisWeek: TopChartsWeekResponse
    
    static func mock() -> Self {
        return .init(lastWeek: .mock1(), thisWeek: .mock2())
    }
}

struct TopChartsWeekResponse: Codable {
    let topTracks: [WeeklyTopTrack]
    let sumOfAllCountedHearbeats: Int
    
    static func mock1() -> Self {
        return .init(
            topTracks: [
                WeeklyTopTrack.mock(with: mockTrack), 
                WeeklyTopTrack.mock(with: mockTrack2),
                WeeklyTopTrack.mock(with: mockTrack10),
                WeeklyTopTrack.mock(with: mockTrack4),
                WeeklyTopTrack.mock(with: mockTrack9),
                WeeklyTopTrack.mock(with: mockTrack7)
            ], sumOfAllCountedHearbeats: 120239
        )
    }
    
    static func mock2() -> Self {
        return .init(
            topTracks: [
                WeeklyTopTrack.mock(with: mockTrack8),
                WeeklyTopTrack.mock(with: mockTrack4),
                WeeklyTopTrack.mock(with: mockTrack3),
                WeeklyTopTrack.mock(with: mockTrack6),
                WeeklyTopTrack.mock(with: mockTrack5),
                WeeklyTopTrack.mock(with: mockTrack11)
            ], sumOfAllCountedHearbeats: 76432)
    }
}

struct TopTracksAPI {
    static private let endpoint = URL(
        string: "\(Config.apiBaseURL)/handleWorkout"
    )!
    
    static func getTopCharts() async throws -> TopTracksResponse {
         let topTracksEndpoint = URL(
            string: "\(Config.apiBaseURL)/top-tracks"
        )!
        
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: topTracksEndpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "GET"
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(TopTracksResponse.self, from: data)
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
}
