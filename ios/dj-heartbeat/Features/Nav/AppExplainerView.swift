import SwiftUI

struct AppExplainerView: View {
    @Environment(\.dismiss) private var dismiss
    
    private struct ViewStrings {
        static let title = "How dj heartbeat works"
        static let explainerText = "1. Connect your Spotify and Apple Health.\n2. Workout.\n3. We sync your workout heatbeats and workout tracks – the more heatbeats a track has, the higher it charts."
        static let ctaText = "Got it"
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: .questionmarkSquareDashed)
                Text(ViewStrings.title)
            }
            .font(.title2)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .leading])
            
            Spacer()
            
            Text(ViewStrings.explainerText)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .padding()
            Spacer()
            Button(action: dismiss.callAsFunction, label: {
                VStack {
                    Text(ViewStrings.ctaText)
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
            .shadow(radius: 4)
        }
    }
}
