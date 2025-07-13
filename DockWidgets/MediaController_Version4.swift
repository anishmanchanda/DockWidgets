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

class ViewController: NSViewController {
    private var mediaController: AppleScriptMediaController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaController = AppleScriptMediaController()
        mediaController?.delegate = self
        
        mediaController?.requestPermissionsExplicitly()
        
        mediaController?.startMonitoring() // Start monitoring here
    }
}

extension ViewController: AppleScriptMediaControllerDelegate {
    func mediaController(_ controller: AppleScriptMediaController, didUpdateNowPlaying info: NowPlayingInfo?) {
        print("Now playing info updated: \(info?.displayText ?? "No music playing")")
    }

    func mediaController(_ controller: AppleScriptMediaController, didUpdatePlaybackState isPlaying: Bool) {
        print("Playback state updated: \(isPlaying ? "Playing" : "Paused")")
    }
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
    func requestPermissionsExplicitly() {
        // Force permission dialog by directly accessing the applications
        let musicPermissionScript = """
        tell application "System Events"
            tell process "Music"
                return "permission requested"
            end tell
        end tell
        """
        
        let spotifyPermissionScript = """
        tell application "System Events"
            tell process "Spotify"
                return "permission requested"
            end tell
        end tell
        """
        
        // These will trigger permission dialogs
        executeAppleScript(musicPermissionScript)
        executeAppleScript(spotifyPermissionScript)
    }
    func startMonitoring() {
        print("startMonitoring called")
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
        print("updateNowPlaying called")
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
        if application "Music" is running then
            tell application "Music"
                try
                    if current track exists then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        return trackName & "|||" & artistName & "|||" & albumName
                    else
                        return "no track"
                    end if
                on error errMsg
                    return "error: " & errMsg
                end try
            end tell
        else
            return "not running"
        end if
        """
        
        guard let result = executeAppleScript(script), !result.isEmpty else {
            return nil
        }
        
        if result == "no track" || result.hasPrefix("error") || result == "not running" {
            print("Music info: \(result)")
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
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    if current track exists then
                        set trackName to name of current track
                        set artistName to artist of current track
                        return trackName & "|||" & artistName
                    else
                        return "no track"
                    end if
                on error errMsg
                    return "error: " & errMsg
                end try
            end tell
        else
            return "not running"
        end if
        """
        
        guard let result = executeAppleScript(script), !result.isEmpty else {
            return nil
        }
        
        if result == "no track" || result.hasPrefix("error") || result == "not running" {
            print("Spotify info: \(result)")
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
        print("playPause called")
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
    
    @discardableResult
    private func executeAppleScript(_ script: String) -> String? {
        print("Executing AppleScript:")
        
        // Create the AppleScript
        guard let appleScript = NSAppleScript(source: script) else {
            print("Failed to create AppleScript")
            return nil
        }
        
        var error: NSDictionary?
        
        // Execute the script
        let result = appleScript.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error: \(error)")
            
            // Check if it's a permission error
            if let errorCode = error[NSAppleScript.errorNumber] as? Int {
                switch errorCode {
                case -1743: // errAEEventNotPermitted
                    print("Permission denied - user needs to grant automation access")
                    // You could show an alert here directing user to System Preferences
                    DispatchQueue.main.async {
                        self.showPermissionAlert()
                    }
                case -1728: // errAENoSuchObject
                    print("Application not found or not running")
                default:
                    print("AppleScript error code: \(errorCode)")
                }
            }
            
            let errorInfo = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            print("Error details: \(errorInfo)")
            return nil
        }
        
        
        let resultString = result.stringValue ?? ""
        print("AppleScript result: \(resultString)")
        return resultString.isEmpty ? nil : resultString
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permission Required"
        alert.informativeText = "This app needs permission to control Music and Spotify. Please go to System Preferences > Security & Privacy > Privacy > Automation and enable access for this app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Open System Preferences to Automation section
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
            NSWorkspace.shared.open(url)
        }
    }
}
