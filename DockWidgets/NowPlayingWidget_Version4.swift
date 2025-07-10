import SwiftUI
import OSLog

class NowPlayingWidget: BaseWidget {
    @Published var nowPlayingInfo: NowPlayingInfo?
    @Published var isPlaying = false
    private let mediaController = AppleScriptMediaController()
    private let logger = Logger(subsystem: "com.dockwidgets", category: "NowPlayingWidget")
    
    override init(position: CGPoint, size: CGSize = CGSize(width: 160, height: 50)) {
        super.init(position: position, size: size)
        setupMediaController()
    }
    
    private func setupMediaController() {
        logger.info("Setting up AppleScript media controller")
        mediaController.delegate = self
        mediaController.startMonitoring()
    }
    
    override func createView() -> AnyView {
        AnyView(NowPlayingView(widget: self))
    }
    
    func playPause() {
        logger.info("Play/pause button pressed")
        mediaController.playPause()
    }
    
    func nextTrack() {
        logger.info("Next track button pressed")
        mediaController.nextTrack()
    }
    
    func previousTrack() {
        logger.info("Previous track button pressed")
        mediaController.previousTrack()
    }
    
    deinit {
        mediaController.stopMonitoring()
    }
}

extension NowPlayingWidget: AppleScriptMediaControllerDelegate {
    func mediaController(_ controller: AppleScriptMediaController, didUpdateNowPlaying info: NowPlayingInfo?) {
        DispatchQueue.main.async {
            self.nowPlayingInfo = info
        }
    }
    
    func mediaController(_ controller: AppleScriptMediaController, didUpdatePlaybackState isPlaying: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = isPlaying
        }
    }
}

struct NowPlayingView: View {
    @ObservedObject var widget: NowPlayingWidget
    @ObservedObject private var settings = UserSettings.shared
    
    var body: some View {
        HStack(spacing: 8) {
            if let info = widget.nowPlayingInfo {
                // Album artwork placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        // Show app icon or music note
                        Image(systemName: info.sourceApp == "Spotify" ? "s.circle.fill" : "music.note")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title)
                        .font(.system(size: getFontSize() * 0.8))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(info.artist)
                            .font(.system(size: getFontSize() * 0.6))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                            .lineLimit(1)
                        if let sourceApp = info.sourceApp {
                            Text("• \(sourceApp)")
                                .font(.system(size: getFontSize() * 0.5))
                                .foregroundColor(.white.opacity(0.6))
                                .shadow(color: .black, radius: 1, x: 0, y: 0)
                        }
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 8) {
                    Button(action: { widget.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: getFontSize() * 0.7))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { widget.playPause() }) {
                        Image(systemName: widget.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: getFontSize() * 0.7))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { widget.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: getFontSize() * 0.7))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: getFontSize() * 0.8))
                        .foregroundColor(.white.opacity(0.6))
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                    
                    Text("No music playing")
                        .font(.system(size: getFontSize() * 0.7))
                        .foregroundColor(.white.opacity(0.6))
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
        )
        .opacity(settings.widgetOpacity)
    }
    
    private func getFontSize() -> CGFloat {
        // Base font size for now playing widget, scaled by widget height
        let baseSize: CGFloat = 16
        let scaleFactor = widget.size.height / 50  // 50 is our base height
        return max(baseSize * scaleFactor, 12)  // Minimum 12pt font
    }
}

struct NowPlayingInfo {
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let sourceApp: String?
    
    init(title: String, artist: String, album: String, artworkURL: URL?, sourceApp: String? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkURL = artworkURL
        self.sourceApp = sourceApp
    }
}