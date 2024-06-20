import Foundation

struct SendFeedbackRequest: Codable {
    let userAuthToken: String?
    let feedback: String
    let contact: String?
}

struct SendFeedbackAPI {
    static private let endpoint = URL(
        string: "\(Config.apiBaseURL)/feedback"
    )!
    
    static func postData(req: SendFeedbackRequest) async throws {
        guard let userAuthToken = req.userAuthToken else { throw AuthError.noCurrentUserToken } // TODO: renmae error
        try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: endpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            request.setValue("Bearer \(userAuthToken)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            
            
            do {
                let encoder = JSONEncoder()
                request.httpBody = try encoder.encode(req)
              } catch let error {
                print("~~~error: \(error.localizedDescription)")
              }
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if data != nil {
                    continuation.resume()
                }
                if let err {
                    print("~~ err: \(err)")
                }
            }
            t.resume()
        }
    }
}
