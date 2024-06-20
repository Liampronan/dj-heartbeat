import Foundation

class UserEventsAPI {
    static private let appOpenedEndpoint = URL(
        string: "\(Config.apiBaseURL)/app-opened"
    )!

    static func postAppOpened() async throws {
        guard let firebaseIdToken = try await MyUser.shared.getToken() else { throw MyUserError.noCurrentUserToken }
        try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: appOpenedEndpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
        
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if data != nil {
                    continuation.resume()
                    return
                }
                if let err {
                    print("~~ err: \(err)")
                    continuation.resume(with: .failure(err))
                }
            }
            t.resume()
        }
    }
}
