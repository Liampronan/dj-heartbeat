import CoreLocation
import HealthKit
import SwiftUI

enum WorkoutDataPermissionsState {
    /// via healthkit, we can only tell if user has a) given-or-denied permissions or b) done neither. i.e., we can't see if user has approved vs. denied.
    case hasGrantedOrDeniedPermissions
    case hasNotDecidedPermissions
}

protocol OnDeviceWorkoutDataManager {
    func fetchWorkoutData(for types: [WorkoutType]) async -> WorkoutQueryResult
    func requestPermissions() async
    func getUserWorkoutDataPermissionsState() throws -> WorkoutDataPermissionsState
    func startObserving() 
}

enum WorkoutQueryResult {
    case success([WorkoutWithHeartRate])
    /// empty happens when a user:
        ///a) has zero workouts
        /// or
        /// b) have denied healthkitpermission to app
    /// include these two together for now + combine error message for them.
    case empty
}

enum HealthKitPermissionsError: Error {
    case unknownPermissionsState
    case noSelf
}

/// fetches workout data from Healthkit
@Observable class HealthKitWorkoutDataFetcher: OnDeviceWorkoutDataManager {
    // future improvement: abstract out HK from here. wrap with protocol
    private var store = HKHealthStore()
    
    func getUserWorkoutDataPermissionsState() throws -> WorkoutDataPermissionsState {
        return switch store.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!) {
        case .notDetermined:
                .hasNotDecidedPermissions
        case .sharingAuthorized, .sharingDenied:
                .hasGrantedOrDeniedPermissions
        @unknown default:
            throw HealthKitPermissionsError.unknownPermissionsState
        }
    }
    
    func fetchWorkoutData(for types: [WorkoutType]) async -> WorkoutQueryResult {
        let workouts = await fetchWorkouts()
        guard !workouts.isEmpty else { return .empty }

        do {
            let allWorkouts = try await fetchAndHydrateHeartRateSamples(workouts: workouts)
            return .success(
                allWorkouts.filter({ types.contains($0.workout.workoutType)  })
            )
        } catch {
            // should this be an error?
            return .empty
        }
    }
    
    private func fetchAndHydrateHeartRateSamples(workouts: [HKWorkout]) async throws -> [WorkoutWithHeartRate] {
        return try await workouts.concurrentMap { [weak self] workout in
            guard let self else { throw HealthKitPermissionsError.noSelf }
            let heartRateSamples =  await fetchHeartRateStats(startDate: workout.startDate, endDate: workout.endDate)
            return WorkoutWithHeartRate(workout: workout, heartRateInfo: heartRateSamples)
        }
    }
    
    var healthkitReadTypes: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.workoutType()
    ]
    func requestPermissions() async {
//        let speedType = HKQuantityType.quantityType(forIdentifier: .runningSpeed)!
//        let runningDistance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
//        let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate)!
//        let woType = HKObjectType.workoutType()
//        let routeType = HKSeriesType.workoutRoute()
//        let readTypes: Set<HKObjectType> = [speedType, runningDistance, woType, heartRate, routeType]
        do {
            let _ = try await store.requestAuthorization(toShare: [], read: healthkitReadTypes)
        }
        catch {
            // TODO: actually return error...
            print("error with permissions \(error)")
        }
    }
    
    private func fetchRoute(for workout: HKWorkout) async -> [CLLocation] {
        let runningObjectQuery = HKQuery.predicateForObjects(from: workout)
        let samples = await withCheckedContinuation { continuation in
            let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
                
                guard error == nil, let samples = samples as? [HKWorkoutRoute] else {
                    // Handle any errors here.
                    fatalError("The initial query failed.")
                }
                continuation.resume(with: .success(samples))
            }
            // we may not need this
            routeQuery.updateHandler = { (query, samples, deleted, anchor, error) in
                guard error == nil else {
                    // Handle any errors here.
                    fatalError("The update failed.")
                }
                // Process updates or additions here.
                print("update handler ~~")
            }
            store.execute(routeQuery)
        }
        
        let locations = await withCheckedContinuation { continuation in
            let query = HKWorkoutRouteQuery(route: samples.first!) { (query, locationsOrNil, done, errorOrNil) in
                
                // This block may be called multiple times.
                if let error = errorOrNil {
                    // Handle any errors here.
                    return
                }
                
                guard let locations = locationsOrNil else {
                    fatalError("*** Invalid State: This can only fail if there was an error. ***")
                }
                
                // Do something with this batch of location data.
                
                if done {
                    // The query returned all the location data associated with the route.
                    // Do something with the complete data set.
                    continuation.resume(with: .success(locations))
                }
                
                // You can stop the query by calling:
                // store.stop(query)
                
            }
            store.execute(query)
        }
        
        return locations
    }
    
    func fetchHeartRateStats(startDate: Date, endDate: Date) async -> [HeartRateSample] {
        let heartRateSamples = await withCheckedContinuation { continuation in
            let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let predicateForStartEnd = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])

            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            
            let query = HKSampleQuery(sampleType: heartRate, predicate: predicateForStartEnd, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
                query, results, error in
                
                guard let samples = results as? [HKQuantitySample] else {
                    // TODO: better error handling...
                    fatalError("No heart rate samples :<<<<<")
                }
                
                let res = samples.map { hkQuantitySample in
                    HeartRateSample(
                        startDate: hkQuantitySample.startDate,
                        endDate: hkQuantitySample.endDate,
                        value: hkQuantitySample.quantity.doubleValue(for: heartRateUnit)
                    )
                }
                continuation.resume(with: .success(res))
                
            }
            store.execute(query)
        }
        
        return heartRateSamples
        
    }
    
    private func fetchWorkouts() async -> [HKWorkout] {
        let aMonthAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let TEMP_LIMIT = 10
        
        let predicateForDateRange = HKQuery.predicateForSamples(withStart: aMonthAgo, end: .now)
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        let result = await withCheckedContinuation { continuation in
            let query: HKSampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicateForDateRange, limit: TEMP_LIMIT, sortDescriptors: [sortDescriptor]) {(query, results, error) in
                var res = [HKWorkout]()
                for workout in results as? [HKWorkout] ?? [] {
                    res.append(workout)
                }
                continuation.resume(with: .success(res))
            }
            store.execute(query)
        }
        return result
    }
    
    func startObserving() {
        let sampleType =  HKObjectType.workoutType()
        
        //1. Enable background delivery for workouts
        store.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { (success, error) in
            if let unwrappedError = error {
                print("could not enable background delivery: \(unwrappedError)")
            }
            if success {
                print("background delivery enabled")
            }
        }
        
        //2.  open observer query
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { (query, completionHandler, error) in
            self.updateWorkoutsForObserver() {
                completionHandler()
            }
        }
        store.execute(query)
    }
    
    private func updateWorkoutsForObserver(completionHandler: @escaping () -> Void) {
        var anchor: HKQueryAnchor?

        let sampleType =  HKObjectType.workoutType()
        
        // Calculate the date for 7 days ago from now
        let dateSevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let now = Date()
        
        // Create a predicate to fetch workouts within the last 7 days
        let predicate = HKQuery.predicateForSamples(withStart: dateSevenDaysAgo, end: now, options: .strictStartDate)
        
        let anchoredQuery = HKAnchoredObjectQuery(type: sampleType, predicate: predicate, anchor: anchor, limit: 10) { query, newSamples, deletedSamples, newAnchor, error in
            if newSamples == nil && deletedSamples == nil {
                completionHandler()
                return
            }
            self.handleNewWorkouts(new: newSamples!, deleted: deletedSamples!)
            anchor = newAnchor
            completionHandler()
        }
        store.execute(anchoredQuery)
    }
    
    func handleNewWorkouts(new: [HKSample], deleted: [HKDeletedObject]) {
        guard let lastEndDate = new.last?.endDate, lastEndDate.isWithin(nHours: 12) else { return }
        Task {
            let queryResult = await fetchWorkoutData(for: WorkoutType.currentlySupportedTypes)
            if case let .success(workoutResults) = queryResult, let latestWorkoutResult = workoutResults.first, let latestWorkoutHeartRateInfo = latestWorkoutResult.heartRateInfo {
                
                
                let latestWorkoutType = latestWorkoutResult.workout.workoutType
                let handleWorkoutRequest = HandleWorkoutRequest(heartRateInfo: latestWorkoutHeartRateInfo, workoutType: latestWorkoutType)
                try await HeartRateAPI.postData(req: handleWorkoutRequest)
            }
        }
    }
    
}

