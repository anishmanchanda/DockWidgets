import Foundation
import Cocoa

// Move NowPlayingInfo struct to the top-level scope so it is visible everywhere
struct NowPlayingInfo {
    let title: String
    let artist: String
    let album: String
    let app: AppleScriptMediaController.MediaApp
    
    var displayText: String {
        if album.isEmpty {
            return "\(title) – \(artist)"
        } else {
            return "\(title) – \(artist) (\(album))"
        }
    }
}

protocol AppleScriptMediaControllerDelegate: AnyObject {
    func mediaController(_ controller: AppleScriptMediaController, didUpdateNowPlaying info: NowPlayingInfo?)
    func mediaController(_ controller: AppleScriptMediaController, didUpdatePlaybackState isPlaying: Bool)
}

class AppleScriptMediaController: ObservableObject {
    weak var delegate: AppleScriptMediaControllerDelegate?
    
    @Published var currentTrack: NowPlayingInfo?
    @Published var isPlaying = false
    @Published var currentApp: MediaApp = .none
    
    private var updateTimer: Timer?
    
    enum MediaApp: String, CaseIterable {
        case music = "Music"
        case spotify = "Spotify"
        case none = "None"
        
        var displayName: String {
            switch self {
            case .music: return "Apple Music"
            case .spotify: return "Spotify"
            case .none: return "No music playing"
            }
        }
    }
    
    func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
        updateNowPlaying() // Initial update
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateNowPlaying() {
        // Check Apple Music first
        if let musicInfo = getMusicInfo() {
            currentTrack = musicInfo
            currentApp = .music
            isPlaying = isMusicPlaying()
            delegate?.mediaController(self, didUpdateNowPlaying: musicInfo)
            delegate?.mediaController(self, didUpdatePlaybackState: isPlaying)
            return
        }
        
        // Then check Spotify
        if let spotifyInfo = getSpotifyInfo() {
            currentTrack = spotifyInfo
            currentApp = .spotify
            isPlaying = isSpotifyPlaying()
            delegate?.mediaController(self, didUpdateNowPlaying: spotifyInfo)
            delegate?.mediaController(self, didUpdatePlaybackState: isPlaying)
            return
        }
        
        // No music playing
        currentTrack = nil
        currentApp = .none
        isPlaying = false
        delegate?.mediaController(self, didUpdateNowPlaying: nil)
        delegate?.mediaController(self, didUpdatePlaybackState: false)
    }
    
    // MARK: - Apple Music
    
    private func getMusicInfo() -> NowPlayingInfo? {
        let script = """
        tell application "Music"
            if it is running and player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                return trackName & "|||" & artistName & "|||" & albumName
            end if
        end tell
        return ""
        """
        
        guard let result = executeAppleScript(script), !result.isEmpty else {
            return nil
        }
        
        let components = result.components(separatedBy: "|||")
        guard components.count >= 2 else { return nil }
        
        return NowPlayingInfo(
            title: components[0],
            artist: components[1],
            album: components.count > 2 ? components[2] : "",
            app: .music
        )
    }
    
    private func isMusicPlaying() -> Bool {
        let script = """
        tell application "Music"
            if it is running then
                return (player state is playing)
            end if
        end tell
        return false
        """
        
        return executeAppleScript(script) == "true"
    }
    
    // MARK: - Spotify
    
    private func getSpotifyInfo() -> NowPlayingInfo? {
        let script = """
        tell application "Spotify"
            if it is running and player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                return trackName & "|||" & artistName
            end if
        end tell
        return ""
        """
        
        guard let result = executeAppleScript(script), !result.isEmpty else {
            return nil
        }
        
        let components = result.components(separatedBy: "|||")
        guard components.count >= 2 else { return nil }
        
        return NowPlayingInfo(
            title: components[0],
            artist: components[1],
            album: "",
            app: .spotify
        )
    }
    
    private func isSpotifyPlaying() -> Bool {
        let script = """
        tell application "Spotify"
            if it is running then
                return (player state is playing)
            end if
        end tell
        return false
        """
        
        return executeAppleScript(script) == "true"
    }
    
    // MARK: - Media Controls
    
    func playPause() {
        switch currentApp {
        case .music:
            executeAppleScript("tell application \"Music\" to playpause")
        case .spotify:
            executeAppleScript("tell application \"Spotify\" to playpause")
        case .none:
            break
        }
    }
    
    
    func nextTrack() {
        switch currentApp {
        case .music:
            executeAppleScript("tell application \"Music\" to next track")
        case .spotify:
            executeAppleScript("tell application \"Spotify\" to next track")
        case .none:
            break
        }
    }
    
    func previousTrack() {
        switch currentApp {
        case .music:
            executeAppleScript("tell application \"Music\" to previous track")
        case .spotify:
            executeAppleScript("tell application \"Spotify\" to previous track")
        case .none:
            break
        }
    }
    
    // MARK: - AppleScript Execution
    
    private func executeAppleScript(_ script: String) -> String? {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        let result = appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error: \(error)")
            return nil
        }
        
        return result?.stringValue
    }
}
