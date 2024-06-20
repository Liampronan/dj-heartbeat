import FirebaseAuth
import Foundation

class SpotifyTokenAPI {
    static private let endpoint = URL(
        string: "\(Config.apiBaseURL)/generateClientToken"
    )!
    
    static func postToken(reqParams: GenerateClientTokenRequestParams) {
        var request = URLRequest(url: endpoint)
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        
        do {
            // convert parameters to Data and assign dictionary to httpBody of request
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            request.httpBody = try encoder.encode(reqParams)
          } catch let error {
            print("~~~error: \(error.localizedDescription)")
            return
          }
        
        let t = URLSession.shared.dataTask(with: request) { data, res, err in
            if let data {
                do {
                    let decoder = JSONDecoder.withJSDateDecoding()
                    let apiResponse = try decoder.decodeJSON(GenerateClientTokenResponse.self, from: data)
                    Auth.auth().signIn(withCustomToken: apiResponse.customToken) { user, error in
                        if let user {
                            print("~~ user signed in ", user)
                        }
                        if let error {
                            print("~~ error ", error)
                        }
                    }
                } catch {
                    print("Error decoding: \(error.localizedDescription)")
                }
            }
            if let err {
                print("~~ err: \(err)")
            }
        }
        t.resume()
    }
}
