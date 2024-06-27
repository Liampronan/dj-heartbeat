import Foundation
import MusicKit

protocol MusicAuthProvider {
    var authState: MusicAuthState { get }
    
    func requestMusicAuthorization() async
}

enum MusicAuthState {
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

@Observable class AppleMusicAuthProvider: MusicAuthProvider {
    private(set) var authState: MusicAuthState = MusicAuthState(from: MusicAuthorization.currentStatus)
    
    func checkAuthorization() async {
        authState = MusicAuthState(from: MusicAuthorization.currentStatus)
    }
    
    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        authState = MusicAuthState(from: status)
    }
}

@Observable class Previews_MusicAuthProvider: MusicAuthProvider {
    var authState: MusicAuthState
    
    init(authState: MusicAuthState) {
        self.authState = authState
    }
    
    func requestMusicAuthorization() async {
        try? await Task.sleep(for: .seconds(0.5))
        authState = .authorized
    }
}

extension MusicAuthProvider where Self == Previews_MusicAuthProvider {
    
    static var authorized: Self {
        Previews_MusicAuthProvider(authState: .authorized)
    }
    
    static var notDetermined: Self {
        Previews_MusicAuthProvider(authState: .notDetermined)
    }
    
}
