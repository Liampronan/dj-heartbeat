import MusicKit
import MediaPlayer

@Observable class MusicQueueManager: NSObject {
//    override init() {
//        super.init()
//        startMonitoringMusicPlayer()
//    }
    
    var playedItems = ["test1", "test2"]

    func startMonitoringMusicPlayer() {
        MPMusicPlayerController.applicationMusicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNowPlayingItemChanged), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: MPMusicPlayerController.applicationMusicPlayer)
    }

    @objc func handleNowPlayingItemChanged(notification: Notification) {
        let player = MPMusicPlayerController.applicationMusicPlayer
        let nowPlayingItem = player.nowPlayingItem
        let title = nowPlayingItem?.title ?? "Unknown"
        print("Now playing: \(title)")
        
        playedItems.append(title)
    }

    func stopMonitoringMusicPlayer() {
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: MPMusicPlayerController.applicationMusicPlayer)
        MPMusicPlayerController.applicationMusicPlayer.endGeneratingPlaybackNotifications()
    }
}
