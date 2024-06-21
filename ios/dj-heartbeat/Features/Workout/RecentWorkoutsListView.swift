import SwiftUI

struct RecentWorkoutsListView: View {
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    @State private var isShowingHKFetchErrorView = false
    @State private var workoutSheetItem: (WorkoutWithHeartRate)? = nil
    
    private struct ViewStrings {
        static let noWorkoutsTitle = "No workouts found"
        static let emptyStateDesc1 = "Have you logged workouts in Apple"
        static let emptyStateDesc2 = "Fitness in the past week?"
        static let attemptToFixPermissionsCta = "Try fixing"
    }
    
    var body: some View {
        NavigationStack  {
            ScrollView(.horizontal) {
                HStack {
                    Spacer(minLength: MVP_DESIGN_SYSTEM_GUTTER / 2)
                    switch recentWorkoutsProvider.state {
                    case .loading:
                        loadingView
                    case .fetched(let workoutsWithHRInfo):
                        fetchedView(with: workoutsWithHRInfo)
                    case .error:
                        errorView
                    }
                }
                .padding(.vertical, 4)
                .sheet(item: $workoutSheetItem, content: { workout in
                    RecentWorkoutDetailView(
                        workout: workout
                    )
                })
                .sheet(isPresented: $isShowingHKFetchErrorView, content: {
                    HealthKitWorkoutFetchErrorView()
                        .presentationDetents([.fraction(1/3)])
                })
            }.scrollIndicators(.never)
        }
    }
    
    var loadingView: some View {
        ForEach([1, 2, 3], id: \.self) { loadingItem in
            RecentWorkoutsListItemView(viewState: .loading)
                .frame(width: 190)
        }
    }
    
    func fetchedView(with workoutsWithHRInfo: [WorkoutWithHeartRate]) -> some View {
        ForEach(workoutsWithHRInfo) { workoutWithHRInfo in
            RecentWorkoutsListItemView(viewState: .loaded(workoutWithHRInfo))
                .frame(width: 190)
                .onTapGesture {
                    workoutSheetItem = workoutWithHRInfo
                }
        }
    }
    
    var errorView: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: .exclamationmarkCircleFill)
                    
                Text(ViewStrings.noWorkoutsTitle)
                    .textCase(.uppercase)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColor.deepOrange)
                    
            }

            VStack(alignment: .leading) {
                Text(ViewStrings.emptyStateDesc1)
                Text(ViewStrings.emptyStateDesc2)
            }.foregroundStyle(.gray1)
                .fontWeight(.medium)
                .fontDesign(.rounded)
            
            Button(action: {
                isShowingHKFetchErrorView.toggle()
            }, label: {
                Text(ViewStrings.attemptToFixPermissionsCta)
            })
        }.padding(.leading)
    }
}

#Preview("Has workouts") {
    VStack {
        RecentWorkoutsListView()
            .environment(\.recentWorkoutsProvider, .fetched)
    }.frame(height: 170)
}

#Preview("Loading") {
    VStack {
        RecentWorkoutsListView()
            .environment(\.recentWorkoutsProvider, .loading)
    }.frame(height: 170)
}

#Preview("No workouts") {
    VStack {
        RecentWorkoutsListView()
            .environment(\.recentWorkoutsProvider, .error)
    }.frame(height: 170)
}

