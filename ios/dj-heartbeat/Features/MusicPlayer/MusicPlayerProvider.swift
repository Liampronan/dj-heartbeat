import MediaPlayer
import MusicKit

protocol MusicPlayerProvider {
    var playedItems: [String] { get }
    var playbackState: MPMusicPlaybackState { get }
    var currentSongTitle: String { get }
    
    func play()
    func pause()
    func skipToPrevItem()
    func skipToNextItem()
    func queueItemsFromTestPlaylist() async throws
}

@Observable class AppleMusicPlayer: NSObject, MusicPlayerProvider {
    var playedItems = [String]()
    var playbackState: MPMusicPlaybackState = MPMusicPlayerController.applicationMusicPlayer.playbackState
    
    var currentSongTitle: String = ""
    
    private var appMusicPlayer: ApplicationMusicPlayer = ApplicationMusicPlayer.shared
    
    func startMonitoringMusicPlayer() {
//        appMusicPlayer.beginGeneratingPlaybackNotifications()
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(handleNowPlayingItemChanged),
//                                               name: .MPMusicPlayerControllerNowPlayingItemDidChange,
//                                               object: MPMusicPlayerController.applicationMusicPlayer)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(handlePlaybackStateChanged),
//                                               name: .MPMusicPlayerControllerPlaybackStateDidChange,
//                                               object: MPMusicPlayerController.applicationMusicPlayer)
    }

    @objc func handleNowPlayingItemChanged(notification: Notification) {
        let player = MPMusicPlayerController.applicationMusicPlayer
        let nowPlayingItem = player.nowPlayingItem
        let title = nowPlayingItem?.title ?? "Unknown"
        playedItems.append(title)
    }
    
    @objc func handlePlaybackStateChanged(notification: Notification) {
        playbackState = MPMusicPlayerController.applicationMusicPlayer.playbackState
        
    }

    func stopMonitoringMusicPlayer() {
        NotificationCenter.default.removeObserver(self, 
                                                  name: .MPMusicPlayerControllerNowPlayingItemDidChange,
                                                  object: MPMusicPlayerController.applicationMusicPlayer)
        NotificationCenter.default.removeObserver(self,
                                               name: .MPMusicPlayerControllerPlaybackStateDidChange,
                                               object: MPMusicPlayerController.applicationMusicPlayer)
        MPMusicPlayerController.applicationMusicPlayer.endGeneratingPlaybackNotifications()
    }
    
    func play() {
        Task { try? await ApplicationMusicPlayer.shared.play() }
    }
    
    func pause() {
        appMusicPlayer.pause()
    }
    
    func skipToNextItem() {
        Task { try? await appMusicPlayer.skipToNextEntry() }
    }
    
    func skipToPrevItem() {
        Task { try? await appMusicPlayer.skipToPreviousEntry() }
    }
    
    func queueItemsFromTestPlaylist() async throws {
        let tracks = try await testingFindPlaylistTracks()
        print(tracks)
        print("tracks^^^")
//        appMusicPlayer.queue = tracks
        
        let collection = MusicItemCollection(tracks)
        
//        ApplicationMusicPlayer.shared
        try await appMusicPlayer.queue.insert(collection, position: .tail)
//        try await  appMusicPlayer.skipToNextEntry()
//        appMusicPlayer.queue = tracks
        print(appMusicPlayer.queue)
        print("queue", appMusicPlayer.queue.entries.count)
        try await ApplicationMusicPlayer.shared.prepareToPlay()
    }
    
    //https://music.apple.com/us/playlist/dj-heartbeat/pl.u-XkD0Y6pT438xpo
    func testingFindPlaylistTracks() async throws -> [Song] {
//        let playlistId = "pl.u-XkD0Y6pT438xpo"
//        // Create a request for the playlist
//        var playlistRequest = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(playlistId))
//        playlistRequest.properties = [.tracks]
//        // Perform the request
//        let response = try await playlistRequest.response()
//
//        // Get the first playlist from the response
//        guard let playlist = response.items.first else {
//            throw NSError(domain: "Playlist not found", code: 404, userInfo: nil)
//        }
//
//        guard let songs = playlist.tracks?.compactMap({ $0 }) else {
//            throw NSError(domain: "Playlist tracks not found", code: 404, userInfo: nil)
//        }
//
//        return songs
        
//        let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: "1603171516")
//        let response = try await request.response()
//
//        guard let album = response.items.first else { return [] }
//
//        let player = ApplicationMusicPlayer.shared
////***********************
        //****** TODO START -- why does this queue=[album] work but your songs don't. they seem to work after adding 
//        player.queue = [album] /// <- directly add the whole album to the queue
//
//        try await player.prepareToPlay()
//        try await player.play()
        
        let playlistId = "pl.u-XkD0Y6pT438xpo"
        // Create a request for the playlist
        var playlistRequest = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(playlistId))
        playlistRequest.properties = [.tracks]
        
        
        // Perform the request
        let response2 = try await playlistRequest.response()
        
        // Get the first playlist from the response
        guard let playlist = response2.items.first else {
            throw NSError(domain: "Playlist not found", code: 404, userInfo: nil)
        }
        
        guard let songs = playlist.tracks?.compactMap({ $0 }) else {
            throw NSError(domain: "Playlist tracks not found", code: 404, userInfo: nil)
        }
        let songIds = songs.map { $0.id }
        let playlistSongsRequest = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: songIds)
        let fetchedSongsResponse = try await playlistSongsRequest.response()
        let fetchedSongs = fetchedSongsResponse.items.compactMap { $0 }
//        return songs
        return fetchedSongs
        // Fetch the songs in the playlist
//        let songsRequest = MusicCatalogResourceRequest<Song>(matching: \.id, in: playlist.tracks.map { $0.id })
//        let songsResponse = try await songsRequest.response()
    }
    
    func printQueueCurrentEntry() {
        print("lastPlayedDate: ")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.id ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.startTime ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.title ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.subtitle ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.item ?? "")
    }
}

@Observable class Previews_MusicPlayer: MusicPlayerProvider {
    var currentSongTitle: String
    var playedItems: [String]
    var playbackState: MPMusicPlaybackState
    
    
    init(playbackState: MPMusicPlaybackState, playedItems: [String], currentSongTitle: String) {
        self.playedItems = playedItems
        self.playbackState = playbackState
        self.currentSongTitle = currentSongTitle
    }
    
    func play() { 
        playbackState = .playing
    }
    
    func pause() { 
        playbackState = .paused
    }
    
    func skipToPrevItem() { }
    
    func skipToNextItem() { }
    
    func queueItemsFromTestPlaylist() { }
}

extension MusicPlayerProvider where Self == Previews_MusicPlayer {
    static var playing: Self {
        let items = ["Highway to the Dangerzone", "We Can't Stop", "Levels"]
        return Previews_MusicPlayer(playbackState: .playing, playedItems: items, currentSongTitle: "Dance The Night")
    }
}