@Observable class PreviewOnDeviceWorkoutDataManager: OnDeviceWorkoutDataManager {
    var userWorkoutDataPermissionsState: WorkoutDataPermissionsState
    var runWorkoutQueryResult: WorkoutQueryResult
    
    init(userWorkoutDataPermissionsState: WorkoutDataPermissionsState = .hasGrantedOrDeniedPermissions, runWorkoutQueryResult: WorkoutQueryResult) {
        self.userWorkoutDataPermissionsState = userWorkoutDataPermissionsState
        self.runWorkoutQueryResult = runWorkoutQueryResult
    }
    
    func fetchWorkoutData(for types: [WorkoutType]) async -> WorkoutQueryResult {
        switch userWorkoutDataPermissionsState {
        case .hasGrantedOrDeniedPermissions:
            return runWorkoutQueryResult
        case .hasNotDecidedPermissions:
            return .empty
        }
    }
    
    func getUserWorkoutDataPermissionsState() throws -> WorkoutDataPermissionsState { userWorkoutDataPermissionsState }
    
    func requestPermissions() async { }
    func startObserving() { }
}

extension OnDeviceWorkoutDataManager where Self == PreviewOnDeviceWorkoutDataManager {
    static var hasNotDecidedPermissions: Self {
        PreviewOnDeviceWorkoutDataManager(
            userWorkoutDataPermissionsState: .hasNotDecidedPermissions,
            runWorkoutQueryResult: WorkoutQueryResult.empty
        )
    }
    
    static var fetchedHasWorkouts: Self {
        let mockFetchedData = MockWorkoutGenerator.simpleExample
        return PreviewOnDeviceWorkoutDataManager(runWorkoutQueryResult: .success(MockWorkoutGenerator.simpleExample))
    }
    
    static var fetchedNoWorkouts: Self {
        let mockFetchedData = MockWorkoutGenerator.simpleExample
        return PreviewOnDeviceWorkoutDataManager(runWorkoutQueryResult: .success([]))
    }
}
