import SFSymbolEnum
import SwiftUI
// START:
// 1. add initial test

struct AllYouView: View {
    @Environment(\.playlistProvider) private var playlistProvider
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    @Environment(\.userOnboardingProvider) private var userOnboardingProvider
    private struct ViewStrings {
        static let recentWorkoutsTitle = "Your recent workouts"
        static let loggedoutText = "You're logged out"
        static let loggedoutSubText = "Your workouts and monthly playlist will show here once you've setup your account."
        static let playlistTitleText = "Your slaylist"
        static let editText = "Edit"
    }
    
    var body: some View {
        if userOnboardingProvider.isUserFullyLoggedIn {
            loggedInBody
        } else {
            loggedOutBody
        }
    }
    
    private var loggedInBody: some View {
        VStack {
            VStack(alignment: .leading) {
                titleWithEditButton
                PlaylistContentView()
            }
            
            Spacer()
            
            VStack(spacing: 0) {
                rowHeader(ViewStrings.recentWorkoutsTitle)
                RecentWorkoutsListView()
                    .frame(maxHeight: 150)
            }
            Spacer()
        }
        .task {
            await recentWorkoutsProvider.fetchWorkoutData()
        }
    }
    
    private var loggedOutBody: some View {
        VStack(alignment: .center, spacing: 12) {
            HStack {
                Image(systemName: .personCropCircleBadgeClockFill)
                Text(ViewStrings.loggedoutText)
                
                    .fontDesign(.rounded)
                
                    .foregroundStyle(.blackText)
            }
            .font(.title)
            .fontWeight(.semibold)
            
            
            Text(ViewStrings.loggedoutSubText)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray2)
        }
        .padding()
    }
    
    private var titleWithEditButton: some View {
        Group {
            HStack {
                rowHeader(ViewStrings.playlistTitleText)
                if let playlistUri {
                    Link(destination: playlistUri) {
                        Text(ViewStrings.editText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background {
                                RoundedRectangle(cornerSize: .init(width: 8, height: 8))
                            }
                            .padding(.trailing, MVP_DESIGN_SYSTEM_GUTTER)
                            .offset(y: 8)
                    }
                }
                
            }
            playlistDateSubtitle
        }
        
    }
  
    private func rowHeader(_ text: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(text)
            }
            .font(.system(size: 24))
            .fontDesign(.rounded)
            .fontWeight(.bold)
            .foregroundStyle(.blackText)
            .padding(.top)
            .padding(.leading, MVP_DESIGN_SYSTEM_GUTTER)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var playlistDateSubtitle: some View {
        Text(playlistName)
            .padding(.leading, MVP_DESIGN_SYSTEM_GUTTER)
    }
    
    private var playlistName: String {
        return switch playlistProvider.state {
        case .fetched(let playlistResponse):
            playlistResponse.playlist.monthName
        case .error, .loading:
            ""
        }
    }
    
    private var playlistUri: URL? {
        return switch playlistProvider.state {
        case .fetched(let playlistResponse):
            URL(string: playlistResponse.playlist.thirdPartyInfo.uri)!
        case .error, .loading:
            nil
        }
    }
}

#Preview("Fetched - logged in") {
    AllYouView()
        .environment(\.playlistProvider, .fetchedManyResults)
        .environment(\.recentWorkoutsProvider, .fetched)
        .environment(\.userOnboardingProvider, .fetchedHasGrantedSpotifyAccess)
}

#Preview("Fetched - logged out") {
    AllYouView()
        .environment(\.playlistProvider, .fetchedManyResults)
        .environment(\.recentWorkoutsProvider, .fetched)
        .environment(\.userOnboardingProvider, .fetchedNotEnabledForSpotifyAccess)
}

#Preview("Error") {
    AllYouView()
        .environment(\.playlistProvider, .error)
        .environment(\.recentWorkoutsProvider, .error)
        .environment(\.userOnboardingProvider, .fetchedHasGrantedSpotifyAccess)
}

