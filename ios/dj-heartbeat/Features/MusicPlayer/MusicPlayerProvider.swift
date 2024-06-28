import Combine
import MediaPlayer
import MusicKit

protocol MusicPlayerProvider {
    var playedItems: [String] { get }
    var playbackStatus: MusicKit.MusicPlayer.PlaybackStatus { get }
    var currentSongTitle: String { get }
    
    func play()
    func pause()
    func skipToPrevItem()
    func skipToNextItem()
    func queueItemsFromTestPlaylist() async throws
}

@Observable
class ObservableState<Item> {
    var item: Item

    init(item: Item) {
        self.item = item
    }
}

@Observable class AppleMusicPlayer: NSObject, MusicPlayerProvider {
    var playedItems = [String]()
    var playbackStatus: MusicKit.MusicPlayer.PlaybackStatus = ApplicationMusicPlayer.shared.state.playbackStatus
    
    private var subscriptions = Set<AnyCancellable>()
    
    override init() {
        super.init()
        appMusicPlayer.state.objectWillChange.sink { [weak self] in
            guard let self else { return }
            self.playbackStatus = self.appMusicPlayer.state.playbackStatus
        }
        .store(in: &subscriptions)
    }
    
    var currentSongTitle: String = ""
    
    private var appMusicPlayer: ApplicationMusicPlayer = ApplicationMusicPlayer.shared
    
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
        let album = try await testFindAlbum()
        print(album)
        print("album^^^")
        appMusicPlayer.queue = [album]
        
        
        
        /*
         let tracks = try await testingFindPlaylistTracks()
//        appMusicPlayer.queue = tracks
        
        let collection = MusicItemCollection(tracks)
        
//        ApplicationMusicPlayer.shared
        try await appMusicPlayer.queue.insert(collection, position: .tail)
//        try await  appMusicPlayer.skipToNextEntry()
//        appMusicPlayer.queue = tracks
        print(appMusicPlayer.queue)
        print("queue", appMusicPlayer.queue.entries.count)
        try await ApplicationMusicPlayer.shared.prepareToPlay()
         */
    }
    
    func testFindAlbum() async throws -> Album {
        let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: "1603171516")
        let response = try await request.response()

        guard let album = response.items.first else {
            throw NSError(domain: "me", code: 404)
        }
          
        let player = ApplicationMusicPlayer.shared

        return album
    }
    
    //https://music.apple.com/us/playlist/dj-heartbeat/pl.u-XkD0Y6pT438xpo
    let playlistId = "pl.u-XkD0Y6pT438xpo"
    func testingFindPlaylistTracks() async throws -> [Song] {
        
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
    var playbackStatus: MusicKit.MusicPlayer.PlaybackStatus
    
    init(playbackStatus: MusicKit.MusicPlayer.PlaybackStatus, playedItems: [String], currentSongTitle: String) {
        self.playedItems = playedItems
        self.playbackStatus = playbackStatus
        self.currentSongTitle = currentSongTitle
    }
    
    func play() { 
        playbackStatus = .playing
    }
    
    func pause() { 
        playbackStatus = .paused
    }
    
    func skipToPrevItem() { }
    
    func skipToNextItem() { }
    
    func queueItemsFromTestPlaylist() { }
}

extension MusicPlayerProvider where Self == Previews_MusicPlayer {
    static var playing: Self {
        let items = ["Highway to the Dangerzone", "We Can't Stop", "Levels"]
        return Previews_MusicPlayer(playbackStatus: .playing, playedItems: items, currentSongTitle: "Dance The Night")
    }
}


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
