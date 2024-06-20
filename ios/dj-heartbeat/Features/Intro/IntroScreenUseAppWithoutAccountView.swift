import SwiftUI

struct IntroScreenUseAppWithoutAccountView: View {
    @Environment (\.userOnboardingProvider) private var userOnboardingProvider
    static let modalDisplayHeight = 280.0
    private struct ViewStrings {
        static let title = "Logged out experience"
        static let explainerText = "• We're waiting for Spotify to enable us to onboard more Spotfiy accounts.\n\n• Some functionality will be limited, and you'll be able to create an account later."
        static let ctaText = "Got it"
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle.badge.clock.fill")
                Text(ViewStrings.title)
            }
            .font(.title)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .leading])
            Spacer()
            Text(ViewStrings.explainerText)
                .multilineTextAlignment(.leading)
                .fontDesign(.rounded)
                .padding([.horizontal, .bottom])
            
            Spacer()
            VStack {
                Button(action: onTapCTA, label: {
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
            }
            .shadow(radius: 4)
        }
    }
    
    private func onTapCTA() {
        Task {
            await userOnboardingProvider.setStateToNotEnabledForSpotifyAccess()
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
        IntroScreenUseAppWithoutAccountView()
                .presentationDetents([.height(IntroScreenUseAppWithoutAccountView.modalDisplayHeight)])
            .preferredColorScheme(.dark)
    }
}
