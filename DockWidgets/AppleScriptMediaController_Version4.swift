import Foundation
import OSLog

protocol AppleScriptMediaControllerDelegate: AnyObject {
    func mediaController(_ controller: AppleScriptMediaController, didUpdateNowPlaying info: NowPlayingInfo?)
    func mediaController(_ controller: AppleScriptMediaController, didUpdatePlaybackState isPlaying: Bool)
}

class AppleScriptMediaController {
    weak var delegate: AppleScriptMediaControllerDelegate?
    private let logger = Logger(subsystem: "com.dockwidgets", category: "AppleScriptMediaController")
    private var monitoringTimer: Timer?
    private var lastPlayingInfo: NowPlayingInfo?
    private var lastPlayingState = false
    
    enum MediaApp: String, CaseIterable {
        case music = "Music"
        case spotify = "Spotify"
    }
    
    func startMonitoring() {
        logger.info("Starting media monitoring")
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkNowPlaying()
        }
    }
    
    func stopMonitoring() {
        logger.info("Stopping media monitoring")
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func checkNowPlaying() {
        // Check each app for currently playing media
        var currentInfo: NowPlayingInfo?
        var isPlaying = false
        
        for app in MediaApp.allCases {
            if let info = getNowPlayingInfo(from: app) {
                currentInfo = info
                isPlaying = true
                break // Prioritize the first app found playing
            }
        }
        
        // Only notify if something changed
        if currentInfo?.title != lastPlayingInfo?.title ||
           currentInfo?.artist != lastPlayingInfo?.artist ||
           isPlaying != lastPlayingState {
            
            lastPlayingInfo = currentInfo
            lastPlayingState = isPlaying
            
            delegate?.mediaController(self, didUpdateNowPlaying: currentInfo)
            delegate?.mediaController(self, didUpdatePlaybackState: isPlaying)
        }
    }
    
    private func getNowPlayingInfo(from app: MediaApp) -> NowPlayingInfo? {
        let script: String
        
        switch app {
        case .music:
            script = """
            tell application "Music"
                if it is running and player state is playing then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    return trackName & " – " & artistName & " (" & albumName & ")" & "|" & trackName & "|" & artistName & "|" & albumName
                end if
            end tell
            return ""
            """
        case .spotify:
            script = """
            tell application "Spotify"
                if it is running and player state is playing then
                    set trackName to name of current track
                    set artistName to artist of current track
                    return trackName & " – " & artistName & "|" & trackName & "|" & artistName & "|"
                end if
            end tell
            return ""
            """
        }
        
        guard let result = executeAppleScript(script), !result.isEmpty else {
            return nil
        }
        
        let components = result.components(separatedBy: "|")
        guard components.count >= 3 else {
            return nil
        }
        
        let info = NowPlayingInfo(
            title: components[1],
            artist: components[2],
            album: components.count > 3 ? components[3] : "",
            artworkURL: nil,
            sourceApp: app.rawValue
        )
        
        logger.info("Found playing media in \(app.rawValue): \(info.title) by \(info.artist)")
        return info
    }
    
    func playPause() {
        // Try to control the currently playing app
        for app in MediaApp.allCases {
            if isAppPlaying(app) {
                sendPlayPauseCommand(to: app)
                return
            }
        }
        
        // If no app is playing, try to start the first available app
        for app in MediaApp.allCases {
            if isAppRunning(app) {
                sendPlayPauseCommand(to: app)
                return
            }
        }
        
        logger.warning("No compatible media app found for play/pause")
    }
    
    func nextTrack() {
        for app in MediaApp.allCases {
            if isAppPlaying(app) {
                sendNextCommand(to: app)
                return
            }
        }
        logger.warning("No compatible media app found for next track")
    }
    
    func previousTrack() {
        for app in MediaApp.allCases {
            if isAppPlaying(app) {
                sendPreviousCommand(to: app)
                return
            }
        }
        logger.warning("No compatible media app found for previous track")
    }
    
    private func isAppRunning(_ app: MediaApp) -> Bool {
        let script = """
        tell application "System Events"
            return (name of processes) contains "\(app.rawValue)"
        end tell
        """
        
        guard let result = executeAppleScript(script) else { return false }
        return result.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }
    
    private func isAppPlaying(_ app: MediaApp) -> Bool {
        let script: String
        
        switch app {
        case .music:
            script = """
            tell application "Music"
                if it is running then
                    return player state is playing
                else
                    return false
                end if
            end tell
            """
        case .spotify:
            script = """
            tell application "Spotify"
                if it is running then
                    return player state is playing
                else
                    return false
                end if
            end tell
            """
        }
        
        guard let result = executeAppleScript(script) else { return false }
        return result.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }
    
    private func sendPlayPauseCommand(to app: MediaApp) {
        let script = """
        tell application "\(app.rawValue)"
            playpause
        end tell
        """
        
        executeAppleScript(script)
        logger.info("Sent play/pause command to \(app.rawValue)")
    }
    
    private func sendNextCommand(to app: MediaApp) {
        let script = """
        tell application "\(app.rawValue)"
            next track
        end tell
        """
        
        executeAppleScript(script)
        logger.info("Sent next track command to \(app.rawValue)")
    }
    
    private func sendPreviousCommand(to app: MediaApp) {
        let script = """
        tell application "\(app.rawValue)"
            previous track
        end tell
        """
        
        executeAppleScript(script)
        logger.info("Sent previous track command to \(app.rawValue)")
    }
    
    private func executeAppleScript(_ script: String) -> String? {
        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        
        guard let output = appleScript?.executeAndReturnError(&errorInfo) else {
            if let error = errorInfo {
                logger.error("AppleScript error: \(error)")
            }
            return nil
        }
        
        return output.stringValue
    }
    
    deinit {
        stopMonitoring()
    }
}