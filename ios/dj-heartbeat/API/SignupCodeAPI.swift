import Foundation

struct VerifySignupCodeRequest: Codable {
    let signupCode: String
}

struct VerifySignupCodeResponse: Codable {
    let isCodeValid: Bool
}

struct SignupCodeAPI {
    static private let endpoint = URL(
        string: "\(Config.apiBaseURL)/signup-code"
    )!
    
    @discardableResult static func verifySignupCode(req: VerifySignupCodeRequest) async throws -> VerifySignupCodeResponse {
        let res = try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: endpoint)
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"
            
            
            do {
                let encoder = JSONEncoder()
                request.httpBody = try encoder.encode(req)
              } catch let error {
                print("~~~error: \(error.localizedDescription)")
              }
            
            let t = URLSession.shared.dataTask(with: request) { data, res, err in
                if let data {
                    do {
                        let decoder = JSONDecoder.withJSDateDecoding()
                        let apiResponse = try decoder.decodeJSON(VerifySignupCodeResponse.self, from: data)
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
