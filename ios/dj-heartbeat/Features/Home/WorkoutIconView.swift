import SwiftUI

struct WorkoutIconView: View {
    let workoutType: WorkoutType
    
    var body: some View {
        Image(systemName: workoutIconName)
    }
    
    private var workoutIconName: String {
        return switch workoutType {
        case .lifting:
            "figure.strengthtraining.traditional"
        case .running:
            "figure.run"
        case .walking:
            "figure.walk"
        case .cycling:
            "figure.outdoor.cycle"
        case .other:
            "move.3d"
        }
    }
}
