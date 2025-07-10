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
        
        // Monitor now playing info changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingInfoDidChange),
            name: .MPNowPlayingInfoDidChange,
            object: nil
        )
    }
    
    @objc private func nowPlayingInfoDidChange() {
        let info = nowPlayingInfoCenter.nowPlayingInfo
        
        guard let title = info?[MPMediaItemPropertyTitle] as? String,
              let artist = info?[MPMediaItemPropertyArtist] as? String else {
            delegate?.mediaController(self, didUpdateNowPlaying: nil)
            return
        }
        
        let album = info?[MPMediaItemPropertyAlbumTitle] as? String ?? ""
        let artwork = info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork
        
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
        remoteCommandCenter.playCommand.perform()
        delegate?.mediaController(self, didUpdatePlaybackState: true)
    }
    
    func pause() {
        remoteCommandCenter.pauseCommand.perform()
        delegate?.mediaController(self, didUpdatePlaybackState: false)
    }
    
    func nextTrack() {
        remoteCommandCenter.nextTrackCommand.perform()
    }
    
    func previousTrack() {
        remoteCommandCenter.previousTrackCommand.perform()
    }
    
    private func isPlaying() -> Bool {
        // Check current playback state
        return nowPlayingInfoCenter.playbackState == .playing
    }
}