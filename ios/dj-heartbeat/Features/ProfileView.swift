import FirebaseAuth
import SwiftUI

struct ProfileView: View {
    @Environment(\.authProvider) private var authProvider
    @Environment(\.dismiss) private var dismiss
    @Environment(\.userOnboardingProvider) private var userOnboardingProvider
    @State private var isShowingSendFeedbackForm = false
    @State private var isShowingUnlinkedSpotifyExplainerView = false
    
    struct ViewStrings {
        static let yourAccountTitle = "Your Account"
        static let signout = "Sign out"
        static let sendFeedback = "Send Us Feedback"
        static let accountLinked = "linked"
        static let accountUnlinked = "unlinked"
    }
    
    var body: some View {
        if userOnboardingProvider.isUserFullyLoggedIn {
            VStack {
                Text(ViewStrings.yourAccountTitle)
                    .textCase(.uppercase)
                    .font(.title3)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.blackText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    .padding(.top, 6)
                Spacer()

                spotifyRow
                sendFeedbackRow
                Spacer()
                Button {
                    try? authProvider.signOut()
                    Task { await userOnboardingProvider.fetchStateForUser() }
                    dismiss()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppColor.gray2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing)
                }
                .padding(.bottom)
                
            }
            .padding(.top)
            .background(AppColor.gray0)
            .sheet(isPresented: $isShowingSendFeedbackForm) {
                SendFeedbackView()
            }
            .sheet(isPresented: $isShowingUnlinkedSpotifyExplainerView) {
                ProfileViewUnlinkedSpotifyExplainerView()
            }
                
        } else {
            Button {
                try? authProvider.signOut()
                Task { await userOnboardingProvider.fetchStateForUser() }
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(ViewStrings.signout)
                }
                .tint(.white)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 20.0)
                        .foregroundStyle(.deepOrange)
                }
            }
            .padding(.bottom)
        }
    }
    
    var spotifyRow: some View {
        HStack {
            HStack(spacing: 0) {
                Image(.spotifyIconBlack)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36)

            }
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.clear, lineWidth: 2.0)
            }
            Spacer()
            spotifyAccountStatus
            
        }.padding(.horizontal)
            .background(.white)
    }
    
    var sendFeedbackRow: some View {
        HStack {
            HStack(spacing: 0) {
                Image(systemName: "paperplane.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36)

            }
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.clear, lineWidth: 2.0)
            }
            Spacer()
            HStack {
                Text("•")
                    .font(.system(size: 50))
                    .foregroundStyle(.deepGreen)
                    .padding(.bottom, 6)
                    .opacity(0.0)  // TODO: standardize row layout. this is hack.
                Text(ViewStrings.sendFeedback)
                    .textCase(.uppercase)
                    .font(.callout)
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColor.gray2)
                
            }
            
        }.onTapGesture {
            isShowingSendFeedbackForm.toggle()
        }
        
        .padding(.horizontal)
        .background(.white)
    }
    
    @ViewBuilder
    private var spotifyAccountStatus: some View {
        switch userOnboardingProvider.state {
        case .loading:
            ProgressView()
        case .error:
            ErrorView()
        case .fetched(let userOnboardingState):
            HStack {
                Text("•")
                    .font(.system(size: 50))
                    .foregroundStyle(userOnboardingState.hasGrantedSpotifyAccess ? .deepGreen : .deepOrange)
                    .padding(.bottom, 6)
                Text(userOnboardingState.hasGrantedSpotifyAccess ? ViewStrings.accountLinked : ViewStrings.accountUnlinked)
                    .font(.callout)
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColor.blackText)
                    .onTapGesture {
                        guard !userOnboardingState.hasGrantedSpotifyAccess else { return }
                        isShowingUnlinkedSpotifyExplainerView.toggle()
                    }
                
            }
        }
    }
}

#Preview("Spotify account linked") {
    VStack {
        AppColor.background
    }.sheet(isPresented: .constant(true)) {
        ProfileView(
        ).presentationDetents([.fraction(0.45)])
            .environment(\.authProvider, .isLoggedIn)
            .environment(\.userOnboardingProvider, .fetchedHasGrantedSpotifyAccess)
    }
}

#Preview("Spotify account unlinked") {
    VStack {
        AppColor.background
    }.sheet(isPresented: .constant(true)) {
        ProfileView().presentationDetents([.fraction(0.45)])
            .environment(\.authProvider, .isLoggedIn)
            .environment(\.userOnboardingProvider, .fetchedNotEnabledForSpotifyAccess)
    }
}
