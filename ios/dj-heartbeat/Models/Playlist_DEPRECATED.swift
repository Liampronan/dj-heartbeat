struct PlaylistThirdPartyInfo: Codable {
    let uri: String // example: spotify:playlist:7wNJXj3yxJwc4qjfOOZcwM
}

struct Playlist_DEPRECATED: Codable {
    let name: String
    let tracks: [Track_DEPRECATED]
    let thirdPartyInfo: PlaylistThirdPartyInfo
    
    func contains(track: Track_DEPRECATED) -> Bool {
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

extension Playlist_DEPRECATED {
    private static var mockTitle = "slaylist | april24"
    
    static func mock() -> Playlist_DEPRECATED {
        return .init(name: mockTitle, tracks: Track_DEPRECATED.mockTracks, thirdPartyInfo: .init(uri: "https://example.com"))
    }
    
    static func mockAddToPlaylist(newTrack: Track_DEPRECATED) -> Playlist_DEPRECATED {
        let updatedPlaylist = Track_DEPRECATED.mockTracks + [newTrack]
        return .init(name: mockTitle, tracks: updatedPlaylist, thirdPartyInfo: .init(uri: "https://example.com"))
    }
    
    static func mockEmptyPlaylist() -> Playlist_DEPRECATED {
        return .init(name: mockTitle, tracks: [], thirdPartyInfo: .init(uri: ""))
    }
}
