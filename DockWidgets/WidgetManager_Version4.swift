import Foundation
import SwiftUI

class WidgetManager: ObservableObject {
    @Published var widgets: [BaseWidget] = []
    private let window: OverlayWindow
    
    init(window: OverlayWindow) {
        self.window = window
        setupDefaultWidgets()
    }
    
    private func setupDefaultWidgets() {
        // Add default widgets
        let flipClock = FlipClockWidget(position: CGPoint(x: 20, y: 300))
        let weather = WeatherWidget(position: CGPoint(x: 20, y: 200))
        let nowPlaying = NowPlayingWidget(position: CGPoint(x: 20, y: 50))
        
        widgets = [flipClock, weather, nowPlaying]
    }
}