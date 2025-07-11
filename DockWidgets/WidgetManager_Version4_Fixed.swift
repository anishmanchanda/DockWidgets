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
        print("right edge of dock: \(dockFrame.maxX)")
        print("left edge of dock: \(dockFrame.minX)")
        print("🎯 Screen frame: \(screenFrame)")
        print("🎯 Dock frame: \(dockFrame)")
        
        // Calculate positions based on dock position
        print("screenFrame: \(screenFrame)")
        print("screenFrame.maxX: \(screenFrame.maxX)")
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
        print("Weather widget position: \(weatherWidget.position), size: \(weatherWidget.size)")
        print("Music widget position: \(musicWidget.position), size: \(musicWidget.size)")
        for (index, widget) in widgets.enumerated() {
            print("   Widget \(index): position=\(widget.position), size=\(widget.size), visible=\(widget.isVisible)")
        }
    }
    
    private func calculateFixedWidgetPositions(screenFrame: NSRect, dockFrame: NSRect) -> (clockPosition: CGPoint, weatherPosition: CGPoint, musicPosition: CGPoint) {
        let widgetSpacing: CGFloat = 15
        let widgetSize = CGSize(width: 140, height: 60)
        print("screenFrame.maxX in calculateFixedWidgetPositions: \(screenFrame.maxX)")
print("screenFrame.maxX in calculateFixedWidgetPositions: \(screenFrame.maxX)")
 

            let verticalCenter = (dockFrame.minY + dockFrame.height) / 2
            
            
            //let leftZoneCenter = screenFrame.minX + (screenFrame.width / 4)
            //let leftZoneCenter = (screenFrame.minX + dockFrame.minX)/2
            let leftZoneCenter = (screenFrame.maxX)/4
            let clockPosition = CGPoint(x: leftZoneCenter-widgetSize.width, y: verticalCenter)
            
            // Weather and Music: positioned on the RIGHT side of the screen, well away from dock apps
            //let rightZoneStart = screenFrame.maxX - (widgetSize.width * 2 + widgetSpacing + 50) // 50px margin from edge
            let rightZoneStart = screenFrame.maxX - (widgetSize.width * 3)
            let weatherX = rightZoneStart + (dockFrame.width)*3 //+ widgetSize.width / 2
            //let musicX = rightZoneStart + widgetSize.width + widgetSpacing
            let musicX = rightZoneStart+100
            
            let weatherPosition = CGPoint(x: weatherX, y: verticalCenter)
            let musicPosition = CGPoint(x: musicX, y: verticalCenter)
            
            print("🎯 Bottom dock - All widgets within dock height")
            print("   Dock frame: \(dockFrame)")
            print("   Widget vertical center: \(verticalCenter)")
            print("   Weather center: (\(weatherX), \(verticalCenter))")
            print("   Music center: (\(musicX), \(verticalCenter))")
            return (clockPosition, weatherPosition, musicPosition)
       
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
