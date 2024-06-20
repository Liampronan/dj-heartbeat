import Foundation

protocol ProfileInfo {
    var uid: String { get }
    var presentableUserName: String { get }
    var isLoggedIn: Bool { get }
    func signOut() throws -> Void
}

protocol ProfileProvider {
//    var state: HandleWorkoutFetchableState { get }
    var uid: String { get }
    var presentableUserName: String { get }
    var isLoggedIn: Bool { get }
    func signOut() throws -> Void
}



//@Observable class ProfileDataModel: ProfileProvider {
//   
//}

//@Observable class PreviewRecentWorkoutsDataModel: HandleWorkoutProvider {
//    var state: HandleWorkoutFetchableState
//    
//    init(state: HandleWorkoutFetchableState) {
//        self.state = state
//    }
//    
//    func postWorkoutInfo(hrInfo: [HeartRateSample], workoutType: WorkoutType) async {}
//}
//
//extension HandleWorkoutProvider where Self == PreviewRecentWorkoutsDataModel {
//    static var loading: Self {
//        PreviewRecentWorkoutsDataModel(state: .loading)
//    }
//    
//    static var fetched: Self {
//        let mockFetchedData = HandleWorkoutResponse(userListens: UserListen.mocks)
//        return PreviewRecentWorkoutsDataModel(state: .fetched(mockFetchedData))
//    }
//    
//    static var error: Self {
//        return PreviewRecentWorkoutsDataModel(state: .error)
//    }
//}
