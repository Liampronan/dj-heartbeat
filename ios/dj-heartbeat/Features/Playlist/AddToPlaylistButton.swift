import SwiftUI

struct AddToPlaylistButtonView: View {
    enum Style {
        case small
        case expanded
    }
   
    let track: Track
    let style: Style
    
    @Environment(\.playlistProvider) private var playlistProvider
    
    private struct ViewStrings {
        static let playlistTitle = "slaylist"
        static let isAddedToPlaylist = "added"
    }
    
    var body: some View {
        Button(action: onTap, label: {
            switch style {
            case .small:
                smallStyleButtonContent
            case .expanded:
                expandedStyleButtonContent
            }
        })
        
        .padding(8)
        .tint(.white)
        .background {
            let playlistTrackState = playlistProvider.playlistTrackState(for: track)
            switch playlistTrackState {
            case .addedToPlaylist, .error:
                AppColor.blackText
            case .notAddedToPlaylist:
                AppColor.deepPurple
            case .loading:
                ProgressView()
            }
            
        }
        .cornerRadius(6)
    }
    
    private func onTap() {
        Task {
            try await playlistProvider.addToDefaultPlaylist(track: track)
        }
    }
    
    @ViewBuilder
    private var smallStyleButtonContent: some View {
        let playlistTrackState = playlistProvider.playlistTrackState(for: track)
        switch playlistTrackState {
        case .addedToPlaylist, .error, .notAddedToPlaylist:
            image(for: playlistTrackState)
        case .loading:
            ProgressView()
        }
    }
    
    @ViewBuilder
    private var expandedStyleButtonContent: some View {
        let playlistTrackState = playlistProvider.playlistTrackState(for: track)
        switch playlistTrackState {
        case .error, .notAddedToPlaylist:
            HStack {
                image(for: playlistTrackState)
                Text(ViewStrings.playlistTitle)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
            }
            
        case .addedToPlaylist:
            HStack {
                Text(ViewStrings.isAddedToPlaylist)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
            }
           
            
        case .loading:
            ProgressView()
        }
    }
    
    private func image(for playlistTrackState: PlaylistTrackState) -> some View {
        if let viewStateSystemImageName = systemImageName(for: playlistTrackState) {
            return Image(systemName: viewStateSystemImageName)
                .font(.title3)
        }
        return Image(systemName: "none").font(.title3)
    }
    
    private func systemImageName(for playlistTrackState: PlaylistTrackState) -> String? {
        return switch playlistTrackState {
        case .addedToPlaylist: "checkmark"
        case .error: "x.circle.fill"
        case .notAddedToPlaylist: "plus.circle.fill"
        case .loading: nil
        }
    }
}

#Preview("small: unadded track") {
    AddToPlaylistButtonView(
        track: mockTrackNotOnDefaultPlaylist,
        style: .small
    )
    .environment(\.playlistProvider, .fetchedManyResults)
}

#Preview("small: added track") {
    AddToPlaylistButtonView(
        track: mockTrack,
        style: .small
    )
    .environment(\.playlistProvider, .fetchedManyResults)
}

#Preview("expanded: unadded track") {
    AddToPlaylistButtonView(
        track: mockTrackNotOnDefaultPlaylist,
        style: .expanded
    )
    .environment(\.playlistProvider, .fetchedManyResults)
}

#Preview("expanded: added track") {
    AddToPlaylistButtonView(
        track: mockTrack,
        style: .expanded
    )
    .environment(\.playlistProvider, .fetchedManyResults)
}
