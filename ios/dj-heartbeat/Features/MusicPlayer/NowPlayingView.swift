import SwiftUI

struct MusicPlayerHistoryView: View {
    @Environment(\.musicPlayerProvider) private var musicPlayerProvider
    
    var body: some View {
        ScrollView {
            VStack {
                // fixme: this is should be unique
                ForEach(musicPlayerProvider.playedItems, id: \.title) { item in
                    VStack {
                        Text(item.title)
                        HStack {
                            Text(item.startedAt?.description ?? "No startedAt")
                            Text(item.endedAt?.description ?? "No endedAt")
                        }
                    }
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
                ForEach(musicPlayerProvider.playedItems, id: \.title) { item in
                    Text(item.title)
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
