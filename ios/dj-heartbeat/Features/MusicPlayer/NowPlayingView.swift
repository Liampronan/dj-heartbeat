import SwiftUI

struct MusicPlayerHistoryView: View {
    @Environment(\.musicPlayerProvider) private var musicPlayerProvider
    
    var body: some View {
        ScrollView {
            VStack {
                // fixme: this is should be unique
                // 
                ForEach(musicPlayerProvider.playedItems, id: \.name) { item in
                    Text(item.name)
                }
            }
        }
    }
}

struct MusicPlayerUpNextView: View {
    
    @Environment(\.musicPlayerProvider) private var musicPlayerProvider
    var body: some View {
        ScrollView {
            VStack {
                // fixme: this is should be unique
                ForEach(musicPlayerProvider.playedItems, id: \.name) { item in
                    Text(item.name)
                }
            }
        }
    }
}

struct NowPlayingView: View {
    var body: some View {
        
        VStack {
            DisclosureGroup("History") {
                MusicPlayerHistoryView()
            }
            MusicPlayerView()
            DisclosureGroup("Up next") {
                MusicPlayerUpNextView()
            }
        }.padding()
    }
}

#Preview {
    NowPlayingView()
        .environment(\.musicPlayerProvider, .playing)
}
