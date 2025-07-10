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
        
        switch dockPositionManager.dockPosition {
        case .bottom:
            // Vertically center widgets between dock top and bottom
            let verticalCenter = dockFrame.minY + (dockFrame.height / 2)
            
            // Clock: horizontally centered between left screen edge and left dock edge
            // Since dock spans full width, we'll use the dock's left quarter
            let clockX = screenFrame.minX + (dockFrame.width / 4)
            let clockPosition = CGPoint(x: clockX, y: verticalCenter)
            
            // Weather and Music: horizontally centered between right screen edge and right dock edge
            // Position them in the right quarter of the dock area
            let rightQuarterCenter = screenFrame.minX + (dockFrame.width * 3 / 4)
            
            // Weather positioned in the right quarter
            let weatherPosition = CGPoint(x: rightQuarterCenter + 80, y: verticalCenter)
            
            // Music positioned slightly to the left of weather to avoid overlap
            let musicPosition = CGPoint(x: rightQuarterCenter - 80, y: verticalCenter)
            
            return (clockPosition, weatherPosition, musicPosition)
            
        case .left:
            // Vertically center widgets between dock top and bottom
            let verticalCenter = dockFrame.minY + (dockFrame.height / 2)
            
            // All widgets positioned to the right of the dock
            let horizontalPosition = dockFrame.maxX + 50
            
            // Spread widgets vertically
            let clockPosition = CGPoint(x: horizontalPosition, y: verticalCenter - 80)
            let weatherPosition = CGPoint(x: horizontalPosition, y: verticalCenter)
            let musicPosition = CGPoint(x: horizontalPosition, y: verticalCenter + 80)
            
            return (clockPosition, weatherPosition, musicPosition)
            
        case .right:
            // Vertically center widgets between dock top and bottom
            let verticalCenter = dockFrame.minY + (dockFrame.height / 2)
            
            // All widgets positioned to the left of the dock
            let horizontalPosition = dockFrame.minX - 50
            
            // Spread widgets vertically
            let clockPosition = CGPoint(x: horizontalPosition, y: verticalCenter - 80)
            let weatherPosition = CGPoint(x: horizontalPosition, y: verticalCenter)
            let musicPosition = CGPoint(x: horizontalPosition, y: verticalCenter + 80)
            
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
