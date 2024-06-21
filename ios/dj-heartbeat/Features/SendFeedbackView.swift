import SwiftUI

struct SendFeedbackView: View {
    private enum FocusField: Hashable {
        case feedbackField
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var contactInfo: String = ""
    @Environment(\.sendFeedbackProvider) private var sendFeedbackProvider
    @FocusState private var focusField: FocusField?
    
    private struct ViewStrings {
        static let header = "Your feedback"
        static let footer = "Bugs, feature requests, ideas. You name it."
        static let contactHeader = "Your email"
        static let contactFooter = "Optional. So we can respond."
        static let cta = "Send Feedback"
        static let toolbarTitle = "Get in touch"
    }
    
    var body: some View {
        NavigationStack {
            
            VStack {
                Spacer(minLength: 20)
                Form {
                    Section {
                        TextEditor(text: $message)
                            .focused($focusField, equals: .feedbackField)
                    } header: {
                        Text(ViewStrings.header)
                    } footer: {
                        Text(ViewStrings.footer)
                    }

                    Section {
                        TextEditor(text: $contactInfo)
                    } header: {
                        Text(ViewStrings.contactHeader)
                    } footer: {
                        Text(ViewStrings.contactFooter)
                    }
                    Button(action: {
                        sendFeedback()
                    }, label: {
                        switch sendFeedbackProvider.sendFeedbackSubmissionState {
                        case .submitted:
                            Image(systemName: .checkmarkCircleFill)
                        case .submitting:
                            ProgressView()
                        case .unsubmitted:
                            Text(ViewStrings.cta)
                        }
                    })
                }
                .onChange(of: sendFeedbackProvider.sendFeedbackSubmissionState) { oldValue, newValue in
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
                        Text(ViewStrings.toolbarTitle)
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
