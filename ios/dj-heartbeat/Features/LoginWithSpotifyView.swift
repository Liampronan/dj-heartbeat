import SwiftUI

struct LoginWithSpotifyView: View {
    let onTapLogin: () -> Void
    private struct ViewStrings {
        static let loginWithSpotifyText = "Login with Spotify"
    }
    
    var body: some View {
        VStack {
            Button(ViewStrings.loginWithSpotifyText) {
                onTapLogin()
            }
            .font(.title3)
            .fontDesign(.rounded)
            .fontWeight(.medium)
            .padding()
            .padding(.horizontal, 24)
            .background(AppColor.spotifyGreen)
            .foregroundColor(.white)
            .clipShape(.capsule)
        }
    }
}

#Preview {
    LoginWithSpotifyView(onTapLogin: {})
        
}
