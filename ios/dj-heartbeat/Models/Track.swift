import Foundation

protocol TrackInfo: Codable {
    var name: String { get }
    var artist: String { get }
    var albumImageURL: URL { get }
}

protocol TrackInfoWithHeartbeats: TrackInfo, Codable {
    var heartbeats: Int { get }
}

struct Track: Codable, Identifiable, TrackInfo, Equatable, Hashable {
    let id: String
    let trackDurationMS: Int
    let name, artist: String
    let albumArtURLString: String
    var albumImageURL: URL { URL(string: albumArtURLString)! }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, artist, trackDurationMS
        case albumArtURLString = "albumArtUrl"
    }
}

extension Track {
    static var mockTracks: [Self] {
        return [mockTrack, mockTrack2, mockTrack3, mockTrack4, mockTrack5, mockTrack6]
    }
}

let mockTrack = Track(
    id: "123",
    trackDurationMS: 32342,
    name: "90210",
    artist: "Travis Scott",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273715973050587fe3c93033aad"
)

let mockTrack2 = Track(
    id: "65dfc9cdadeda9e583df3d1f",
    trackDurationMS: 210090,
    name: "Rhythm Is a Dancer",
    artist: "SNAP!",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b2731c67046b3ff199558c065bbb"
)

let mockTrack3 = Track(
    id: "65efa86f8e95f928f559db37",
    trackDurationMS: 214240,
    name: "Kamikaze",
    artist: "MØ",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b27330955deea86056e80b9cc630"
)

let mockTrack4 = Track(
    id: "65efa86f8e95f928f559db39",
    trackDurationMS: 199426,
    name: "3 Peat",
    artist: "Lil Wayne",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b27333ebdffaa447ff19ce9f24bb"
)

let mockTrack5 = Track(
    id: "65ebe6fd8e95f928f5f740e7",
    trackDurationMS: 129817,
    name: "Hot In It (feat. Charli XCX)",
    artist: "Tiësto",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273cf8c47967e5c6bbc7dca5abb"
)

let mockTrack6 = Track(
    id: "65e7d5dcadeda9e5836a7178",
    trackDurationMS: 129817,
    name: "Milkshake",
    artist: "Kelis",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b2736575b1bd7db306ab468ac327"
)

let mockTrack7 = Track(
    id: "65d433df0ff8bd4efaccdc68",
    trackDurationMS: 193829,
    name: "Physical",
    artist: "Dua Lipa",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273ccdddb2e5349ea0608c3e016"
)

let mockTrack8 = Track(
    id: "6604c6f25dac9789b89e9e11",
    trackDurationMS: 178583,
    name: "Blow Your Mind (Mwah)",
    artist: "Dua Lipa",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273838698485511bd9108fadadc"
)

let mockTrack9 = Track(
    id: "65dea536969001ac7731ec1b",
    trackDurationMS: 251240,
    name: "Gimme More",
    artist: "Britney Spears",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273ca10fae7d292c52f7e8b11ca"
)

let mockTrack10 = Track(
    id: "65d91092075385879e2ad2ba",
    trackDurationMS: 238626,
    name: "Disturbia",
    artist: "Rihanna",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273f9f27162ab1ed45b8d7a7e98"
)

let mockTrack11 = Track(
    id: "65dcb6ad68da9955fe156c2a",
    trackDurationMS: 252106,
    name: "Show Me Love",
    artist: "Robin S",
    albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273b4bd024fb05eb2c0ddf6ea61"
)

let mockTrackNotOnDefaultPlaylist = Track(id: "65d51bfd97adba6037fd2964", trackDurationMS: 148485, name: "I Ain't Worried", artist: "OneRepublic", albumArtURLString: "https://i.scdn.co/image/ab67616d0000b273ec96e006b8bdfc582610ec13")

