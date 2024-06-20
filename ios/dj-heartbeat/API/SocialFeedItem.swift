import Foundation

struct DaySocialFeedItems: Codable {
    let feedItems: [SocialFeedItem]
    var hearbeatCount: Int {
        return feedItems.reduce(0) { $0 + $1.heartbeatCount }
    }
    
    static func mock() -> Self {
        .init(feedItems: [.mock(), .mock(), .mock(), .mock()])
    }
    
    static func mockNoResults() -> Self {
        .init(feedItems: [])
    }
}

struct SocialFeedItem: Codable, Identifiable {
    var id: String { username + workoutType.rawValue + "\(heartbeatCount)" }
    let userListens: [UserListen]
    let username: String
    let workoutType: WorkoutType
    var heartbeatCount: Int { userListens.reduce(0) { $0 + $1.heartbeats } }

    static func mock() -> Self {
        .init(
            userListens: UserListen.mocks,
            username: "@mileystan",
            workoutType: .running
        )
    }
}
