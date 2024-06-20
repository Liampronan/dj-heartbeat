import SwiftUI

struct SocialFeedItemUsernameView: View {
    enum Style {
        case normal
        case headerTitle
        
        var font: Font {
            return switch self {
            case .normal: .callout
            case .headerTitle: .title3
            }
        }
    }
    let username: String
    let style: Style
    
    var body: some View {
        Text(username)
            .font(style.font)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.blackText)
            }
    }
}

#Preview("style: normal") {
    SocialFeedItemUsernameView(username: "@mileystan", style: .normal)
}

#Preview("style: headerTitle") {
    SocialFeedItemUsernameView(username: "@mileystan", style: .headerTitle)
}
