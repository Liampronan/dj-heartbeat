import SwiftUI


struct MusicPlayerHistoryView: View {
    var body: some View {
        VStack {
            Text("history item a")
            Text("history item b")
        }
    }
}

struct MusicPlayerUpNextView: View {
    var body: some View {
        VStack {
            Text("upnext item a")
            Text("upnext item b")
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
