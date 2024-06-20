import SwiftUI

struct LoginWithSpotifyView: View {
    let onTapLogin: () -> Void
    
    var body: some View {
        VStack {
            Button("Login with Spotify") {
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
