import SwiftUI

struct SocialFeedItemHeartbeatCountView: View {
    let heartbeatCount: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Text("+")
                .padding(.bottom, 3)
                .font(.body)
            Text(heartbeatCount.formattedWithAbbreviations)
                .padding(.trailing, 8)
            Image(systemName: .heartFill)
            
        }
        .font(.title3)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .foregroundStyle(.gray1)
    }
}

#Preview {
    SocialFeedItemHeartbeatCountView(heartbeatCount: 4732)
}
