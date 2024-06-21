import SwiftUI

struct AppTabView: View {
    @Environment(\.recentWorkoutsProvider) private var recentWorkoutsProvider
    
    private struct ViewStrings {
        static let heartCharts = "Heart charts"
        static let allYou = "All You"
        static let social = "Social"
    }
    var body: some View {
        VStack {
            TabView {
                NavContainer {
                    HomeView()
                }
                .tabItem {
                    Label(ViewStrings.heartCharts, systemImage: "heart")
                }
                
                NavContainer {
                    AllYouView()
                }.tabItem {
                    Label(ViewStrings.allYou, systemImage: "sparkles")
                }
                
                NavContainer {
                    SocialFeedView()
                }.tabItem {
                    Label(ViewStrings.social, systemImage: "music.note.house")
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
