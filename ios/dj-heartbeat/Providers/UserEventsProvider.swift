import Foundation

protocol UserEventsProvider {
    func postAppOpened() async
}

@Observable class UserEventsDataModel: UserEventsProvider {
    func postAppOpened() async {
        do {
            try await UserEventsAPI.postAppOpened()
        } catch {
            print("error postingAppOpened")
        }
    }
}

@Observable class PreviewUserEventsDataModel: UserEventsProvider {
    func postAppOpened() async {}
}

extension UserEventsProvider where Self == PreviewUserEventsDataModel {
    static var noopPostAppOpened: Self {
        PreviewUserEventsDataModel()
    }
}
