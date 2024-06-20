struct PlaylistThirdPartyInfo: Codable {
    let uri: String // example: spotify:playlist:7wNJXj3yxJwc4qjfOOZcwM
}

struct Playlist: Codable {
    let name: String
    let tracks: [Track]
    let thirdPartyInfo: PlaylistThirdPartyInfo
    
    func contains(track: Track) -> Bool {
        tracks.contains { $0 == track }
    }
    
    var playlistDurationMS: Int { tracks.reduce(0) { $0 + $1.trackDurationMS} }
    
    var isEmpty: Bool {
         return tracks.isEmpty
    }
    
    var monthName: String {
        name.replacingOccurrences(of: "slaylist |", with: "")
    }
}

extension Playlist {
    private static var mockTitle = "slaylist | april24"
    
    static func mock() -> Playlist {
        return .init(name: mockTitle, tracks: Track.mockTracks, thirdPartyInfo: .init(uri: "https://example.com"))
    }
    
    static func mockAddToPlaylist(newTrack: Track) -> Playlist {
        let updatedPlaylist = Track.mockTracks + [newTrack]
        return .init(name: mockTitle, tracks: updatedPlaylist, thirdPartyInfo: .init(uri: "https://example.com"))
    }
    
    static func mockEmptyPlaylist() -> Playlist {
        return .init(name: mockTitle, tracks: [], thirdPartyInfo: .init(uri: ""))
    }
}
