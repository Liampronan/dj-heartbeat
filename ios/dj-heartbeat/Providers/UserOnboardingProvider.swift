import Foundation

enum UserOnboardingState: Equatable {
    case hasGrantedSpotifyAccess
    case hasNotGrantedSpotifyAccess
    /// this state signifies users who have not connected a spotify account but can view the app.
    /// while we wait for spotify to enable us to onboard GA users, this is a way to let ppl use the app with limited features. 
    case notEnabledForSpotifyAccess
    
    var hasGrantedSpotifyAccess: Bool {
        self == .hasGrantedSpotifyAccess
    }
}

protocol UserOnboardingProvider {
    var authProvider: AuthProvider { get }
    
    var state: FetchableDataState<UserOnboardingState> { get }
    
    func fetchStateForUser() async
    
    func setStateToNotEnabledForSpotifyAccess() async
}

extension UserOnboardingProvider {
    /// user is logged in and has granted spotify access. helpful for gating spotify-specific features 
    var isUserFullyLoggedIn: Bool {
        switch state {
        case .fetched(let onboardingState):
            return onboardingState == .hasGrantedSpotifyAccess
        case .error, .loading:
            return false
        }
    }
}

@Observable class UserOnboardingDataModel: UserOnboardingProvider {
    var authProvider: AuthProvider
    private(set) var state: FetchableDataState<UserOnboardingState> = .loading
    
    init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }
    
    func fetchStateForUser() async {
        await authProvider.fetchState()
        do {
            guard try await authProvider.isLoggedIn() else {
                state = .fetched(.hasNotGrantedSpotifyAccess)
                return
            }
            
            state = .fetched(.hasGrantedSpotifyAccess)
        } catch {
            state = .error
        }
       
    }
    
    func setStateToNotEnabledForSpotifyAccess() {
        state = .fetched(.notEnabledForSpotifyAccess)
    }
}

@Observable class PreviewUserOnboardDataModel: UserOnboardingProvider {
    var authProvider: AuthProvider
    private(set) var state: FetchableDataState<UserOnboardingState>
    
    init(state: FetchableDataState<UserOnboardingState>, authProvider: AuthProvider = PreviewAuthProvider.isLoggedIn) {
        self.state = state
        self.authProvider = authProvider
    }
    
    func fetchStateForUser() async {
        print("no-op fetchStateForUser")
    }
    
    func setStateToNotEnabledForSpotifyAccess() {
        print("no-op setStateToNotEnabledForSpotifyAccess")
    }
}

extension UserOnboardingProvider where Self == PreviewUserOnboardDataModel {
    static var loading: Self {
        return Self.init(state: .loading)
    }
    
    static var fetchedHasGrantedSpotifyAccess: Self {
        return Self.init(state: .fetched(.hasGrantedSpotifyAccess))
    }
    
    static var fetchedNotEnabledForSpotifyAccess: Self {
        return Self.init(state: .fetched(.notEnabledForSpotifyAccess))
    }
}
