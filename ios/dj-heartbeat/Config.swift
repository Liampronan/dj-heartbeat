import Foundation

struct Config {
    private static func environment() -> [String: Any] {
        let fileName = "config"
        let path = Bundle.main.path(forResource: fileName, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    static var apiBaseURL: URL {
        let strVal = environment()["apiBaseURL"] as! String
        return URL(string: strVal)!
    }
    
    static var spotifyClientId: String {
        return environment()["spotifyClientId"] as! String
    }

    static var spotifyRedirectURL: String {
        return environment()["spotifyRedirectURL"] as! String
    }
}
