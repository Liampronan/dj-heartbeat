import Foundation

protocol UserEventsProvider {
    var authProvider: AuthProvider { get }
    func postAppOpened() async
}

@Observable class UserEventsDataModel: UserEventsProvider {
    var authProvider: AuthProvider
    
    init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }
    
    func postAppOpened() async {
        do {
            try await UserEventsAPI.postAppOpened(userAuthToken: authProvider.userAuthToken)
        } catch {
            print("error postingAppOpened")
        }
    }
}

@Observable class PreviewUserEventsDataModel: UserEventsProvider {
    var authProvider: AuthProvider
    
    init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }
    
    func postAppOpened() async {}
}

extension UserEventsProvider where Self == PreviewUserEventsDataModel {
    static var noopPostAppOpened: Self {
        PreviewUserEventsDataModel(authProvider: PreviewAuthProvider.isLoggedIn)
    }
}
