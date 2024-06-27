import SwiftUI

// Here, we register default env values for dependency injection.
// this is based off of Preview-based-architecture: https://blog.thomasdurand.fr/story/2024-03-15-preview-based-architecture/

struct HandleWorkoutProviderKey: EnvironmentKey {
    static let defaultValue: HandleWorkoutProvider = HandleWorkoutDataModel(
        authProvider: AuthProviderKey.defaultValue
    )
}

struct AuthProviderKey: EnvironmentKey {
    static let defaultValue: AuthProvider = FirebaseAuthDataModel()
}

struct MusicPlayerProviderKey: EnvironmentKey {
    static let defaultValue: MusicPlayerProvider = AppleMusicPlayer()
}

struct OnDeviceWorkoutDataManagerKey: EnvironmentKey {
    static let defaultValue: OnDeviceWorkoutDataManager = HealthKitWorkoutDataFetcher(
        handleWorkoutProvider: HandleWorkoutProviderKey.defaultValue
    )
}

struct PlaylistProviderKey: EnvironmentKey {
    static let defaultValue: PlaylistProvider = PlaylistDataModel(
        authProvider: AuthProviderKey.defaultValue
    )
}

struct RecentWorkoutsProviderKey: EnvironmentKey {
    static let defaultValue: RecentWorkoutsProvider = RecentWorkoutsDataModel(
        recentWorkoutsLocalDataManager: OnDeviceWorkoutDataManagerKey.defaultValue
    )
}

struct SendFeedbackProviderKey: EnvironmentKey {
    static let defaultValue: SendFeedbackProvider = SendFeedbackDataModel(
        authProvider: AuthProviderKey.defaultValue
    )
}

struct SocialFeedProviderKey: EnvironmentKey {
    static let defaultValue: SocialFeedProvider = SocialFeedDataModel()
}

struct SpotifyAuthProviderKey: EnvironmentKey {
    static let defaultValue: SpotifyAuthProvider = SpotifyAuthController()
}

struct TrackDiscoverProviderKey: EnvironmentKey {
    static let defaultValue: TrackDiscoverProvider = TrackDiscoverDataModel(
        authProvider: AuthProviderKey.defaultValue
    )
}

struct UserEventsProviderKey: EnvironmentKey {
    static let defaultValue: UserEventsProvider = UserEventsDataModel(
        authProvider: AuthProviderKey.defaultValue
    )
}

struct UserOnboardingProviderKey: EnvironmentKey {
    static let defaultValue: UserOnboardingProvider = UserOnboardingDataModel(
        authProvider: AuthProviderKey.defaultValue
    )
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
    
    var musicPlayerProvider: MusicPlayerProvider {
        get { self[MusicPlayerProviderKey.self] }
        set { self[MusicPlayerProviderKey.self] = newValue }
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
