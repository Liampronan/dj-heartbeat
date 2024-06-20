import SwiftUI

struct TrackDiscoverView: View {
    @Environment(\.trackDiscoverProvider) private var trackDiscoverProvider

    var body: some View {
        NavigationStack {
            VStack {
                content
            }
        }
    }
    
    var content: some View {
        VStack {
            switch trackDiscoverProvider.state {
            case .loading:
                ProgressView()
            case .error:
                Text("error!!!")
            case .fetched(let trackDiscoverCategories):
                TrackDiscoverViewInternal(
                    trackDiscoverCategories: trackDiscoverCategories
                )
            }
        }
        .task {
            await trackDiscoverProvider.fetchTrackDiscover()
        }
    }
}


enum TrackDiscoverCategory: Identifiable, Equatable, Hashable {
    case suggestedForYou(TrackDiscoverCategoryResponse)
    case unheardOf(TrackDiscoverCategoryResponse)
    case recent(TrackDiscoverCategoryResponse)
    case leastRecent(TrackDiscoverCategoryResponse)
    case random(TrackDiscoverCategoryResponse)
    
    var title: String {
        switch self {
        case .suggestedForYou(let category),
                .unheardOf(let category),
                .recent(let category),
                .leastRecent(let category),
                .random(let category):
            return category.titleText
        }
    }
    
    var titleDescription: String {
        switch self {
        case .suggestedForYou(let category),
                .unheardOf(let category),
                .recent(let category),
                .leastRecent(let category),
                .random(let category):
            return category.descriptionText
        }
    }
    
    var id: String { self.title }
    
    
    static var mocks: [Self] {
        return [
            .suggestedForYou(.init(tracks: [mockTrack], titleText: "a", descriptionText: "a")),
            .unheardOf(.init(tracks: [mockTrack], titleText: "b", descriptionText: "b")),
            .recent(.init(tracks: [mockTrack], titleText: "c", descriptionText: "c")),
            .leastRecent(.init(tracks: [mockTrack], titleText: "d", descriptionText: "d")),
            .random(.init(tracks: [mockTrack], titleText: "e", descriptionText: "e"))
        ]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var tracks: [Track] {
        switch self {
        case .suggestedForYou(let category),
                .unheardOf(let category),
                .recent(let category),
                .leastRecent(let category),
                .random(let category):
            return category.tracks
        }
    }
    
    static func initCategories(from apiResponse: TrackDiscoverResponse) -> [TrackDiscoverCategory] {
        return [
            .suggestedForYou(apiResponse.suggestedForYou),
            .unheardOf(apiResponse.unheardOf),
            .random(apiResponse.random),
            .recent(apiResponse.recentlyPlayed),
            .leastRecent(apiResponse.leastRecentlyPlayed)
        ]
    }
}

private struct TrackDiscoverViewInternal: View {
    let trackDiscoverCategories: [TrackDiscoverCategory]
    
    @State private var trackDiscoverCategoriesSelectedIndex = 0
        
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    Spacer()
                    ForEach(Array(trackDiscoverCategories.enumerated()), id: \.element) { (index, trackDiscoverCategory) in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                    trackDiscoverCategoriesSelectedIndex = index
                                }
                        }, label: {
                            VStack {
                                Text(trackDiscoverCategory.title.capitalized)
                                        .foregroundColor(index == trackDiscoverCategoriesSelectedIndex ? Color.white : Color.pink)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                        .background(index == trackDiscoverCategoriesSelectedIndex ? Color.pink : Color.white)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.red, lineWidth: 1.5)
                                                .padding(.vertical, 2)
                                        )
                                
                                Text(trackDiscoverCategory.titleDescription)
                            }
                            
                        })
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut(duration: 0.3), value: trackDiscoverCategoriesSelectedIndex)

                    }
                }
            }
            .scrollIndicators(.never)
            
            ScrollView {
                trackItemViews
            }
            .padding()
            .scrollIndicators(.hidden)
        }
    }
    
    private var selectedListensData: [Track] {
        trackDiscoverCategories[trackDiscoverCategoriesSelectedIndex].tracks
    }
    
    private var trackItemViews: some View {
        ForEach(Array(selectedListensData.enumerated()), id: \.element.id) { (index, track) in
            Spacer(minLength: 12)
            HStack {
                TrackItemView(track: track)
                AddToPlaylistButtonView(
                    track: track,
                    style: .small
                )
            }
            Spacer(minLength: 10)
        }
    }
}

#Preview {
    TrackDiscoverViewInternal(
        trackDiscoverCategories: TrackDiscoverCategory.mocks
    )
    .environment(\.playlistProvider, .fetchedManyResults)
    .environment(\.trackDiscoverProvider, .fetchedManyResults)
}
