import FirebaseAuth
import Foundation

typealias AuthProviderFetchableState = FetchableDataState<AuthProviderState>
enum AuthProviderState {
    case isLoggedIn(token: String)
    case isLoggedOut
    
    var isLoggedIn: Bool {
        return switch self {
        case .isLoggedIn(_): true
        case .isLoggedOut: false
        }
    }
    
    var userAuthToken: String? {
        return switch self {
        case .isLoggedIn(let token): token
        case .isLoggedOut: nil
        }
    }
}

protocol AuthProvider {
    var state: FetchableDataState<AuthProviderState> { get }
    var user: AnyUserInfo? { get }
    func isLoggedIn() async throws -> Bool
    func config() async
    func fetchState() async
    func signOut() throws
    var userAuthToken: String? { get }
}

@Observable class FirebaseAuthDataModel: AuthProvider {
    var state: FetchableDataState<AuthProviderState> = .loading
    var user: AnyUserInfo? = nil
    
    var userAuthToken: String? {
        return switch state {
        case .fetched(let loggedInState):
            loggedInState.userAuthToken
        case .error, .loading: nil
        }
    }
    
    func isLoggedIn() async throws -> Bool {
        switch state {
        case .error, .loading:
            return false
            
        case .fetched(let authProviderState):
            return authProviderState.isLoggedIn
        }
    }
    
    func config() async {
        // attach listener so we can store user if they are already logged in (or when they login) for example. 
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user {
                self.user = AnyUserInfo(user)
            } else {
                self.user = nil
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func fetchState() async {
        state = .loading
        do {
            guard let token = try await getToken() else {
                state = .fetched(.isLoggedOut)
                return
            }
            state = .fetched(.isLoggedIn(token: token))
        } catch {
            state = .error
        }
    }
    
    @discardableResult func getToken() async throws -> String?  {
        let currentUser = Auth.auth().currentUser
        guard let currentUser else { return nil }
        return try await currentUser.getIDToken()
    }
}

@Observable class PreviewAuthProvider: AuthProvider {
    var state: AuthProviderFetchableState
    var user: AnyUserInfo?
    
    init(state: AuthProviderFetchableState) {
        self.state = state
    }
    
    var userAuthToken: String? {
        return switch state {
        case .fetched(let loggedInState):
            loggedInState.userAuthToken
        case .error, .loading: nil
        }
    }
    
    func isLoggedIn() async throws -> Bool {
        switch state {
        case .error, .loading:
            return false
            
        case .fetched(let authProviderState):
            return authProviderState.isLoggedIn
        }
    }
    
    func config() {
        
    }
    
    func fetchState() async {
        print("mock fetchState no-op")
    }
    
    func signOut() throws {
        print("mock signOut no-op")
    }
}

extension AuthProvider where Self == PreviewAuthProvider {
    static var loading: Self {
        PreviewAuthProvider(state: .loading)
    }
    
    static var isLoggedIn: Self {
        return PreviewAuthProvider(state: .fetched(.isLoggedIn(token: "testToken123")))
    }
    
    static var isLoggedOut: Self {
        return PreviewAuthProvider(state: .fetched(.isLoggedOut))
    }
}


protocol UserInfo {
    var uid: String { get }
    var presentableUserName: String { get }
}

/// Wraps protocol in contrete Equatable implementation so we can listen to changes via`onChange`
/// This seems a little funky but solves the issue, which only happens in one place.
@Observable class AnyUserInfo: Equatable {
    private let _base: UserInfo
    private let _equals: (UserInfo) -> Bool

    init<T: UserInfo & Equatable>(_ base: T) {
        self._base = base
        self._equals = { other in
            guard let otherBase = other as? T else { return false }
            return base == otherBase
        }
    }

    static func == (lhs: AnyUserInfo, rhs: AnyUserInfo) -> Bool {
        return lhs._equals(rhs._base)
    }
}

enum AuthError: Error {
    case noCurrentUserToken
}
