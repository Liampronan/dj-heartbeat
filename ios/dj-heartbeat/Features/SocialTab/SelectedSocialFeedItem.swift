import SwiftUI

struct SelectedSocialFeedItemSheetView: View {
    let selectedSocialFeedItem: SocialFeedItem
    
    var body: some View {
        VStack {
            header
                .padding()
            Spacer()
            UserListensHorizontalScrollView(userListens: selectedSocialFeedItem.userListens)
            Spacer()
            
        }
    }
    
    var header: some View {
        HStack {
            SocialFeedItemUsernameView(
                username: selectedSocialFeedItem.username,
                style: .headerTitle
            )
            Spacer()
            SocialFeedItemHeartbeatCountView(
                heartbeatCount: selectedSocialFeedItem.heartbeatCount
            )
        }
    }
}

private struct UserListensHorizontalScrollView: View {
    var userListens: [UserListen]

    @State private var currentPage: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let itemWidth = geometry.size.width * 0.5 // Each item takes 50% of the width
            let spacing = geometry.size.width * 0.025 // 5% spacing

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(userListens.indices, id: \.self) { index in
                        VStack {
                            SocialFeedUserListenTrackView(userListen: userListens[index])
                                .padding()
                        }
                        .frame(width: itemWidth)
                        .onTapGesture {
                            currentPage = index
                        }
                    }
                }
                .padding(.leading, spacing)
            }
        }
    }
}


private struct SocialFeedUserListenTrackView: View {
    let userListen: UserListen
    private let imageHeightWidth = UIScreen.main.bounds.height / 8
    @Environment (\.userOnboardingProvider) private var userOnboardingProvider
    
    var body: some View {
        VStack(spacing: 16) {
            AsyncImageView(url: userListen.albumImageURL, heightWidth: imageHeightWidth)
            VStack {
                Text(userListen.track.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                Text(userListen.track.artist)
                    .font(.title3)
                // only show playlist action if user has spotify connected
                if userOnboardingProvider.isUserFullyLoggedIn {
                    AddToPlaylistButtonView(
                        track: userListen.track,
                        style: .expanded
                    )
                }
            }
        }
    }
}

#Preview {
    
    VStack { }
        .sheet(isPresented: .constant(true)) {
            SelectedSocialFeedItemSheetView(
                selectedSocialFeedItem: SocialFeedItem.mock()
            )
            .presentationDetents([.fraction(0.45)])
        }
}
