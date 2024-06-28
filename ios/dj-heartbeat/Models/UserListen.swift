import Foundation

struct UserListen: Codable, Identifiable {
    let id: String
    let track: Track_DEPRECATED
    let listenedAt: Date
    let totalHeartbeats: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case track, listenedAt, totalHeartbeats
    }
}

extension UserListen {
    static var mocks: [UserListen] {
        [
            .init(
                id: UUID().uuidString,
                track: mockTrack,
                listenedAt: .now,
                totalHeartbeats: 210),
            .init(
                id: UUID().uuidString,
                track: mockTrack2,
                listenedAt: .now,
                totalHeartbeats: 273 ),
            .init(
                id: UUID().uuidString,
                track: mockTrack3,
                listenedAt: .now,
                totalHeartbeats: 319 ),
            .init(
                id: UUID().uuidString,
                track: mockTrack4,
                listenedAt: .now,
                totalHeartbeats: 389 ),
            .init(
                id: UUID().uuidString,
                track: mockTrack5,
                listenedAt: .now,
                totalHeartbeats: 298 )
        ]
    }
}

extension UserListen: TrackInfoWithHeartbeats {
    var name: String { track.name }
    var artist: String { track.artist }
    var albumImageURL: URL { track.albumImageURL }
    var heartbeats: Int { Int(totalHeartbeats) }
}
