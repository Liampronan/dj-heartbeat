import SwiftUI

struct IntroScreen: View {
    @State var isIntroScreenExplainerSheetPresented = false
    @State var isUseAppWithoutAccountViewPresented = false
    @State var isSignupCodeViewPresented = false
    @State var signupCode = ""
    
    
    private struct ViewStrings {
        static let appTitle = "dj heartbeat"
        static let appSubTitle = "a weekly workout playlist.\ncurated by your heartbeats."
        static let useAppWithoutSignupCodeCTA = "Use app without account"
        static let iHaveACodeCTA = "I have a signup code"
    }
    
    var body: some View {
        VStack {
            Spacer()
            titleAndSubTitle
            Spacer()
            VStack(spacing: 12) {
                iHaveACodeCTAButton
                iDontHaveACodeCTAButton
            }
            .padding(.bottom)
        }
        .foregroundStyle(.blackText)
        .background(AppColor.deepPurple.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $isIntroScreenExplainerSheetPresented) {
            IntroScreenExplainerSheetView()
                .presentationDetents([.fraction(0.35)])
        }
        .sheet(isPresented: $isUseAppWithoutAccountViewPresented) {
            IntroScreenUseAppWithoutAccountView()
                .presentationDetents(
                    [.height(IntroScreenUseAppWithoutAccountView.modalDisplayHeight)]
                )
        }
        .sheet(isPresented: $isSignupCodeViewPresented) {
            SignupCodeModalView(
                handleSuccessfulSignupCode: handleSuccessfulSignupCode
            )
        }
    }
    
    var titleAndSubTitle: some View {
        VStack(spacing: 8) {
            Text(ViewStrings.appTitle)
                .font(.largeTitle)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
            Text(ViewStrings.appSubTitle)
                .font(.headline)
                .fontWeight(.regular)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
        }.overlay {
            Text("❤️")
                .font(.caption)
                .background(AppColor.white.frame(width: 10, height: 18))
                .offset(x: -68.75, y: -40)
        }
        .padding()
        .padding(.vertical, 10)
        .padding(.horizontal, 30)
        .background {
            VStack {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(.white)
                    .shadow(radius: 10)
            }
        }
    }
    
    var iHaveACodeCTAButton: some View {
        Button(action: onTapIHaveACodeCTA, label: {
            VStack {
                Text(ViewStrings.iHaveACodeCTA)
                    .fontDesign(.rounded)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.deepPurple)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(AppColor.white)
            .clipShape(.capsule)
            .padding(.horizontal, 50)
        })
        .shadow(color: AppColor.deepPurple.opacity(0.4), radius: 4)
    }
    
    var iDontHaveACodeCTAButton: some View {
        Button(action: onTapIDontHaveAGoodCTA, label: {
            Text(ViewStrings.useAppWithoutSignupCodeCTA)
                .fontDesign(.rounded)
                .font(.subheadline)
                .foregroundStyle(AppColor.white)
        })
        
    }
    
    func onTapIDontHaveAGoodCTA() {
        isUseAppWithoutAccountViewPresented.toggle()
    }
    
    func onTapIHaveACodeCTA() {
        isSignupCodeViewPresented.toggle()
    }
    
    func handleSuccessfulSignupCode() {
        isIntroScreenExplainerSheetPresented.toggle()
    }
}

#Preview("Intro Screen") {
    IntroScreen()
}

