import SwiftUI

private struct RecentWorkoutsListItemView: View {
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

struct RecentWorkoutsListView: View {
    @State private var workoutSheetItem: (WorkoutWithHeartRate)? = nil
    @State private var isShowingHKFetchErrorView = false
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    
    var body: some View {
        NavigationStack  {
            ScrollView(.horizontal) {
                HStack {
                    Spacer(minLength: MVP_DESIGN_SYSTEM_GUTTER / 2)
                    switch recentWorkoutsProvider.state {
                    case .loading:
                        ForEach([1, 2, 3], id: \.self) { loadingItem in
                            RecentWorkoutsListItemView(viewState: .loading)
                                .frame(width: 190)
                        }
                    case .fetched(let workoutsWithHRInfo):
                        ForEach(workoutsWithHRInfo) { workoutWithHRInfo in
                            RecentWorkoutsListItemView(viewState: .loaded(workoutWithHRInfo))
                                .frame(width: 190)
                                .onTapGesture {
                                    workoutSheetItem = workoutWithHRInfo
                                }
                        }
                        
                    case .error:
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    
                                Text("No workouts found")
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
                                Text("Have you logged workouts in Apple")
                                Text("Fitness in the past week?")
                            }.foregroundStyle(.gray1)
                                .fontWeight(.medium)
                                .fontDesign(.rounded)
                            
                                
                            
                            Button(action: {
                                isShowingHKFetchErrorView.toggle()
                            }, label: {
                                Text("Try fixing")
                            })
                        }.padding(.leading)
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
}


struct HealthKitWorkoutFetchErrorView: View {
    
    enum ConnectAttemptState {
        case hasNotTriedToRequestPermissions
        case showErrorRequestingPermissions
        case hasTriedToRequestPermissions
    }
    private struct ViewStrings {
        static let title = "No workouts found"
        static let errorExplainer = "You either have not given this app permissions to access your workout data or don't have any workouts in Apple Health for the week."
        static let ctaText = "Open Apple Health"
        static let ctaSubText = "You can enable permissions in Apple Health:\nYour Profile → Apps & Services → dj heartbeat"
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    @State private var connectAttemptState = ConnectAttemptState.hasNotTriedToRequestPermissions
    
    var body: some View {
        HStack {
            Image(systemName: "figure.run.square.stack.fill")
            Text(ViewStrings.title)
        }
        .font(.title)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.top, .leading])
        
        Spacer()
        VStack {
            Text(ViewStrings.errorExplainer)
                .multilineTextAlignment(.center)
                .padding()
            
            
            if connectAttemptState == .hasNotTriedToRequestPermissions {
                Button(action: {
                    Task {
                        await recentWorkoutsProvider.requestWorkoutsLocalPermissions()
                        await recentWorkoutsProvider.fetchWorkoutData()
                        if recentWorkoutsProvider.state.hasWorkoutData {
                            dismiss()
                        } else {
                            transitionToFallbackState()
                        }
                    }
                }, label: {
                    Text("Request permissions")
                })
            } else if connectAttemptState == .showErrorRequestingPermissions {
                HStack {
                    Image(systemName: "xmark.app")
                        .foregroundStyle(AppColor.lightRed)
                    Text("Unable to request permissions.")
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.blackText)
                }
                
            } else {
                VStack(spacing: 12) {
                    Text(ViewStrings.ctaSubText)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Link(ViewStrings.ctaText,
                         destination: .init(string: "x-apple-health://Sources/")!
                    )
                }
            }
            Spacer()
        }
    }
    
    private func transitionToFallbackState() {
        withAnimation {
            connectAttemptState = .showErrorRequestingPermissions
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                connectAttemptState = .hasTriedToRequestPermissions
            }
        }
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

