import SFSymbolEnum
import SwiftUI

struct WorkoutIconView: View {
    let workoutType: WorkoutType
    
    var body: some View {
        Image(systemName: workoutIconName)
    }
    
    private var workoutIconName: SFSymbol {
        return switch workoutType {
        case .lifting:
                .figureStrengthtrainingFunctional
        case .running:
                .figureRun
        case .walking:
                .figureWalk
        case .cycling:
                .figureOutdoorCycle
        case .other:
                .move3d
        }
    }
}
