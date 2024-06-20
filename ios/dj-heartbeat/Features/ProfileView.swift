import FirebaseAuth
import SwiftUI

protocol ProfileInfoable {
    var uid: String { get }
    var presentableUserName: String { get }
    var isLoggedIn: Bool { get }
    func signOut() throws -> Void
}

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: ProfileInfoable
    @Environment(\.userOnboardingProvider) private var userOnboardingProvider
    @State private var isShowingSendFeedbackForm = false
    @State private var isShowingUnlinkedSpotifyExplainerView = false
    
    var body: some View {
        if userOnboardingProvider.isUserFullyLoggedIn {
            VStack {
                Text("YOUR ACCOUNT")
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
                    try? profile.signOut()
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
                try? profile.signOut()
                Task { await userOnboardingProvider.fetchStateForUser() }
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign out")
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
                Text("SEND US FEEDBACK".uppercased())
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
            Text("error")
        case .fetched(let userOnboardingState):
            HStack {
                Text("•")
                    .font(.system(size: 50))
                    .foregroundStyle(userOnboardingState.hasGrantedSpotifyAccess ? .deepGreen : .deepOrange)
                    .padding(.bottom, 6)
                Text(userOnboardingState.hasGrantedSpotifyAccess ? "LINKED" : "UNLINKED")
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

struct ProfileMock: ProfileInfoable {
    let uid: String
    var isLoggedIn: Bool
    var presentableUserName: String { uid.replacingOccurrences(of: "spotify:", with: "") }
    
    func signOut() throws {
        print("mock signout")
    }
    
    static func generate() -> ProfileMock {
        return .init(uid: "spotify:mileyfanboi", isLoggedIn: true)
    }
}

#Preview("Spotify account linked") {
    VStack {
        AppColor.background
    }.sheet(isPresented: .constant(true)) {
        ProfileView(
            profile: ProfileMock.generate()
        ).presentationDetents([.fraction(0.45)])
            .environment(\.userOnboardingProvider, .fetchedHasGrantedSpotifyAccess)
    }
}

#Preview("Spotify account unlinked") {
    VStack {
        AppColor.background
    }.sheet(isPresented: .constant(true)) {
        ProfileView(
            profile: ProfileMock.generate()
        ).presentationDetents([.fraction(0.45)])
            .environment(\.userOnboardingProvider, .fetchedNotEnabledForSpotifyAccess)
    }
}
