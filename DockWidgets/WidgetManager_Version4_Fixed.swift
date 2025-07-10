import Foundation
import SwiftUI
import Combine

class WidgetManager: ObservableObject {
    @Published var widgets: [BaseWidget] = []
    private let window: OverlayWindow
    private let settings = UserSettings.shared
    private let dockPositionManager = DockPositionManager.shared
    private var settingsSubscription: AnyCancellable?
    
    init(window: OverlayWindow) {
        self.window = window
        setupObservers()
        setupDefaultWidgets()
        startDebugTimer()
    }
    
    private func setupObservers() {
        // Only observe settings changes, not dock position changes
        settingsSubscription = NotificationCenter.default.publisher(for: .settingsChanged)
            .sink { [weak self] _ in
                self?.updateWidgetVisibility()
            }
        
        print("🎯 WidgetManager: Dynamic dock adjustment disabled, only settings changes monitored")
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
        
        print("🎯 Screen frame: \(screenFrame)")
        print("🎯 Dock frame: \(dockFrame)")
        
        // Calculate positions based on dock position
        let positions = calculateFixedWidgetPositions(screenFrame: screenFrame, dockFrame: dockFrame)
        
        // Fixed widget dimensions (no dynamic sizing based on dock magnification)
        let widgetSize = CGSize(width: 140, height: 60)
        
        // Create clock widget - always visible
        let clockWidget = FlipClockWidget(
            position: positions.clockPosition,
            size: widgetSize
        )
        clockWidget.isVisible = true
        widgets.append(clockWidget)
        
        // Create weather widget - visibility based on settings
        let weatherWidget = WeatherWidget(
            position: positions.weatherPosition,
            size: widgetSize
        )
        weatherWidget.isVisible = settings.showWeather
        widgets.append(weatherWidget)
        
        // Create music widget - visibility based on settings
        let musicWidget = NowPlayingWidget(
            position: positions.musicPosition,
            size: widgetSize
        )
        musicWidget.isVisible = settings.showMusic
        widgets.append(musicWidget)
        
        print("🎯 Created widgets with fixed positions:")
        for (index, widget) in widgets.enumerated() {
            print("   Widget \(index): position=\(widget.position), size=\(widget.size), visible=\(widget.isVisible)")
        }
    }
    
    private func calculateFixedWidgetPositions(screenFrame: NSRect, dockFrame: NSRect) -> (clockPosition: CGPoint, weatherPosition: CGPoint, musicPosition: CGPoint) {
        
        // Get the overlay window frame to calculate positions relative to it
        let overlayFrame = window.frame
        
        switch dockPositionManager.dockPosition {
        case .bottom:
            // For bottom dock, widgets should be centered vertically within the overlay window
            let verticalCenter = overlayFrame.height / 2
            
            // Clock: horizontally centered between left screen edge and left edge of dock
            // For bottom dock, dock spans full width, so we center in the left half of screen
            let leftZoneCenter = screenFrame.width / 4
            let clockPosition = CGPoint(x: leftZoneCenter, y: verticalCenter)
            
            // Weather and Music: horizontally centered between right edge of dock and right screen edge
            // For bottom dock, dock spans full width, so we center in the right half of screen
            let rightZoneCenter = screenFrame.width * 3 / 4
            
            // Position weather and music side by side in the right zone, both at same vertical center
            let weatherPosition = CGPoint(x: rightZoneCenter - 70, y: verticalCenter)
            let musicPosition = CGPoint(x: rightZoneCenter + 70, y: verticalCenter)
            
            return (clockPosition, weatherPosition, musicPosition)
            
        case .left:
            // Clock: horizontally centered between left screen edge and left edge of dock
            let leftZoneCenter = screenFrame.minX + (dockFrame.minX - screenFrame.minX) / 2
            // Vertically center clock on the entire screen height
            let screenVerticalCenter = screenFrame.minY + (screenFrame.height / 2)
            let clockPosition = CGPoint(x: leftZoneCenter, y: screenVerticalCenter)
            
            // Weather and Music: horizontally centered between right edge of dock and right screen edge
            let rightZoneCenter = dockFrame.maxX + (screenFrame.maxX - dockFrame.maxX) / 2
            
            // Position weather and music vertically centered in the screen, with slight offset
            let weatherPosition = CGPoint(x: rightZoneCenter, y: screenVerticalCenter - 40)
            let musicPosition = CGPoint(x: rightZoneCenter, y: screenVerticalCenter + 40)
            
            return (clockPosition, weatherPosition, musicPosition)
            
        case .right:
            // Clock: horizontally centered between left screen edge and left edge of dock
            let leftZoneCenter = screenFrame.minX + (dockFrame.minX - screenFrame.minX) / 2
            // Vertically center clock on the entire screen height
            let screenVerticalCenter = screenFrame.minY + (screenFrame.height / 2)
            let clockPosition = CGPoint(x: leftZoneCenter, y: screenVerticalCenter)
            
            // Weather and Music: horizontally centered between right edge of dock and right screen edge
            let rightZoneCenter = dockFrame.maxX + (screenFrame.maxX - dockFrame.maxX) / 2
            
            // Position weather and music vertically centered in the screen, with slight offset
            let weatherPosition = CGPoint(x: rightZoneCenter, y: screenVerticalCenter - 40)
            let musicPosition = CGPoint(x: rightZoneCenter, y: screenVerticalCenter + 40)
            
            return (clockPosition, weatherPosition, musicPosition)
        }
    }
    
    private func updateWidgetVisibility() {
        // Only update visibility, not positions
        for widget in widgets {
            if widget is WeatherWidget {
                widget.isVisible = settings.showWeather
            } else if widget is NowPlayingWidget {
                widget.isVisible = settings.showMusic
            }
        }
        
        print("🎯 Updated widget visibility - Weather: \(settings.showWeather), Music: \(settings.showMusic)")
    }
    
    private func startDebugTimer() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            print("🔍 Debug: \(self.widgets.count) widgets active, visibility: \(self.widgets.map { "\(type(of: $0)): \($0.isVisible)" })")
        }
    }
}
