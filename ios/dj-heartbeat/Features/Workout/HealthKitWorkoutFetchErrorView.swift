import SwiftUI

fileprivate let appleHealthPermissionsUrl = URL(string: "x-apple-health://Sources/")!

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
        static let requestPermissionsCta = "Request permissions"
        static let unableToRequestPermissions = "Unable to request permissions."
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
                    Text(ViewStrings.requestPermissionsCta)
                })
            } else if connectAttemptState == .showErrorRequestingPermissions {
                HStack {
                    Image(systemName: "xmark.app")
                        .foregroundStyle(AppColor.lightRed)
                    Text(ViewStrings.unableToRequestPermissions)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.blackText)
                }
                
            } else {
                VStack(spacing: 12) {
                    Text(ViewStrings.ctaSubText)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Link(ViewStrings.ctaText,
                         destination: appleHealthPermissionsUrl
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

#Preview {
    HealthKitWorkoutFetchErrorView()
}
