import FirebaseAuth
import Foundation

extension User: UserInfo {
    var presentableUserName: String {
        uid.replacingOccurrences(of: "spotify:", with: "")
    }
}
