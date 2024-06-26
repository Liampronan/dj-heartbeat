import Observation
import MediaPlayer
import MusicKit
import SwiftUI

struct AppleMusicView: View {
    @State var authMgr = MusicAuthorizationManager()
    
    var body: some View {
        VStack {
            switch authMgr.authState {
            case .authorized:
                Text("is logged in")
                    .padding()
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
                Task { await fetchRecentlyPlayedSongs() }
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
