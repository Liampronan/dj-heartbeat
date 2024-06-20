import FirebaseAuth
import SwiftUI

@Observable class FirebaseCurrentUser {

    static var shared = FirebaseCurrentUser()
    private (set) var user: User? = nil

    init() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user {
                self.user = user
            } else {
                self.user = nil
            }
        }
    }

}

enum IntroPermissionGrantState {
    case needsHealthKit
    case needsSpotify
}

struct IntroScreenExplainerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authProvider) private var authProvider
    @Environment(\.spotifyAuthProvider) private var spotifyAuthProvider
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    @Environment(\.userOnboardingProvider) private var userOnboardingProvder
    
    @State var introPermissionGrantState: IntroPermissionGrantState = .needsSpotify

    
    private struct ViewStrings {
        static let title = "Permissions, please"
        static let healthKitPermissionExplainer = "Provide access your workout data so we can sync it with your listens."
        static let spotifyLoginExplainer = "Login so we can sync your listens with your workouts."
        static let ctaText = "Got it"
    }
    
    var body: some View {
        VStack(alignment: .center) {
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
            Text(introPermissionGrantState == .needsHealthKit ? ViewStrings.healthKitPermissionExplainer : ViewStrings.spotifyLoginExplainer)
                .multilineTextAlignment(.center)
                .fontDesign(.rounded)
                .padding()
            Spacer()
            VStack {
                if introPermissionGrantState == .needsHealthKit {
                    Button(action: onTapCTA, label: {
                        VStack {
                            Text(ViewStrings.ctaText)
                                .fontDesign(.rounded)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(AppColor.deepPurple)
                        .clipShape(.capsule)
                        .padding(.horizontal, 36)
                    })
                } else {
                    LoginWithSpotifyView(onTapLogin: spotifyAuthProvider.authorize)
                }
                
            }
            .shadow(radius: 4)
        }
        .onChange(of: authProvider.user) { oldValue, newValue in
            if newValue != nil && oldValue == nil {
                introPermissionGrantState = .needsHealthKit
            }
        }
    }
    
    
    func onTapCTA() {
        Task(priority: .userInitiated) {
            await recentWorkoutsProvider.requestWorkoutsLocalPermissions()
            dismiss()
            await userOnboardingProvder.fetchStateForUser()
        }
    }
}

#Preview("Spotify Login") {
    VStack {}
        .sheet(isPresented: .constant(true)) {
        IntroScreenExplainerSheetView()
            .presentationDetents([.fraction(0.35)])
            .preferredColorScheme(.dark)
    }
}

#Preview("Apple Health Permissions") {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            IntroScreenExplainerSheetView(introPermissionGrantState: .needsHealthKit)
            .presentationDetents([.fraction(0.35)])
            .preferredColorScheme(.dark)
    }
}
