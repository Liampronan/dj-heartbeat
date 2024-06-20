import SwiftUI

struct TrackItemView: View {
    let track: TrackInfo
    
    private struct ViewMetrics {
        static let albumArtWidth = 60.0
    }
    
    var body: some View {
        HStack {
            albumArt
            Spacer(minLength: 12)
            titleAndArtist.padding(.leading, 4)
            Spacer()
        }
    }
    
    var albumArt: some View {
        AsyncImageView(url: track.albumImageURL, heightWidth: ViewMetrics.albumArtWidth)
    }
    
    var titleAndArtist: some View {
        VStack {
            Text(track.name)
                .font(.subheadline)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .lineLimit(1)
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.blackText)
            Text(track.artist)
                .font(.subheadline)
                .fontDesign(.rounded)
                .fontWeight(.regular)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.blackText)
        }
    }
}
