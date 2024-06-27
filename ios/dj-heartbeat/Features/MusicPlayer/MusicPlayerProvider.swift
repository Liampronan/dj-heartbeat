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
    func setQueue()
}

@Observable class AppleMusicPlayer: NSObject, MusicPlayerProvider {
    var playedItems = [String]()
    var playbackState: MPMusicPlaybackState = MPMusicPlayerController.applicationMusicPlayer.playbackState
    
    var currentSongTitle: String = ""
    
    private var appMusicPlayer: MPMusicPlayerController {
        return MPMusicPlayerController.applicationMusicPlayer
    }
    
    func startMonitoringMusicPlayer() {
        appMusicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNowPlayingItemChanged),
                                               name: .MPMusicPlayerControllerNowPlayingItemDidChange,
                                               object: MPMusicPlayerController.applicationMusicPlayer)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePlaybackStateChanged),
                                               name: .MPMusicPlayerControllerPlaybackStateDidChange,
                                               object: MPMusicPlayerController.applicationMusicPlayer)
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
        appMusicPlayer.play()
    }
    
    func pause() {
        appMusicPlayer.pause()
    }
    
    func skipToNextItem() {
        appMusicPlayer.skipToNextItem()
        
    }
    
    func skipToPrevItem() {
        appMusicPlayer.skipToPreviousItem()
    }
    
    func setQueue() {
        MPMusicPlayerController.applicationMusicPlayer.setQueue(with: .songs())
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
    
    func setQueue() { }
}

extension MusicPlayerProvider where Self == Previews_MusicPlayer {
    static var playing: Self {
        let items = ["Highway to the Dangerzone", "We Can't Stop", "Levels"]
        return Previews_MusicPlayer(playbackState: .playing, playedItems: items, currentSongTitle: "Dance The Night")
    }
}
