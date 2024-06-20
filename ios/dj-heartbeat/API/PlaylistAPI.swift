import Foundation

struct AddToPlaylistRequest: Codable {
    let trackId: String
}

struct AddToPlaylistResponse: Codable {
    let track: Track
    let playlistDurationMS: Int
}

struct FetchPlaylistResponse: Codable {
    let playlist: Playlist
}

extension FetchPlaylistResponse {
    static func mockManyResults() -> Self {
        .init(
            playlist: .mock()
        )
    }
    
    static func mockNoResults() -> Self {
        .init(
            playlist: .mockEmptyPlaylist()
        )
    }
    
    static func mockAddToPlaylist(newTrack: Track) -> Self {
        .init(playlist: .mockAddToPlaylist(newTrack: newTrack))
    }
}

class PlaylistAPI {
    static private let baseEndpoint = URL(
        string: "\(Config.apiBaseURL)/default-playlist"
    )!

    static func addToPlaylist(req: AddToPlaylistRequest) async throws -> FetchPlaylistResponse {
        guard let firebaseIdToken = try await MyUser.shared.getToken() else { throw MyUserError.noCurrentUserToken }
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: baseEndpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            
            do {
                // convert parameters to Data and assign dictionary to httpBody of request
                let encoder = JSONEncoder()
                request.httpBody = try encoder.encode(req)
              } catch let error {
                print("~~~error: \(error.localizedDescription)")
                return
              }
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(FetchPlaylistResponse.self, from: data)
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
    
    static func fetchDefaultPlaylist() async throws -> FetchPlaylistResponse {
        guard let firebaseIdToken = try await MyUser.shared.getToken() else { throw MyUserError.noCurrentUserToken }
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: baseEndpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(FetchPlaylistResponse.self, from: data)
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
    
    static func clearDefaultPlaylist() async throws -> FetchPlaylistResponse {
        guard let firebaseIdToken = try await MyUser.shared.getToken() else { throw MyUserError.noCurrentUserToken }
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: baseEndpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "DELETE"
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(FetchPlaylistResponse.self, from: data)
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
}
