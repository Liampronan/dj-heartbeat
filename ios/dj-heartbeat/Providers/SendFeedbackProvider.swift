import Foundation

protocol SendFeedbackProvider {
    var sendFeedbackSubmissionState: SendFeedbackSubmissionState { get }
    func sendFeedback(feedback: String, contact: String?) async throws
}

enum SendFeedbackSubmissionState {
    case unsubmitted
    case submitting
    case submitted
}

@Observable class SendFeedbackDataModel: SendFeedbackProvider {
    var sendFeedbackSubmissionState = SendFeedbackSubmissionState.unsubmitted
    
    func sendFeedback(feedback: String, contact: String?) async throws {
        guard sendFeedbackSubmissionState == .unsubmitted else { return }
        sendFeedbackSubmissionState = .submitting
        // ideally we could de-dupe this code. but when i move state transition to enum, it doesn't trigger state change for submitting
        try await SendFeedbackAPI.postData(req: .init(feedback: feedback, contact: contact))
        sendFeedbackSubmissionState = .submitted
    }
}

@Observable class PreviewSendFeedbackDataModel: SendFeedbackProvider {
    var sendFeedbackSubmissionState: SendFeedbackSubmissionState
    
    init(sendFeedbackSubmissionState: SendFeedbackSubmissionState) {
        self.sendFeedbackSubmissionState = sendFeedbackSubmissionState
    }
    
    func sendFeedback(feedback: String, contact: String?) async throws {
        sendFeedbackSubmissionState = .submitting
        // ideally we could de-dupe this code. but when i move state transition to enum, it doesn't trigger state change for submitting
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        print("mock sending feedback... ", feedback, " with contact", contact ?? "")
        sendFeedbackSubmissionState = .submitted
    }
}

extension SendFeedbackProvider where Self == PreviewSendFeedbackDataModel {
    static var unsubmitted: Self {
        PreviewSendFeedbackDataModel(sendFeedbackSubmissionState: .unsubmitted)
    }
    
    static var submitting: Self {
        PreviewSendFeedbackDataModel(sendFeedbackSubmissionState: .submitting)
    }
    
    static var submitted: Self {
        PreviewSendFeedbackDataModel(sendFeedbackSubmissionState: .submitted)
    }
}

