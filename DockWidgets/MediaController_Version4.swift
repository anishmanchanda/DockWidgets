import Foundation
import MediaPlayer

protocol MediaControllerDelegate: AnyObject {
    func mediaController(_ controller: MediaController, didUpdateNowPlaying info: NowPlayingInfo?)
    func mediaController(_ controller: MediaController, didUpdatePlaybackState isPlaying: Bool)
}

class MediaController {
    weak var delegate: MediaControllerDelegate?
    private var nowPlayingInfoCenter: MPNowPlayingInfoCenter
    private var remoteCommandCenter: MPRemoteCommandCenter
    private var monitoringTimer: Timer?
    
    init() {
        nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        remoteCommandCenter = MPRemoteCommandCenter.shared()
    }
    
    func startMonitoring() {
        // Set up remote command center
        remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
        
        // Monitor now playing info changes with a timer
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.nowPlayingInfoDidChange()
        }
    }
    
    private func nowPlayingInfoDidChange() {
        let info = nowPlayingInfoCenter.nowPlayingInfo
        
        guard let title = info?[MPMediaItemPropertyTitle] as? String,
              let artist = info?[MPMediaItemPropertyArtist] as? String else {
            delegate?.mediaController(self, didUpdateNowPlaying: nil)
            return
        }
        
        let album = info?[MPMediaItemPropertyAlbumTitle] as? String ?? ""
        // TODO: Handle artwork conversion to URL if needed
        
        let nowPlayingInfo = NowPlayingInfo(
            title: title,
            artist: artist,
            album: album,
            artworkURL: nil // Convert artwork to URL if needed
        )
        
        delegate?.mediaController(self, didUpdateNowPlaying: nowPlayingInfo)
    }
    
    func playPause() {
        // Send play/pause command
        if isPlaying() {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        // Send play command to the system
        delegate?.mediaController(self, didUpdatePlaybackState: true)
    }
    
    func pause() {
        // Send pause command to the system
        delegate?.mediaController(self, didUpdatePlaybackState: false)
    }
    
    func nextTrack() {
        // Send next track command to the system
    }
    
    func previousTrack() {
        // Send previous track command to the system
    }
    
    private func isPlaying() -> Bool {
        // Check if there's currently playing media
        return nowPlayingInfoCenter.nowPlayingInfo != nil
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    deinit {
        stopMonitoring()
    }
}