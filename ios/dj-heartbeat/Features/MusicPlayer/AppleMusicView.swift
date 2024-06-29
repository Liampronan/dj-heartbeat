import Observation
import MusicKit
import SwiftUI

// START:
// - create simple hard-coded playlist -- queue items: not just .songs(), can be
// - track listendAt timestamp in queue

struct AppleMusicView: View {
    @Environment(\.musicAuthProvider) private var musicAuthProvider
    @Environment(\.musicPlayerProvider) private var musicPlayerProvider
    
    var body: some View {
        VStack {
            switch musicAuthProvider.authState {
            case .authorized:
                VStack {
                    ScrollView {
                        VStack {
                            ForEach(musicPlayerProvider.playedItems, id: \.self) { item in
                                Text(item)
                            }
                        }
                    }
                    MusicPlayerView()
                }
            case .notDetermined:
                Button("Authorize Apple Music") {
                    handleRequestAuthorizeAppleMusicTap()
                }
                .padding()
            case .deniedOrRestricted:
                ErrorView() // TODO: route to settings>permissions
            case .unknown:
                ErrorView()
            }
        }
    }
    
    private func handleRequestAuthorizeAppleMusicTap() {
        Task { await musicAuthProvider.requestMusicAuthorization() }
    }
}


#Preview("Auth Not Determined") {
    AppleMusicView()
        .environment(\.musicAuthProvider, .notDetermined)
        .environment(\.musicPlayerProvider, .playing)
}

#Preview("Authrozied") {
    AppleMusicView()
        .environment(\.musicAuthProvider, .authorized)
        .environment(\.musicPlayerProvider, .playing)
}
