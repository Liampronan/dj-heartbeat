import Combine
import MediaPlayer
import MusicKit

protocol MusicPlayerProvider {
    var playedItems: [TESTING_PlayItem] { get }
    var playbackStatus: MusicKit.MusicPlayer.PlaybackStatus { get }
    var currentSongTitle: String { get }
    var history: MusicPlayerHistory { get }
    var queue: MusicPlayerQueue { get }
    
    func play()
    func pause()
    func skipToPrevItem()
    func skipToNextItem()
    func queueItemsFromTestPlaylist() async throws
}

@Observable class MusicPlayerHistory {
    private(set) var songs: [TESTING_PlayItem]

    init(songs: [TESTING_PlayItem] = []) {
        self.songs = songs
    }
    // this is a little funky because it also needs the trackSongStart call to happen first to accurately track everything.
    // it works for now. edge cases: it's unaware of pauses (so end time could be > length of song) and first track.
    // a cleaner approach could be to replay the state changes from the Application Music Player and handle them in a state machine way here.
    func playerDidChange(with currentEntry: ApplicationMusicPlayer.Queue.Entry) {
        // set timestamp
        guard songs.count > 0 else {
            songs.append(.init(title: currentEntry.title, startedAt: nil, endedAt: .now))
            return
        }
        
        if songs.count == 1, songs[0].endedAt == nil {
            songs[0].endedAt = .now
        }
        
        let prevEndedAt = songs[songs.count - 1].endedAt
        
        // NEXT: build virtual queue THEN set the appMusicPlayer.queue to those (by making them queue items). then consider just using queue which includes history (?).
        songs.append(.init(title: currentEntry.title, startedAt: prevEndedAt, endedAt: .now))
    }
    
    func trackSongStart(with currentEntry: ApplicationMusicPlayer.Queue.Entry) {
        songs.append(.init(title: currentEntry.title, startedAt: .now, endedAt: nil))
    }
}

@Observable class MusicPlayerQueue {
    private(set) var songs: [TESTING_PlayItem] //fixme: we'll need to have these compatible with Apple Music Playable items.

    init(songs: [TESTING_PlayItem] = []) {
        self.songs = songs
    }
}

struct TESTING_PlayItem {
    let title: String
    var startedAt: Date?
    var endedAt: Date?
}

@Observable class AppleMusicPlayer: NSObject, MusicPlayerProvider {
    var playbackStatus: MusicKit.MusicPlayer.PlaybackStatus = ApplicationMusicPlayer.shared.state.playbackStatus
    var playedItems: [TESTING_PlayItem] { return history.songs }

    private(set) var history = MusicPlayerHistory()
    private(set) var queue = MusicPlayerQueue()
    private var appMusicPlayer: ApplicationMusicPlayer = ApplicationMusicPlayer.shared
    
    private var subscriptions = Set<AnyCancellable>()
    
    var currentSongTitle: String = ""
    
    func play() {
        Task {
            try? await ApplicationMusicPlayer.shared.play()
            print("queue", appMusicPlayer.queue.entries.count)
        }
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
    
    func startObserving() {
        appMusicPlayer.queue.objectWillChange.sink { [weak self] in
            guard let self else { return }
            // not sure if we want this. feels a bit much though to have to track state like this
            guard appMusicPlayer.state.playbackStatus == .playing else { return }

            guard let queueCurrentEntry = appMusicPlayer.queue.currentEntry else { return }
            history.playerDidChange(with: queueCurrentEntry)
        }
        .store(in: &subscriptions)
        
        appMusicPlayer.state.objectWillChange.sink { [weak self] in
            guard let self else { return }
            self.playbackStatus = self.appMusicPlayer.state.playbackStatus
            // TOOD: handle last song
//            switch status {
//            case .playing:
//                // Track start if needed
//            case .paused, .stopped:
//                // Record end time
//                if let lastEntry = history.last, lastEntry.endTime == nil {
//                    history[history.count - 1].endTime = Date()
//                }
//            default:
//                break
//            }
            
        }
        .store(in: &subscriptions)
        
        // this just seems to track the first setting of the whole queue. so it doesn't seem to work when tapping next to go to the next item in the queue.
        appMusicPlayer.queue.currentEntry.publisher.sink { [weak self] entry in
            guard let self else { return }
            print("currentEntry did change", entry)
            self.history.trackSongStart(with: entry)
        }.store(in: &subscriptions)
    }
    
    func queueItemsFromTestPlaylist() async throws {
        let playlistSongs = try await testingFindPlaylistTracks()
      
        let entries = playlistSongs.map { MusicPlayer.Queue.Entry($0) }
        // note: we must have a queue with an entries and call `prepareToPlay` BEFORE adding to the queue
        appMusicPlayer.queue = .init(entries)
        try await appMusicPlayer.prepareToPlay()
        
//        let secondEntry = MusicPlayer.Queue.Entry(playlistSongs.first!)
//        try await appMusicPlayer.queue.insert(secondEntry, position: .afterCurrentEntry)
        startObserving()
    }
    
    //https://music.apple.com/us/playlist/dj-heartbeat/pl.u-XkD0Y6pT438xpo
    let playlistId = "pl.u-XkD0Y6pT438xpo"
    func testingFindPlaylistTracks() async throws -> [Track] {
        // Create a request for the playlist
        var playlistRequest = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(playlistId))
        playlistRequest.properties = [.tracks]
        let response = try await playlistRequest.response()
        
        // Get the first playlist from the response
        guard let playlist = response.items.first else {
            throw NSError(domain: "Playlist not found", code: 404, userInfo: nil)
        }
        
        guard let songs = playlist.tracks?.compactMap({ $0 }) else {
            throw NSError(domain: "Playlist tracks not found", code: 404, userInfo: nil)
        }

        return songs
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
    var history: MusicPlayerHistory
    var queue: MusicPlayerQueue
    var playbackStatus: MusicKit.MusicPlayer.PlaybackStatus
    
    
    var playedItems: [TESTING_PlayItem] {
        return history.songs
    }

    init(playbackStatus: MusicKit.MusicPlayer.PlaybackStatus, currentSongTitle: String, history: MusicPlayerHistory, queue: MusicPlayerQueue) {
        self.playbackStatus = playbackStatus
        self.currentSongTitle = currentSongTitle
        self.history = history
        self.queue = queue
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
        
        let playedItems = Track_DEPRECATED.mockTracks.map { TESTING_PlayItem.init(title: $0.name, startedAt: .now, endedAt: .now) }
        let queuedItems = Track_DEPRECATED.mockTracks.map { TESTING_PlayItem.init(title: $0.name, startedAt: .now, endedAt: .now) }
        
        return Previews_MusicPlayer(playbackStatus: .playing, currentSongTitle: "Dance The Night", history: .init(songs: playedItems), queue: .init(songs: queuedItems))
    }
}
