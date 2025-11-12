import Foundation

struct PlexSession: Codable {
    let MediaContainer: MediaContainer?
}

struct MediaContainer: Codable {
    let Metadata: [Track]?
}

struct Track: Codable, Identifiable {
    let id: String?
    let type: String?
    let title: String?
    let grandparentTitle: String?
    let originalTitle: String?
    let parentTitle: String?
    let thumb: String?
    let parentThumb: String?
    let grandparentThumb: String?
    let duration: Int?
    let viewOffset: Int?
    let sessionKey: String?
    let Player: Player?
    let Session: Session?

    enum CodingKeys: String, CodingKey {
        case type, title, thumb, duration, viewOffset, sessionKey
        case id = "ratingKey"
        case grandparentTitle, originalTitle, parentTitle
        case parentThumb, grandparentThumb
        case Player, Session
    }
}

struct Player: Codable {
    let state: String?
    let machineIdentifier: String?
    let address: String?
    let port: String?
    let `protocol`: String?
    let product: String?
}

struct Session: Codable {
    let id: String?
}

struct NowPlaying: Identifiable {
    let id: String // Use track's ratingKey as stable ID
    let title: String
    let artist: String
    let album: String
    let albumArtUrl: String?
    let state: String
    let duration: Int
    let viewOffset: Int
    let sessionKey: String?
    let playerAddress: String?
    let playerPort: String?
    let playerProtocol: String?
    let machineIdentifier: String?
}

@MainActor
class PlexAPI: ObservableObject {
    @Published var nowPlaying: NowPlaying?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let serverUrl: String
    private let token: String
    private let clientIdentifier: String
    nonisolated(unsafe) private var updateTimer: Timer?

    init(serverUrl: String, token: String) {
        self.serverUrl = serverUrl
        self.token = token
        self.clientIdentifier = "plex-desktop-widget-\(Date().timeIntervalSince1970)"
    }

    func startUpdating(interval: TimeInterval = 2.0) {
        // Initial fetch
        Task { @MainActor in
            await fetchNowPlaying()
        }

        // Start timer for periodic updates - ensure it runs on main thread
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.fetchNowPlaying()
            }
        }
    }

    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func fetchNowPlaying() async {
        guard let url = URL(string: "\(serverUrl)/status/sessions") else {
            errorMessage = "Invalid server URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                isLoading = false
                return
            }

            if httpResponse.statusCode == 200 {
                let session = try JSONDecoder().decode(PlexSession.self, from: data)

                if let tracks = session.MediaContainer?.Metadata {
                    // Find first playing or paused music track
                    if let playingTrack = tracks.first(where: { track in
                        track.type == "track" &&
                        (track.Player?.state == "playing" || track.Player?.state == "paused")
                    }) {
                        let playerAddr = playingTrack.Player?.address
                        let playerPort = playingTrack.Player?.port
                        let playerProtocol = playingTrack.Player?.protocol
                        let machineId = playingTrack.Player?.machineIdentifier

                        nowPlaying = NowPlaying(
                            id: playingTrack.id ?? UUID().uuidString,
                            title: playingTrack.title ?? "Unknown Track",
                            artist: playingTrack.originalTitle ?? playingTrack.grandparentTitle ?? "Unknown Artist",
                            album: playingTrack.parentTitle ?? "Unknown Album",
                            albumArtUrl: getAlbumArtUrl(from: playingTrack),
                            state: playingTrack.Player?.state ?? "playing",
                            duration: playingTrack.duration ?? 0,
                            viewOffset: playingTrack.viewOffset ?? 0,
                            sessionKey: playingTrack.sessionKey ?? playingTrack.Session?.id,
                            playerAddress: playerAddr,
                            playerPort: playerPort,
                            playerProtocol: playerProtocol,
                            machineIdentifier: machineId
                        )

                        errorMessage = nil
                    } else {
                        nowPlaying = nil
                        errorMessage = nil
                    }
                } else {
                    nowPlaying = nil
                    errorMessage = nil
                }
                isLoading = false
            } else if httpResponse.statusCode == 401 {
                errorMessage = "Invalid Plex token"
                nowPlaying = nil
                isLoading = false
            } else {
                errorMessage = "Server returned status \(httpResponse.statusCode)"
                nowPlaying = nil
                isLoading = false
            }
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
            nowPlaying = nil
            isLoading = false
        }
    }

    private func getAlbumArtUrl(from track: Track) -> String? {
        let thumbPath = track.thumb ?? track.parentThumb ?? track.grandparentThumb
        guard let thumbPath = thumbPath else { return nil }
        // Return URL without token - token will be added via HTTP header in image loading
        return "\(serverUrl)\(thumbPath)"
    }

    // Helper method to fetch album art with token in header
    func fetchAlbumArt(url: String) async -> Data? {
        guard let imageUrl = URL(string: url) else { return nil }

        var request = URLRequest(url: imageUrl)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.timeoutInterval = 10.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            return data
        } catch {
            return nil
        }
    }

    nonisolated deinit {
        // Must invalidate timer synchronously without MainActor since deinit is nonisolated
        // This is safe because we're just invalidating the timer, not accessing @Published properties
        updateTimer?.invalidate()
    }
}
