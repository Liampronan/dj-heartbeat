import SwiftUI

struct HandleWorkoutProviderKey: EnvironmentKey {
    static let defaultValue: HandleWorkoutProvider = HandleWorkoutDataModel()
}

struct AuthProviderKey: EnvironmentKey {
    static let defaultValue: AuthProvider = FirebaseAuthDataModel()
}

struct OnDeviceWorkoutDataManagerKey: EnvironmentKey {
    static let defaultValue: OnDeviceWorkoutDataManager = HealthKitWorkoutDataFetcher()
}

struct PlaylistProviderKey: EnvironmentKey {
    static let defaultValue: PlaylistProvider = PlaylistDataModel()
}

struct RecentWorkoutsProviderKey: EnvironmentKey {
    static let defaultValue: RecentWorkoutsProvider = RecentWorkoutsDataModel(
        recentWorkoutsLocalDataManager: HealthKitWorkoutDataFetcher()
    )
}

struct SendFeedbackProviderKey: EnvironmentKey {
    static let defaultValue: SendFeedbackProvider = SendFeedbackDataModel()
}

struct SocialFeedProviderKey: EnvironmentKey {
    static let defaultValue: SocialFeedProvider = SocialFeedDataModel()
}

struct SpotifyAuthProviderKey: EnvironmentKey {
    static let defaultValue: SpotifyAuthProvider = SpotifyAuthController()
}

struct TrackDiscoverProviderKey: EnvironmentKey {
    static let defaultValue: TrackDiscoverProvider = TrackDiscoverDataModel()
}

struct UserEventsProviderKey: EnvironmentKey {
    static let defaultValue: UserEventsProvider = UserEventsDataModel(
        authProvider: AuthProviderKey.defaultValue
    )
}

struct UserOnboardingProviderKey: EnvironmentKey {
    static let defaultValue: UserOnboardingProvider = UserOnboardingDataModel()
}

struct WeeklyChartProviderKey: EnvironmentKey {
    static let defaultValue: WeeklyChartProvider = WeeklyChartDataModel()
}

extension EnvironmentValues {
        
    var authProvider: AuthProvider {
        get { self[AuthProviderKey.self] }
        set { self[AuthProviderKey.self] = newValue }
    }
    
    var handleWorkoutProvider: HandleWorkoutProvider {
        get { self[HandleWorkoutProviderKey.self] }
        set { self[HandleWorkoutProviderKey.self] = newValue }
    }
    
    var playlistProvider: PlaylistProvider {
        get { self[PlaylistProviderKey.self] }
        set { self[PlaylistProviderKey.self] = newValue }
    }
    
    var recentWorkoutsProvider: RecentWorkoutsProvider {
        get { self[RecentWorkoutsProviderKey.self] }
        set { self[RecentWorkoutsProviderKey.self] = newValue }
    }
    
    var spotifyAuthProvider: SpotifyAuthProvider {
        get { self[SpotifyAuthProviderKey.self] }
        set { self[SpotifyAuthProviderKey.self] = newValue }
    }
    
    var sendFeedbackProvider: SendFeedbackProvider {
        get { self[SendFeedbackProviderKey.self] }
        set { self[SendFeedbackProviderKey.self] = newValue }
    }
    
    var socialFeedProvider: SocialFeedProvider {
        get { self[SocialFeedProviderKey.self] }
        set { self[SocialFeedProviderKey.self] = newValue }
    }
    
    var trackDiscoverProvider: TrackDiscoverProvider {
        get { self[TrackDiscoverProviderKey.self] }
        set { self[TrackDiscoverProviderKey.self] = newValue }
    }
    
    var userEventsProvider: UserEventsProvider {
        get { self[UserEventsProviderKey.self] }
        set { self[UserEventsProviderKey.self] = newValue }
    }
    
    var userOnboardingProvider: UserOnboardingProvider {
        get { self[UserOnboardingProviderKey.self] }
        set { self[UserOnboardingProviderKey.self] = newValue }
    }
    
    var weeklyChartProvider: WeeklyChartProvider {
        get { self[WeeklyChartProviderKey.self] }
        set { self[WeeklyChartProviderKey.self] = newValue }
    }
    
}
