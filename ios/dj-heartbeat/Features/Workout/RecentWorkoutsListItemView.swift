import SwiftUI

struct RecentWorkoutsListItemView: View {
    enum ViewState {
        case loading
        case loaded(WorkoutWithHeartRate)
        
        var displayText: String {
            return switch self {
            case .loaded(let workoutWithHeartRate): workoutWithHeartRate.workout.startDate.relativeDateString
            case .loading: ""
            }
        }
    }
    
    enum CardStyle {
        case unprocessedWorkout
        case procssedWorkout
        
        var asBackgroundColor: Color {
            switch self {
            case .unprocessedWorkout: AppColor.deepBlue
            default: .white
            }
        }
        
        var asTextColor: Color {
            switch self {
            case .unprocessedWorkout: Color.white
            default: AppColor.gray1
            }
        }
    }
    
    private var style: CardStyle {
        if viewState.displayText == "Today" {
            return .unprocessedWorkout
        }
        return .procssedWorkout
    }
    
    let viewState: ViewState
    
    var body: some View {
        
        VStack(spacing: 12) {
            if case let .loaded(workoutWithHeartRate) = viewState {
                Text(viewState.displayText)
                    .font(.callout)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                
                WorkoutIconView(workoutType: workoutWithHeartRate.workout.workoutType)
                    .font(.title2)
            }
            
            if case .loading = viewState {
                ProgressView()
            }
            
        }
        .frame(minWidth: 140, minHeight: 60)
        .foregroundStyle(style.asTextColor)
        .padding(.vertical)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(style.asBackgroundColor)
                .shadow(color: .black.opacity(0.2), radius: 4)
                .padding(.vertical, 2)
        }
    }
}

#Preview("Loading") {
    RecentWorkoutsListItemView(viewState: .loading)
}

#Preview("Loaded") {
    RecentWorkoutsListItemView(
        viewState: .loaded(MockWorkoutGenerator.simpleExample.first!)
    )
}
