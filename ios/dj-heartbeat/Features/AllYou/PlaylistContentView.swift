import SwiftUI

struct PlaylistContentView: View {
    @Environment(\.playlistProvider) private var playlistProvider
    
    var body: some View {
        switch playlistProvider.state {
        case .loading:
            ProgressView()
        case .fetched(let playlist):
            fetchedState(with: playlist.playlist)
        case .error:
            ErrorView()
                .padding(.leading, MVP_DESIGN_SYSTEM_GUTTER)
        }
    }
    
    private let playlistItemRows = [
        GridItem(.flexible(maximum: 100)),
        GridItem(.flexible(maximum: 100)),
        GridItem(.flexible(maximum: 100))
    ]
    
    func fetchedState(with playlist: Playlist_DEPRECATED) -> some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: playlistItemRows, alignment: .center) {
                ForEach(playlist.tracks) { track in
                    TrackItemView(track: track)
                }
            }
            .frame(height: 250)
            .offset(x: MVP_DESIGN_SYSTEM_GUTTER)
        }
        .scrollIndicators(.never)
    }
}

#Preview {
    PlaylistContentView()
        .environment(\.playlistProvider, .fetchedManyResults)
}
