import FirebaseAuth
import FirebaseCore
import SwiftUI

@main
struct dj_heartbeatApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasInitialLaunchedOccurred = false
    @State private var isShowingDevMenu = false
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    @Environment(\.spotifyAuthProvider) private var spotifyAuthProvider
    @Environment(\.socialFeedProvider) private var socialFeedProvider
    @Environment(\.userOnboardingProvider) private var userOnboardingProvider
    @Environment(\.userEventsProvider) private var userEventsProvider
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            AppleMusicView()
            // force light scheme for app for now; it's a workout app so the bright light helps make you up :>
            .preferredColorScheme(.light)
        }
        
    }
    
    // TODO: cleanup as we are migrating away from this.
    var body_old: some Scene {
        WindowGroup {
            Group {
                ZStack {
                    VStack {
                        switch userOnboardingProvider.state {
                        case .fetched(let fetchedState):
                            switch fetchedState {
                            case .hasNotGrantedSpotifyAccess:
                                IntroScreen()
                            case .hasGrantedSpotifyAccess, .notEnabledForSpotifyAccess:
                                AppleMusicView()
                            }
                        case .loading:
                            EmptyView()
                        case .error:
                            ErrorView()
                        }
                    }
                }
                // force light scheme for app for now; it's a workout app so the bright light helps make you up :>
                .preferredColorScheme(.light)
            }
            .onChange(of: scenePhase) { (oldPhase, newPhase) in
                guard newPhase == .active else { return }
                
                guard hasInitialLaunchedOccurred else {
                    hasInitialLaunchedOccurred = true
                    return
                }
                
                Task {
                    await recentWorkoutsProvider.fetchWorkoutData()
                    await socialFeedProvider.fetchSocialFeed()
                }
            }
            .onShake {
                #if DEBUG
                isShowingDevMenu.toggle()
                #endif
            }
            .sheet(isPresented: $isShowingDevMenu) {
                DevMenu()
            }
            .onAppear {
                recentWorkoutsProvider.startObservingLocalWorkoutsCompletion()
            }
        }
    }
    
    private func fetchLoggedInUserData() async {
        guard userOnboardingProvider.state == .fetched(.hasGrantedSpotifyAccess) else {
            return
        }
        await userEventsProvider.postAppOpened()
        await socialFeedProvider.fetchSocialFeed()
    }
    
    var loggedInView: some View {
        AppTabView()
    }
}
