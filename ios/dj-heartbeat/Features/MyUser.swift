import FirebaseAuth
import Foundation

typealias AuthProviderFetchableState = FetchableDataState<AuthProviderState>
enum AuthProviderState {
    case isLoggedIn
    case isLoggedOut
    
    var isLoggedIn: Bool {
        self == .isLoggedIn
    }
}

protocol AuthProvider {
    var state: FetchableDataState<AuthProviderState> { get }
    
    func isLoggedIn() async throws -> Bool
}

@Observable class AuthDataModel: AuthProvider {
    
    var state: FetchableDataState<AuthProviderState> = .loading
    
    // TOOD: 
    // 1. remove isLoggedIn() from protocol -- should just be done on state
    // 1a. remove isLoggedIn() from
    // 2. migrate away from PreviewAuthProvider
    func isLoggedIn() async throws -> Bool {
        switch state {
        case .error, .loading:
            return false
            
        case .fetched(let authProviderState):
            return authProviderState.isLoggedIn
        }
    }
}

@Observable class PreviewAuthProvider: AuthProvider {
    var state: AuthProviderFetchableState
    
    init(state: AuthProviderFetchableState) {
        self.state = state
    }
    
    func isLoggedIn() async throws -> Bool {
        return false
    }
}

extension AuthProvider where Self == PreviewAuthProvider {
    static var loading: Self {
        PreviewAuthProvider(state: .loading)
    }
    
    static var isLoggedIn: Self {
        return PreviewAuthProvider(state: .fetched(.isLoggedIn))
    }
    
    static var isLoggedOit: Self {
        return PreviewAuthProvider(state: .fetched(.isLoggedOut))
    }
}

struct MyUser {
    static var shared = MyUser()
    
    func configure() async {
        do {
            try await getToken()
        } catch {
            print("error configuring...")
        }
    }
    
    func isLoggedIn() async throws -> Bool {
        guard let _ = try await getToken() else {
            return false
        }
        return true
    }
    
    @discardableResult func getToken() async throws -> String?  {
        let currentUser = Auth.auth().currentUser
        guard let currentUser else { return nil }
        return try await currentUser.getIDToken()
    }
}

enum MyUserError: Error {
    case noCurrentUserToken
}
