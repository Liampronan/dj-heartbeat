import Foundation

struct WeeklyTopTrack: Codable {
    let id: String
    let track: Track
    let totalHeartbeats: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case track
        case totalHeartbeats
    }
    
    static func mock(with track: Track) -> Self {
        return .init(id: UUID().uuidString, track: track, totalHeartbeats: Double.random(in: 100...400))
    }
}

extension WeeklyTopTrack: TrackInfoWithHeartbeats {
    var name: String { track.name }
    var artist: String { track.artist }
    var albumImageURL: URL { track.albumImageURL }
    var heartbeats: Int { Int(totalHeartbeats) }
}
