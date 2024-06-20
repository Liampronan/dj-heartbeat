import Foundation

struct HandleWorkoutResponse: Codable, Identifiable, Equatable {
    static func == (lhs: HandleWorkoutResponse, rhs: HandleWorkoutResponse) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: UUID { return UUID() }
    let userListens: [UserListen]
    
    var maxSongHeartbeatsDuringThisWorkout: Int {
        userListens.max { l1, l2 in
            l1.heartbeats < l2.heartbeats
        }?.heartbeats ?? 1
    }
}

struct HandleWorkoutRequest: Codable {
    let heartRateInfo: [HeartRateSample]
    let workoutType: WorkoutType
}

struct HeartRateAPI {
    static private let endpoint = URL(
        string: "\(Config.apiBaseURL)/handleWorkout"
    )!
    
    @discardableResult static func postData(req: HandleWorkoutRequest) async throws -> HandleWorkoutResponse {
        guard let firebaseIdToken = try await MyUser.shared.getToken() else { throw MyUserError.noCurrentUserToken }
        
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: endpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            
            
            do {
                // convert parameters to Data and assign dictionary to httpBody of request
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .millisecondsSince1970
                request.httpBody = try encoder.encode(req)
              } catch let error {
                print("~~~error: \(error.localizedDescription)")
              }
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(HandleWorkoutResponse.self, from: data)
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
