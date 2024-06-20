import SwiftUI

struct SendFeedbackView: View {
    enum FocusField: Hashable {
        case feedbackField
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var contactInfo: String = ""
    @Environment(\.sendFeedbackProvider) private var sendFeedbackProvider
    @FocusState private var focusField: FocusField?
    
    var body: some View {
        NavigationStack {
            
            VStack {
                Spacer(minLength: 20)
                Form {
                    Section {
                        TextEditor(text: $message)
                            .focused($focusField, equals: .feedbackField)
                    } header: {
                        Text("Your feedback")
                    } footer: {
                        Text("Bugs, feature requests, ideas. You name it.")
                    }

                    Section {
                        TextEditor(text: $contactInfo)
                    } header: {
                        Text("Your email")
                    } footer: {
                        Text("Optional. So we can respond.")
                    }
                    Button(action: {
                        sendFeedback()
                    }, label: {
                        switch sendFeedbackProvider.sendFeedbackSubmissionState {
                        case .submitted:
                            Image(systemName: "checkmark.circle.fill")
                        case .submitting:
                            ProgressView()
                        case .unsubmitted:
                            Text("Send Feedback")
                        }
                    })
                }
                .onChange(of: sendFeedbackProvider.sendFeedbackSubmissionState) { oldValue, newValue in
                    print("newValue is", newValue)
                    guard newValue == .submitted else { return }
                    showSuccessStateAndDismiss()
                }
                .onAppear {
                    focusField = .feedbackField
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack {
                        Spacer(minLength: 30)
                        Text("Get in touch")
                            .font(.largeTitle)
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                            .padding()
                    }
                    .backgroundStyle(.red)
                }
            }
        }
    }
    
    private func sendFeedback() {
        Task {
            try await sendFeedbackProvider.sendFeedback(
                feedback: message,
                contact: contactInfo
            )
        }
    }
    
    private func showSuccessStateAndDismiss() {
        // in previews, its tricky to mock a DismissAction. 
        // so return early (so we can still rely on @Environment(\.dismiss))
        #if targetEnvironment(simulator)
            return
        #endif

        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms to allow for UI feedback
            dismiss()
        }
    }
}

#Preview("Feedback – unsubmitted") {
    SendFeedbackView()
        .environment(\.sendFeedbackProvider, .unsubmitted)
}

#Preview("Feedback submitting") {
    SendFeedbackView()
        .environment(\.sendFeedbackProvider, .submitting)
}

#Preview("Feedback – submitted") {
    SendFeedbackView()
        .environment(\.sendFeedbackProvider, .submitted)
}
