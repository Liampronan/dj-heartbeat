import Observation
import MediaPlayer
import MusicKit
import SwiftUI

struct AppleMusicView: View {
    @State var authMgr = MusicAuthorizationManager()
    @State var musicQueueManager = MusicQueueManager()
    
    // START:
    // - clean up play / pause btn -- wrap `applicationMusicPlayer.playbackState` in obersvable
    // ____set this up for an actual run____
    // - create queue items: can be simple via playlist
    // - start queue

    var body: some View {
        VStack {
            switch authMgr.authState {
            case .authorized:
                Text("is logged in")
                    .padding()
                Button(MPMusicPlayerController.applicationMusicPlayer.playbackState == .playing ? "pause" : "play") {
                    if MPMusicPlayerController.applicationMusicPlayer.playbackState == .playing {
                        MPMusicPlayerController.applicationMusicPlayer.pause()
                    } else {
                        MPMusicPlayerController.applicationMusicPlayer.play()
                    }
                }
                Button("next") {
                    MPMusicPlayerController.applicationMusicPlayer.skipToNextItem()
                }
                ScrollView {
                    VStack {
                        ForEach(musicQueueManager.playedItems, id: \.self) { item in
                            Text(item)
                        }
                    }
                }
            case .notDetermined:
                Button("Authorize Apple Music") {
                    handleRequestAuthorizeAppleMusicTap()
                }
                .padding()
            case .deniedOrRestricted:
                ErrorView() // TODO: route to settings>permissions
            case .unknown:
                ErrorView()
            }
        }
        .onAppear {
            Task {
                await authMgr.requestMusicAuthorization()
            }
        }
        .onChange(of: authMgr.authState) { oldValue, newValue in
            print(oldValue, newValue)
            if newValue == .authorized {
                Task {
                    await fetchRecentlyPlayedSongs()
                    MPMusicPlayerController.applicationMusicPlayer.setQueue(with: .songs())
//                    try await MPMusicPlayerController.applicationMusicPlayer.prepareToPlay()
//                    print("prepareToPlay √")
                    musicQueueManager.startMonitoringMusicPlayer()
                }
            }
        }
    }
    
    private func handleRequestAuthorizeAppleMusicTap() {
        Task { await authMgr.requestMusicAuthorization() }
    }
    
    private func fetchRecentlyPlayedSongs() async {
        print("lastPlayedDate: ")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.id ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.startTime ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.title ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.subtitle ?? "")
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.item ?? "")
    }
}

@Observable class MusicAuthorizationManager {
    enum AuthState {
        case authorized
        case notDetermined
        case deniedOrRestricted
        case unknown
        
        init(from musickitStatus: MusicAuthorization.Status) {
            print("musickitStatus is: ", musickitStatus.rawValue)
            switch musickitStatus {
            case .authorized:
                self = .authorized
            case .notDetermined:
                self = .notDetermined
            case .denied, .restricted:
                self = .deniedOrRestricted
            @unknown default:
                self = .unknown
            }
        }
    }
    
    var isAuthorizedForMusicKit = false
    var authState: AuthState = .unknown
    // we may not need these
//    let developerToken = try await DefaultMusicTokenProvider().developerToken(options: .ignoreCache)
//    let userToken = try await musicUserTokenProvider.userToken(for: developerToken, options: .ignoreCache)
    
    func checkAuthorization() async {
        authState = AuthState(from: MusicAuthorization.currentStatus)
    }
    
    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        authState = AuthState(from: status)
    }
}
