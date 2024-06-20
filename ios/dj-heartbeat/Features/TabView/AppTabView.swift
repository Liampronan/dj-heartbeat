import SwiftUI

struct AppTabView: View {
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    var body: some View {
        VStack {
            TabView {
                NavContainer {
                    HomeView()
                }
                .tabItem {
                    Label("Heart Charts", systemImage: "heart")
                }
                
                NavContainer {
                    AllYouView()
                }.tabItem {
                    Label("All You", systemImage: "sparkles")
                }
                
                NavContainer {
                    SocialFeedView()
                }.tabItem {
                    Label("Social", systemImage: "music.note.house")
                }                
            }
        }.task {
            await fetchInitialData()
        }
    }
    
    private func fetchInitialData() async {
        await recentWorkoutsProvider.fetchWorkoutData()
    }
}

#Preview {
    AppTabView()
        .environment(\.weeklyChartProvider, .fetched)
        .environment(\.socialFeedProvider, .fetchedManyResults)
        .environment(\.recentWorkoutsProvider, .fetched)
}
