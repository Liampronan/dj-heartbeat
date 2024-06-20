import Foundation
import SpotifyiOS

protocol SpotifyAuthProvider {
    var sessionManager: SPTSessionManager { get }
    func authorize()
}

// TODO: if we go this way, we need to set accessToken on appRemote in order to control on-device spotify player (as opposed to just interacting with server).
    //    self.appRemote.connectionParams.accessToken = session.accessToken

class SpotifyAuthController: SpotifyAuthProvider {
    let SpotifyClientID = Config.spotifyClientId
    let SpotifyRedirectURL = URL(string: Config.spotifyRedirectURL)!
    let spotifySessionDelegate = SpotifySessionManagerDelegate()
    lazy var configuration = SPTConfiguration(
      clientID: SpotifyClientID,
      redirectURL: SpotifyRedirectURL
    )
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: "\(Config.apiBaseURL)/apiToken"),
         let tokenRefreshURL = URL(string: "\((Config.apiBaseURL))/refreshApiToken") {
        self.configuration.tokenSwapURL = tokenSwapURL
        self.configuration.tokenRefreshURL = tokenRefreshURL
        self.configuration.playURI = ""
      }
      let manager = SPTSessionManager(configuration: self.configuration, delegate: spotifySessionDelegate)
      return manager
    }()
    
    func authorize() {
        let scope: SPTScope = [.userReadRecentlyPlayed,  .userReadEmail, .userReadCurrentlyPlaying, .userReadPlaybackState, .userModifyPlaybackState, .playlistModifyPublic, .playlistModifyPrivate]
        sessionManager.initiateSession(with: scope, options: .default)
    }
}

struct GenerateClientTokenRequestParams: Codable {
    let spotifyAccessToken: String
    let spotifyRefreshToken: String
    let expiresAt: Date
}

struct GenerateClientTokenResponse: Codable {
    let customToken: String
}

class SpotifySessionManagerDelegate: NSObject, SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        SpotifyTokenAPI.postToken(reqParams:
                .init(spotifyAccessToken: session.accessToken,
                      spotifyRefreshToken: session.refreshToken,
                      expiresAt: session.expirationDate
                     )
        )
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("didRenew session")
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("~~~ didFailWith... sessions error: \(error)")
    }
}
