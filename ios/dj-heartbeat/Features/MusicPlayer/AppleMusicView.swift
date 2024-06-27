import Observation
import MusicKit
import SwiftUI

struct AppleMusicView: View {
    @Environment(\.musicPlayerProvider) private var musicPlayerProvider
    @State var authMgr = MusicAuthorizationManager()
    
    
    // START:
    // √ clean up play / pause btn -- wrap `applicationMusicPlayer.playbackState` in obersvable
    // ____set this up for an actual run____
    // - create queue items: can be simple via playlist
    // - start queue

    var body: some View {
        VStack {
            switch authMgr.authState {
            case .authorized:
                VStack {
                    MusicPlayerView()
                    ScrollView {
                        VStack {
                            ForEach(musicPlayerProvider.playedItems, id: \.self) { item in
                                Text(item)
                            }
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
    }
    
    private func handleRequestAuthorizeAppleMusicTap() {
        Task { await authMgr.requestMusicAuthorization() }
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
    var authState: AuthState = AuthState(from: MusicAuthorization.currentStatus)
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
