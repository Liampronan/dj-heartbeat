import Foundation

typealias HandleWorkoutFetchableState = FetchableDataState<HandleWorkoutResponse>

protocol HandleWorkoutProvider {
    var authProvider: AuthProvider { get }
    var state: HandleWorkoutFetchableState { get }
    func postWorkoutInfo(hrInfo: [HeartRateSample], workoutType: WorkoutType) async
}

@Observable class HandleWorkoutDataModel: HandleWorkoutProvider {
    var authProvider: AuthProvider
    var state: HandleWorkoutFetchableState = .loading
    
    init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }
    
    func postWorkoutInfo(hrInfo: [HeartRateSample], workoutType: WorkoutType) async {
        do {
            state = .loading
            let req = HandleWorkoutRequest(
                userAuthToken: authProvider.userAuthToken,
                heartRateInfo: hrInfo,
                workoutType: workoutType
            )
            let response = try await HeartRateAPI.postData(req: req)
            state = .fetched(response)
        } catch {
            state = .error
        }
    }
}

@Observable class PreviewHandleWorkoutProviderDataModel: HandleWorkoutProvider {
    var state: HandleWorkoutFetchableState
    var authProvider: AuthProvider
    
    init(state: HandleWorkoutFetchableState, authProvider: AuthProvider = PreviewAuthProvider.isLoggedIn) {
        self.state = state
        self.authProvider = authProvider
    }
    
    func postWorkoutInfo(hrInfo: [HeartRateSample], workoutType: WorkoutType) async {}
}

extension HandleWorkoutProvider where Self == PreviewHandleWorkoutProviderDataModel {
    static var loading: Self {
        PreviewHandleWorkoutProviderDataModel(state: .loading)
    }
    
    static var fetched: Self {
        let mockFetchedData = HandleWorkoutResponse(userListens: UserListen.mocks)
        return PreviewHandleWorkoutProviderDataModel(state: .fetched(mockFetchedData))
    }
    
    static var error: Self {
        return PreviewHandleWorkoutProviderDataModel(state: .error)
    }
}
