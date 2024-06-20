import Foundation

typealias RecentWorkoutsFechableDataState = FetchableDataState<[WorkoutWithHeartRate]>

protocol RecentWorkoutsProvider {
    var state: RecentWorkoutsFechableDataState { get }
    var recentWorkoutsLocalDataManager: OnDeviceWorkoutDataManager { get }
    
    func fetchWorkoutData() async
    func requestWorkoutsLocalPermissions() async
    func getUserWorkoutDataPermissionsState() throws -> WorkoutDataPermissionsState
    func startObservingLocalWorkoutsCompletion()
}

extension FetchableDataState where T == [WorkoutWithHeartRate] {
    var hasWorkoutData: Bool {
        switch self {
        case .fetched(let workoutData):
            return !workoutData.isEmpty
        default:
            return false
        }
    }
}

extension RecentWorkoutsProvider {
   
    func requestWorkoutsLocalPermissions() async {
        await recentWorkoutsLocalDataManager.requestPermissions()
    }
    
    func getUserWorkoutDataPermissionsState() throws -> WorkoutDataPermissionsState {
        try recentWorkoutsLocalDataManager.getUserWorkoutDataPermissionsState()
    }
    
    func startObservingLocalWorkoutsCompletion() {
        recentWorkoutsLocalDataManager.startObserving()
    }
}

@Observable class RecentWorkoutsDataModel: RecentWorkoutsProvider {
    
    var state: RecentWorkoutsFechableDataState = .loading
    var recentWorkoutsLocalDataManager: OnDeviceWorkoutDataManager
    
    init(recentWorkoutsLocalDataManager: OnDeviceWorkoutDataManager) {
        self.recentWorkoutsLocalDataManager = recentWorkoutsLocalDataManager
    }
    
    func startObservingLocalWorkoutsCompletion() {
        recentWorkoutsLocalDataManager.startObserving()
    }
    
    func fetchWorkoutData() async {
        state = .loading
        let result = await recentWorkoutsLocalDataManager.fetchWorkoutData(for: WorkoutType.currentlySupportedTypes)
        switch result {
        case .success(let workouts):
            state = .fetched(workouts)
        case .empty:
            state = .error
        }
    }
}

@Observable class PreviewRecentWorkoutsProvider: RecentWorkoutsProvider {
    var recentWorkoutsLocalDataManager: any OnDeviceWorkoutDataManager
    
    var state = RecentWorkoutsFechableDataState.loading
    
    init(
        state: RecentWorkoutsFechableDataState,
        recentWorkoutsLocalDataManager: PreviewOnDeviceWorkoutDataManager = MockPreviewOnDeviceWorkoutDM
    ) {
        self.state = state
        self.recentWorkoutsLocalDataManager = recentWorkoutsLocalDataManager
    }
    
    func fetchWorkoutData() async { }
    
    // we may end up need to init this and pass in mocks if we want to fully mock out things as they are in prod.
    private static var MockPreviewOnDeviceWorkoutDM: PreviewOnDeviceWorkoutDataManager {
        PreviewOnDeviceWorkoutDataManager(
            runWorkoutQueryResult: .empty
        )
    }
}

extension RecentWorkoutsProvider where Self == PreviewRecentWorkoutsProvider {
    static var loading: Self {
        PreviewRecentWorkoutsProvider(state: .loading)
    }
    
    static var fetched: Self {
        let mockFetchedData = MockWorkoutGenerator.simpleExample
        return PreviewRecentWorkoutsProvider(state: .fetched(mockFetchedData))
    }
    
    static var error: Self {
        return PreviewRecentWorkoutsProvider(state: .error)
    }
}
