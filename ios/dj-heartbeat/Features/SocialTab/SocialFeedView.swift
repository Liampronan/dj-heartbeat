import SwiftUI

struct SocialFeedView: View {
    @Environment(\.socialFeedProvider) private var socialFeedViewProvider
    @State private var selectedSocialFeedItem: SocialFeedItem?
    
    var body: some View {
        VStack() {
            titleAndSubtitle
            Spacer(minLength: 32)
            
            Group {
                switch socialFeedViewProvider.state {
                case .loading:
                    ProgressView()
                case .error:
                    ErrorView()
                case .fetched(let data):
                    renderFetched(with: data)
                }
            }
            
            Spacer()
        }
        .task {
            await socialFeedViewProvider.fetchSocialFeed()
        }
        .sheet(item: $selectedSocialFeedItem) { selectedSocialFeedItem in
            SelectedSocialFeedItemSheetView(selectedSocialFeedItem: selectedSocialFeedItem)
                .presentationDetents([.fraction(0.45)])
        }
    }
    
    var titleAndSubtitle: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Recent workouts")
            }
            .font(.system(size: 28))
            .fontDesign(.rounded)
            .fontWeight(.bold)
            .foregroundStyle(.blackText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, MVP_DESIGN_SYSTEM_GUTTER)
    }
    
    func renderFetched(with response: FetchSocialFeedResponse) -> some View {
        Group {
            if response.hasTodayData {
                ScrollView {
                    ForEach(
                        response.today.feedItems,
                        content: renderTodayFeedItem
                    )
                    
                }.scrollIndicators(.hidden)
            } else {
                Text("Get moving and\nmotivate others.")
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.gray1)
                    .offset(.init(width: 0, height: -80))
                
            }
        }
    }
    
    func renderTodayFeedItem(_ item: SocialFeedItem) -> some View {
        VStack {
            HStack {
                SocialFeedItemUsernameView(
                    username: item.username,
                    style: .normal
                )
                Spacer()
                SocialFeedItemHeartbeatCountView(heartbeatCount: item.heartbeatCount)
            }
            .padding(.leading, MVP_DESIGN_SYSTEM_GUTTER)
            .padding(.trailing, MVP_DESIGN_SYSTEM_GUTTER / 2) // not ideal
            
            Spacer(minLength: 16)
            
            ScrollView(.horizontal) {
                HStack {
                    Spacer(minLength: MVP_DESIGN_SYSTEM_GUTTER)
                    ZStack {
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 40, height: 40)
                            
                        WorkoutIconView(workoutType: item.workoutType)
                            .foregroundStyle(Color.black)
                            .font(.title3)
                    }
                    .background(Circle().fill(Color.white))
                    .frame(width: 50, height: 50)
                    
                    Spacer(minLength: 16)
                    
                    ForEach(item.userListens) { userListen in
                        AsyncImageView(url: userListen.albumImageURL, heightWidth: 65)
                        Spacer(minLength: 18)
                    }
                }
                Spacer(minLength: 16)
                Divider()
                    .padding(.leading, 65)
                    .frame(height: 5)
                    .frame(minWidth: 400)
            }
            
            Spacer(minLength: 36)
        }
        .onTapGesture {
            selectedSocialFeedItem = item
        }
    }
}

#Preview("Fetched: Many Results") {
    SocialFeedView()
        .environment(\.socialFeedProvider, .fetchedManyResults)
}

#Preview("Fetched: No Results") {
    SocialFeedView()
        .environment(\.socialFeedProvider, .fetchedNoResults)
}

#Preview("Loading") {
    SocialFeedView()
        .environment(\.socialFeedProvider, .loading)
}
