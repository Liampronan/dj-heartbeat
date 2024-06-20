import Foundation

typealias HandleWorkoutFetchableState = FetchableDataState<HandleWorkoutResponse>

protocol HandleWorkoutProvider {
    var state: HandleWorkoutFetchableState { get }
    func postWorkoutInfo(hrInfo: [HeartRateSample], workoutType: WorkoutType) async
}

@Observable class HandleWorkoutDataModel: HandleWorkoutProvider {
    var state: HandleWorkoutFetchableState = .loading
    
    func postWorkoutInfo(hrInfo: [HeartRateSample], workoutType: WorkoutType) async {
        do {
            state = .loading
            let req = HandleWorkoutRequest(heartRateInfo: hrInfo, workoutType: workoutType)
            let response = try await HeartRateAPI.postData(req: req)
            state = .fetched(response)
        } catch {
            state = .error
        }
    }
}

@Observable class PreviewRecentWorkoutsDataModel: HandleWorkoutProvider {
    var state: HandleWorkoutFetchableState
    
    init(state: HandleWorkoutFetchableState) {
        self.state = state
    }
    
    func postWorkoutInfo(hrInfo: [HeartRateSample], workoutType: WorkoutType) async {}
}

extension HandleWorkoutProvider where Self == PreviewRecentWorkoutsDataModel {
    static var loading: Self {
        PreviewRecentWorkoutsDataModel(state: .loading)
    }
    
    static var fetched: Self {
        let mockFetchedData = HandleWorkoutResponse(userListens: UserListen.mocks)
        return PreviewRecentWorkoutsDataModel(state: .fetched(mockFetchedData))
    }
    
    static var error: Self {
        return PreviewRecentWorkoutsDataModel(state: .error)
    }
}
