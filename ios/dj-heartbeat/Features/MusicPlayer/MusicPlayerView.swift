import SFSymbolEnum
import SwiftUI

struct MusicPlayerView: View {
    @Environment(\.musicPlayerProvider) private var musicPlayerProvider
    
    private struct ViewMetrics {
        static var playButtonSize = 70.0
        static var prevNextButtonSize = Self.playButtonSize / 2
        static var interButtonVSpacing = 12.0
    }
    
    var body: some View {
        VStack(spacing: ViewMetrics.interButtonVSpacing) {
            
            Text(musicPlayerProvider.currentSongTitle)
                .font(.title2)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
            
            Button(action: handlePlayOrPauseTap, label: { playOrPauseImage })
            
            HStack {
                Button(action: musicPlayerProvider.skipToPrevItem, label: { Image(symbol: .backwardFill) })
                Button(action: musicPlayerProvider.skipToNextItem, label: { Image(symbol: .forwardFill) })
            }
            .font(.system(size: ViewMetrics.prevNextButtonSize))
        }
        .task {
            try? await musicPlayerProvider.queueItemsFromTestPlaylist()
        }
    }
    
    private var playOrPauseImage: some View {
        let symbol: SFSymbol = musicPlayerProvider.playbackStatus == .playing ? .pauseCircleFill : .playCircleFill
        return Image(symbol: symbol).font(.system(size: ViewMetrics.playButtonSize))
    }
    
    private func handlePlayOrPauseTap() {
        if musicPlayerProvider.playbackStatus == .playing {
            musicPlayerProvider.pause()
        } else {
            musicPlayerProvider.play()
        }
    }
}

#Preview {
    MusicPlayerView()
        .environment(\.musicPlayerProvider, .playing)
}

