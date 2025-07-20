import Foundation
import SwiftUI
import Combine

class WidgetManager: ObservableObject {
    @Published var widgets: [BaseWidget] = []
    private let window: OverlayWindow
    private let settings = UserSettings.shared
    private let dockPositionManager = DockPositionManager.shared
    private var settingsSubscription: AnyCancellable?
    private var mediaController: AppleScriptMediaController?
    
    init(window: OverlayWindow) {
        self.window = window
        dockPositionManager.updateDockInfo() // Update Dock info when initializing
        
        setupDefaultWidgets()
        startDebugTimer()
        setupMediaController()
    }
    
    private func setupMediaController() {
        mediaController = AppleScriptMediaController()
        mediaController?.delegate = self
        mediaController?.startMonitoring()
        print("🎯 MediaController: Monitoring started")
    }
    
    
    
    private func setupDefaultWidgets() {
        // Create widgets once with fixed positioning
        createFixedPositionWidgets()
        print("🎯 WidgetManager: Created \(widgets.count) widgets with fixed positioning")
    }
    
    private func createFixedPositionWidgets() {
        widgets.removeAll()
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let dockFrame = dockPositionManager.dockFrame
        
        let positions = calculateFixedWidgetPositions(screenFrame: screenFrame, dockFrame: dockFrame)
        
        let widgetSize = CGSize(width: 140, height: 60)
        
        // Reintroduce clock widget creation logic
        let clockWidget = FlipClockWidget(
            position: positions.clockPosition,
            size: widgetSize
        )
        clockWidget.isVisible = true
        widgets.append(clockWidget)
        
        let weatherWidget = WeatherWidget(
            position: positions.weatherPosition,
            size: widgetSize
        )
        //weatherWidget.isVisible = settings.showWeather
        widgets.append(weatherWidget)
        
        let musicWidget = NowPlayingWidget(
            position: positions.musicPosition,
            size: widgetSize
        )
        //musicWidget.isVisible = settings.showMusic
        widgets.append(musicWidget)
    }
    
    private func calculateFixedWidgetPositions(screenFrame: NSRect, dockFrame: NSRect) -> (clockPosition: CGPoint, weatherPosition: CGPoint, musicPosition: CGPoint) {
        let widgetSize = CGSize(width: 140, height: 60)
        let verticalCenter = (dockFrame.minY + dockFrame.height) / 2
        let leftZoneCenter = (screenFrame.maxX) / 4
        let clockPosition = CGPoint(x: leftZoneCenter - widgetSize.width, y: verticalCenter)
        
        let rightZoneStart = dockFrame.maxX
        let weatherX = rightZoneStart + 10
        let musicX = rightZoneStart + ((screenFrame.maxX - rightZoneStart) / 2)
        
        let weatherPosition = CGPoint(x: weatherX, y: verticalCenter)
        let musicPosition = CGPoint(x: musicX, y: verticalCenter)
        
        return (clockPosition, weatherPosition, musicPosition)
    }
    
    private func startDebugTimer() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            
        }
    }
}

extension WidgetManager: AppleScriptMediaControllerDelegate {
    func mediaController(_ controller: AppleScriptMediaController, didUpdateNowPlaying info: NowPlayingInfo?) {
        
    }

    func mediaController(_ controller: AppleScriptMediaController, didUpdatePlaybackState isPlaying: Bool) {
        
    }
}
