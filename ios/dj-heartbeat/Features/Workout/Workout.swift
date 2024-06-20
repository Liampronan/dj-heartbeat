import Foundation
import HealthKit

/// wraps data provider (Healthkit) results
protocol Workout: Equatable, Identifiable {
    var startDate: Date { get }
    var endDate: Date { get }
    var totalDistanceKM: Double { get }
    var totalDistanceM: Double { get }
    var totalTimeSeconds: Double { get }
    var elevationAscendedFeet: Double? { get }
    var workoutType: WorkoutType { get }
    var id: String { get }
}

extension Workout {
    public var id: String { return startDate.formatted() + endDate.formatted() }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
           lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }
}

struct WorkoutWithHeartRate: Identifiable {
    var id: String {
        let firstStartDate = heartRateInfo?.first?.startDate.formatted() ?? ""
        let lastStartDate = heartRateInfo?.last?.startDate.formatted() ?? ""
        return workout.id + firstStartDate + lastStartDate
    }
    
    var workout: any Workout
    var heartRateInfo: [HeartRateSample]?
}

struct MockWorkout: Workout {
    var startDate: Date
    var endDate: Date
    var totalDistanceKM: Double
    var totalDistanceM: Double
    var totalTimeSeconds: Double
    var elevationAscendedFeet: Double?
    var workoutType: WorkoutType
    var heartRateInfo: [HeartRateSample]?
}

enum WorkoutType: String, Codable {
    case lifting
    case running
    case walking
    case cycling
    case other
    
    static var currentlySupportedTypes: [Self] { [.lifting, .running, .walking, .cycling] }
}

struct HeartRateSample: Codable {
    let startDate: Date
    let endDate: Date
    let value: Double
    
    static func generateMocks() -> [HeartRateSample] { return [] } // TODO: implement some test data
}

extension HKWorkout: Workout {
    var totalDistanceKM: Double {
        self.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0.0
    }

    var totalDistanceM: Double {
        self.totalDistance?.doubleValue(for: .mile()) ?? 0.0
    }

    var totalTimeSeconds: Double {
        self.endDate.timeIntervalSince(self.startDate)
    }

    var elevationAscendedFeet: Double? {
        guard let metadata else { return nil }
        guard let workoutElevation = metadata["HKElevationAscended"] as? HKQuantity else {
            return nil
        }
        return workoutElevation.doubleValue(for: HKUnit.foot())
    }

    var workoutType: WorkoutType {
        switch self.workoutActivityType {
        case .traditionalStrengthTraining: return .lifting
        case .running: return .running
        case .walking: return .walking
        case .cycling: return .cycling
        default: return .other
        }
    }
}

struct MockWorkoutGenerator  {
    static let simpleExample: [WorkoutWithHeartRate] = {
       generateExample()
    }()
    
    static func generateExample(startingAt startDate: Date = .now, numberOfWorkouts: Int = 3) -> [WorkoutWithHeartRate] {
        let baseKMGenerateRange = (1...10)
        return (0..<numberOfWorkouts).map { index in
            let mockResultKM = Double(baseKMGenerateRange.randomElement()!)
            let daysAgo = index * -1
            let mockEndDate = Calendar.current.date(byAdding: .day, value: daysAgo, to: startDate)!
            let mockStartDate = mockEndDate.addingTimeInterval(-600)
            
            let mockWorkout = MockWorkout(
                startDate: mockStartDate,
                endDate: mockEndDate,
                totalDistanceKM: mockResultKM,
                totalDistanceM: translateKMtoM(mockResultKM),
                totalTimeSeconds: 60000, // TODO: make me more dynamic so that diff mock workouts have diff time.
                workoutType: .running // TODO: make me more dynamic
            )
            
            return WorkoutWithHeartRate(
                workout: mockWorkout,
                heartRateInfo: HeartRateSample.generateMocks()
            )
        }
    }
    
    static func translateKMtoM(_ km: Double) -> Double {
        return km * (3.1/5.0)
    }
}
