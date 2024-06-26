import SwiftUI

struct RecentWorkoutDetailView: View {
    @Environment(\.authProvider) private var authProvider
    @Environment(\.handleWorkoutProvider) private var handleWorkoutProvider
    @Environment(\.weeklyChartProvider) private var weeklyChartDataProvider
    let workout: WorkoutWithHeartRate
    
    var body: some View {
        VStack {
            switch handleWorkoutProvider.state {
            case .loading:
                ProgressView()
            case .error:
                ErrorView()
            case .fetched(let handleWorkoutResponse):
                PostWorkoutView(handleWorkoutResponse: handleWorkoutResponse)
            }
        }
        .task {
            postHRInfo()
        }
    }
   
    private func postHRInfo() {
        guard let heartRateInfo = workout.heartRateInfo else { return }
        Task {
            await handleWorkoutProvider.postWorkoutInfo(hrInfo: heartRateInfo, workoutType: workout.workout.workoutType)
            // re-fetch chart data to account for updated rankings
            await weeklyChartDataProvider.fetchThisWeeksChartData()
        }
    }
}

#Preview {
    RecentWorkoutDetailView(workout: MockWorkoutGenerator.simpleExample.first!)
        .environment(\.weeklyChartProvider, .fetched)
        .environment(\.handleWorkoutProvider, .fetched)
}

