import Firebase
import FirebaseAuth
import Observation

// TODO: remove duplication with MyUser
@Observable class FirebaseCurrentUser {
    
    static var shared = FirebaseCurrentUser()
    private (set) var user: User? = nil
    
    init() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user {
                self.user = user
            } else {
                self.user = nil
            }
        }
    }
    
}

extension FirebaseCurrentUser: ProfileInfoable {
    var uid: String {
        user?.uid ?? "n_a"
    }
    
    var presentableUserName: String {
        uid.replacingOccurrences(of: "spotify:", with: "")
    }
    
    var isLoggedIn: Bool {
        return user?.uid != nil
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
}
