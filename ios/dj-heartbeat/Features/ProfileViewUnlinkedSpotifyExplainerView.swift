import SwiftUI

struct ProfileViewUnlinkedSpotifyExplainerView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "person.crop.circle.badge.clock.fill")
                Text("Spotify Unlinked")
            }
            .font(.title)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top])
            Spacer()
            
            Text("• Features are limited for your account until Spotify enables us to onboard more users.")
            Text("• We'll notify you when you can connect your Spotify account.")
            Spacer()
            VStack {
                Button(action: onTapCTA, label: {
                    VStack {
                        Text("Got it")
                            .fontDesign(.rounded)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(AppColor.deepPurple)
                    .clipShape(.capsule)
                    .padding(.horizontal, 36)
                })
            }
            .shadow(radius: 4)
        }.padding()
    }
    
    func onTapCTA() {
        dismiss()
    }
}

#Preview {
    VStack {
        
    }.sheet(isPresented: .constant(true)) {
        ProfileViewUnlinkedSpotifyExplainerView()
            .presentationDetents([.fraction(0.35)])
    }
    .preferredColorScheme(.dark)
    
}
