import Foundation

protocol SendFeedbackProvider {
    var authProvider: AuthProvider { get }
    var sendFeedbackSubmissionState: SendFeedbackSubmissionState { get }
    func sendFeedback(feedback: String, contact: String?) async throws
}

enum SendFeedbackSubmissionState {
    case unsubmitted
    case submitting
    case submitted
}

@Observable class SendFeedbackDataModel: SendFeedbackProvider {
    var authProvider: AuthProvider
    var sendFeedbackSubmissionState = SendFeedbackSubmissionState.unsubmitted
    
    init(authProvider: AuthProvider, sendFeedbackSubmissionState: SendFeedbackSubmissionState = SendFeedbackSubmissionState.unsubmitted) {
        self.authProvider = authProvider
        self.sendFeedbackSubmissionState = sendFeedbackSubmissionState
    }
    
    func sendFeedback(feedback: String, contact: String?) async throws {
        guard sendFeedbackSubmissionState == .unsubmitted else { return }
        sendFeedbackSubmissionState = .submitting
        let sendFeedbackReq = SendFeedbackRequest(
            userAuthToken: authProvider.userAuthToken,
            feedback: feedback,
            contact: contact
        )
        // ideally we could de-dupe this code here and in PreviewSendFeedbackDataModel. but when i move state transition to enum, it doesn't trigger state change for submitting
        try await SendFeedbackAPI.postData(
            req: sendFeedbackReq
        )
        sendFeedbackSubmissionState = .submitted
    }
}

@Observable class PreviewSendFeedbackDataModel: SendFeedbackProvider {
    var sendFeedbackSubmissionState: SendFeedbackSubmissionState
    var authProvider: AuthProvider
    
    init(authProvider: AuthProvider, sendFeedbackSubmissionState: SendFeedbackSubmissionState) {
        self.authProvider = authProvider
        self.sendFeedbackSubmissionState = sendFeedbackSubmissionState
    }
    
    func sendFeedback(feedback: String, contact: String?) async throws {
        sendFeedbackSubmissionState = .submitting
        // ideally we could de-dupe this code her and in SendFeedbackDataModel. but when i move state transition to enum, it doesn't trigger state change for submitting
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        print("mock sending feedback... ", feedback, " with contact", contact ?? "")
        sendFeedbackSubmissionState = .submitted
    }
}

extension SendFeedbackProvider where Self == PreviewSendFeedbackDataModel {
    static var unsubmitted: Self {
        PreviewSendFeedbackDataModel(
            authProvider: PreviewAuthProvider.isLoggedIn,
            sendFeedbackSubmissionState: .unsubmitted
        )
    }
    
    static var submitting: Self {
        PreviewSendFeedbackDataModel(
            authProvider: PreviewAuthProvider.isLoggedIn,
            sendFeedbackSubmissionState: .submitting
        )
    }
    
    static var submitted: Self {
        PreviewSendFeedbackDataModel(
            authProvider: PreviewAuthProvider.isLoggedIn,
            sendFeedbackSubmissionState: .submitted
        )
    }
}

