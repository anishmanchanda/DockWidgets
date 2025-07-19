import SwiftUI

class NowPlayingWidget: BaseWidget {
    private var mediaController: AppleScriptMediaController?
    
    override init(position: CGPoint, size: CGSize = CGSize(width: 320, height: 120)) {
        super.init(position: position, size: size)
        setupMediaController()
    }
    
    private func setupMediaController() {
        mediaController = AppleScriptMediaController()
        mediaController?.delegate = self
        mediaController?.requestPermissionsExplicitly()
        mediaController?.startMonitoring()
    }
    
    override func createView() -> AnyView {
        AnyView(NowPlayingView(mediaController: mediaController))
    }
}

// MARK: - Media Controller Delegate
extension NowPlayingWidget: AppleScriptMediaControllerDelegate {
    func mediaController(_ controller: AppleScriptMediaController, didUpdateNowPlaying info: NowPlayingInfo?) {
        // The view will automatically update through @ObservedObject
        //print("Widget received now playing update: \(info?.displayText ?? "No music")")
    }
    
    func mediaController(_ controller: AppleScriptMediaController, didUpdatePlaybackState isPlaying: Bool) {
        // The view will automatically update through @ObservedObject
        //print("Widget received playback state update: \(isPlaying ? "Playing" : "Paused")")
    }
}

struct NowPlayingView: View {
    @ObservedObject var mediaController: AppleScriptMediaController
    
    init(mediaController: AppleScriptMediaController?) {
        self.mediaController = mediaController ?? AppleScriptMediaController()
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Track Information
            if let track = mediaController.currentTrack {
                VStack(spacing: 2) {
                    Text(track.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(track.artist)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                }
            } else {
                Text("No music playing")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Control Buttons
            if mediaController.currentApp != .none {
                HStack(spacing: 10) {
                    Button(action: {
                        mediaController.previousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onTapGesture {
                        mediaController.previousTrack()
                    }
                    
                    Button(action: {
                        mediaController.playPause()
                    }) {
                        Image(systemName: mediaController.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onTapGesture {
                        mediaController.playPause()
                    }
                    
                    Button(action: {
                        mediaController.nextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onTapGesture {
                        mediaController.nextTrack()
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear) // Completely transparent background
        .cornerRadius(8)
    }
}

// MARK: - Button Style for better interaction
struct MediaControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
