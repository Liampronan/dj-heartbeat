import SwiftUI

enum SignupCodeRequestState: Equatable {
    case unsubmitted
    case submitting
    case successfulCode
    case failedCode
    
    var isSubmitting: Bool {
        self == .submitting
    }
    
    var isFailed: Bool {
        self == .failedCode
    }
}

struct SignupCodeModalView: View {
    enum FocusField: Hashable {
        case signupCodeField
    }
    let handleSuccessfulSignupCode: () -> Void
    @State var signupCodeRequestState = SignupCodeRequestState.unsubmitted
    @State private var signupCode = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusField: FocusField?
    
    var body: some View {
            
        VStack(spacing: 10) {
            TextField("Enter signup code", text: $signupCode)
                .multilineTextAlignment(.center)
            
            Button(action: {
                dismiss()
            }) {
                Button {
                    handleSubmit()
                } label: {
                    VStack {
                        VStack {
                            if signupCodeRequestState.isSubmitting  {
                                ProgressView()
                            } else {
                                Text(signupCodeRequestState.isFailed ? "Invalid code" : "Submit")
                                    .fontDesign(.rounded)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding()
                            }
                        }
                        .frame(height: 50)
                    }
                    .frame(maxWidth: .infinity)
                    .background(signupCodeRequestState.isFailed ? AppColor.deepRed : AppColor.deepPurple)
                    .clipShape(.capsule)
                    .frame(width: 200, height: 100)
                }
            }
            .foregroundStyle(.blackText)
            
        }
        .onAppear {
            focusField = .signupCodeField
        }
    }
    
    
    private func handleSubmit() {
        Task {
            signupCodeRequestState = .submitting
            do {
                let result = try await SignupCodeAPI.verifySignupCode(
                    req: .init(signupCode: signupCode)
                )
                if result.isCodeValid {
                    signupCodeRequestState = .successfulCode
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        handleSuccessfulSignupCode()
                    }
                    
                } else {
                    handleError()
                }
                
            } catch {
                handleError()
            }
            
        }
    }
    
    private func handleError() {
        withAnimation {
            signupCodeRequestState = .failedCode
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                signupCodeRequestState = .unsubmitted
            }
        }
    }
}

#Preview("unsubmitted") {
    VStack {
        SignupCodeModalView(
            handleSuccessfulSignupCode: {},
            signupCodeRequestState: .unsubmitted
        
        )
    }
}

#Preview("submitting") {
    VStack {
        SignupCodeModalView(
            handleSuccessfulSignupCode: {},
            signupCodeRequestState: .submitting
        )
    }
}
