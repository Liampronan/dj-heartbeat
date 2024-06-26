import SwiftUI
import MediaPlayer
import MusicKit

struct AppleMusicView: View {
    enum ViewState {
        case loading
        case loaded(isLoggedIn: Bool)
    }
    @State var state = ViewState.loading
    @State var authMgr = MusicAuthorizationManager()
    
    var body: some View {
        VStack {
            switch state {
            case .loading:
                ProgressView()
            case .loaded(let isLoggedIn):
                if isLoggedIn {
                    Text("is logged in")
                        .padding()
                } else {
                    Button("Authorize Apple Music") {
                        authorizeAppleMusic()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                await authMgr.requestMusicAuthorization()
                requestAppleMusicAuthorization()
            }
            
        }
    }
    
    private func requestAppleMusicAuthorization() {
        switch MPMediaLibrary.authorizationStatus() {
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { status in
                if status == .authorized {
                    print("Apple Music authorization granted")
                } else {
                    print("Apple Music authorization denied")
                }
            }
        case .authorized:
            print("Apple Music already authorized")
            Task {
                let developerToken = try await DefaultMusicTokenProvider().developerToken(options: .ignoreCache)
                print("developerToken", developerToken)
                let userToken = try await musicUserTokenProvider.userToken(for: developerToken, options: .ignoreCache)
                print("userToken", userToken)
                do {
                    try await fetchRecentlyPlayedSongs(userToken: userToken)
                } catch {
                    print(error)
                }
                
            }
        default:
            print("Apple Music authorization denied or restricted")
        }
    }
    
    private let musicUserTokenProvider = MusicUserTokenProvider()
    private func authorizeAppleMusic() {
        Task {
            do {
                let token = await MusicAuthorization.request()
                if token == .authorized {
                    // TODO: .ignoreCache ? what does this do? is there another option
                    let developerToken = try await DefaultMusicTokenProvider().developerToken(options: .ignoreCache)
                    let musicUserToken = try await musicUserTokenProvider.userToken(for: developerToken, options: .ignoreCache)
                    try await fetchRecentlyPlayedSongs(userToken: musicUserToken)
                }
            } catch {
                print("Error authorizing Apple Music: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchRecentlyPlayedSongs(userToken: String) async throws {
        // THIS WORKS BUT SONG NEEDS TO BE IN LIBRARY AND IT ONLY WORKED AFTER I RESTARTED THE APP
        // cons: requires app to be open
        /*var request = MusicLibraryRequest<Song>()
        request.filter(matching: \.id, equalTo: "i.JL1YrdrU3rxBqp")
        let response = try await request.response()

        guard let song = response.items.first else { return }

        print("audioVariants: \(String(describing: song.audioVariants))")
        print("isAppleDigitalMaster: \(String(describing: song.isAppleDigitalMaster))")
        print("lastPlayedDate: \(String(describing: song.lastPlayedDate))")
        print("libraryAddedDate: \(String(describing: song.libraryAddedDate))")
        print("playCount: \(String(describing: song.playCount))")
        print("title: \(String(describing: song.title))")
        */
        
        // APPROACH 2
        // Monitor queue on phone. pull data from currentEntry. Track that way
         // -> Pros: simple and works
        // -> Cons: requires app to be open? (maybe there is a way around this.)
        // -> UX:
            // - User starts workout from app
            // - [maybe] User starts playlist via app (to ensure app is open)
        // -> Questions:
        // does it work on watch? Maybe who cares.
        var request2 = MusicLibraryRequest<Song>()
        request2.sort(by: \.lastPlayedDate, ascending: false)
        request2.limit = 10
        let response2 = try await request2.response()
        print(response2.items.map { $0.albumTitle ?? "" + " " + $0.artistName })
        print("lastPlayedDate: ")
//        SystemMusicPlayer.shared.queue.in
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.id)
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.startTime)
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.title)
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.subtitle)
        print("queue is: ", SystemMusicPlayer.shared.queue.currentEntry?.item)
        
        // TODO:
        // 0. can we add to music libary - any random song
        // 1. can we add to music library - any song upcoming song
        // 2. can we pull form queue and add to library
//        MusicLibraryRequest
        let searchRequest = MusicCatalogSearchRequest(term: "same old love", types: [Song.self])
        do {
            let searchResponse = try await searchRequest.response()
            
            // Process the search response to get the song ID
            if let song = searchResponse.songs.first {
                let songID = song.id
                print("Found song ID: \(songID)")
                
                // Proceed to add the song to the library
//                var addRequest = MusicLibraryRequest<Song>()
//                addRequest.filter(matching: \.id, equalTo: songID)
//                addRequest.items = [songID]
                
                // Add the song to the library
                try await MusicLibrary.shared.add(song)
            } else {
                print("Song not found in catalog")
            }
            } catch {
                print("Error searching for song: \(error)")
            }
        
//        let url = URL(string: "https://api.music.apple.com/v1/me/recent/played/tracks")! ?include=songs
        let url = URL(string: "https://api.music.apple.com/v1/me/library/songs/i.JL1YrdrU3rxBqp?extend=lastPlayedAt")!
//        let url = URL(string: "https://api.music.apple.com/v1/me/library/search?term=funkadelic&types=library-songs")! // -> can search library for song *only if it's in library* -> so could auto-add to lib on listen?
//        /v1/catalog/us/songs/1440785707
//        1440785707
        
//        var request = URLRequest(url: url)
//        
//        let developerToken = try await DefaultMusicTokenProvider().developerToken(options: .ignoreCache)
//        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
//        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error fetching recently played songs: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            print("data is", String(data: data, encoding: .utf8))
//            
//            print("data fetched")
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    // Process the JSON response to get the list of songs and timestamps
//                    if let data = json["data"] as? [[String: Any]] {
//                        for item in data {
//                            if let attributes = item["attributes"] as? [String: Any],
////                               let timestamp = attributes["playParams"]?["id"] as? String,  // Assuming `playParams` contains timestamp information
//                               let song = attributes["name"] as? String {
////                                print("Song: \(song), Played At: \(timestamp)")
//                            }
//                        }
//                    }
//                }
//            } catch {
//                print("Error parsing JSON: \(error.localizedDescription)")
//            }
//        }
//        task.resume()
    }
}


class MusicAuthorizationManager: ObservableObject {
    @Published var isAuthorizedForMusicKit = false
//    @Published var musicKitError:

    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()

        switch status {
        case .authorized:
            isAuthorizedForMusicKit = true
        case .restricted:
            print("error")
        case .notDetermined:
            print("error")
        case .denied:
            print("error")
        @unknown default:
            print("error")
        }
    }
}
