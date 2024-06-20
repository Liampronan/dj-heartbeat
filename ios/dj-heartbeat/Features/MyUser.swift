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
    
    func isLoggedIn() async throws -> Bool
    func fetchState() async
    
    var userAuthToken: String? { get }
}

@Observable class FirebaseAuthDataModel: AuthProvider {
    var state: FetchableDataState<AuthProviderState> = .loading
    // TODO:
    // -> 0. fetch initial state
    // 1. remove isLoggedIn() from protocol -- should just be done on state
    // 1a. remove isLoggedIn() from
    // 2. migrate away from PreviewAuthProvider [or use this?]
    
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
    
    func fetchState() async {
        state = .loading
        do {
            guard let token = try await getToken() else {
                state = .fetched(.isLoggedOut)
                return
            }
            state = .fetched(.isLoggedIn(token: token))
        } catch {
            state = .error // TODO: can we pass in error here (AuthError.noCurrentUserToken). may need generic error on FetchableDataState protocol
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
    
    func fetchState() async {
        
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

enum AuthError: Error {
    case noCurrentUserToken
}
