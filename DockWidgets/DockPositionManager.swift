import Foundation
import Cocoa

// Renamed to avoid conflict with system type
enum DockPositionType: String {
    case bottom
    // Removed left and right cases as requested
}

class DockPositionManager: ObservableObject {
    static let shared = DockPositionManager()
    
    @Published var dockPosition: DockPositionType = .bottom
    @Published var dockFrame: NSRect = NSRect.zero
    
    private let defaults = UserDefaults.standard
    
    private init() {
        updateDockInfo()
    }
    
    func updateDockInfo() {
        let dockInfo = getDockInfo()
        
        //print("🎯 DockPositionManager: Frame=\(dockInfo.frame)")
        
        DispatchQueue.main.async {
            self.dockPosition = .bottom // Always bottom as requested
            self.dockFrame = dockInfo.frame
        }
    }
    
    private func getDockInfo() -> (position: DockPositionType, frame: NSRect) {
        guard let screenFrame = NSScreen.main?.visibleFrame else {
            //print("🎯 DockPositionManager: No screen detected, returning zero frame.")
            return (.bottom, NSRect.zero)
        }

        // Get dock size
        let tileSize = getDockTileSize()
        //print("tile size is: \(tileSize)")
        let dockDefaults = UserDefaults(suiteName: "com.apple.dock")
        let persistentApps = dockDefaults?.array(forKey: "persistent-apps")?.count ?? 0
        let persistentOthers = dockDefaults?.array(forKey: "persistent-others")?.count ?? 0
        let iconCount = max(persistentApps + persistentOthers + 8, 1) // +4 for trash and separators
        
        // Calculate frame for bottom position only
        let dockWidth = CGFloat(iconCount) * tileSize
        let dockX = (screenFrame.width - dockWidth) / 2 + screenFrame.minX
        let dockFrame = NSRect(x: dockX, y: screenFrame.minY, width: dockWidth, height: tileSize)
        
        //print("🎯 DockPositionManager: Calculated dock frame: \(dockFrame)")
        return (.bottom, dockFrame)
    }
    
    private func getDockTileSize() -> CGFloat {
        // Try to get tile size from dock preferences
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.dock", "tilesize"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           let tileSize = Double(output) {
            //print("🎯 DockPositionManager: Got tile size from defaults: \(tileSize)")
            return CGFloat(tileSize) + 4 // Add padding
        }
        
        // Fallback to default dock size
        let fallbackSize: CGFloat = 60
        //print("🎯 DockPositionManager: Using fallback tile size: \(fallbackSize)")
        return fallbackSize
    }
    
    private func getDockScreen() -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(dockFrame.origin) }) ?? NSScreen.main
    }
    
    // Get the left edge of the dock
    func getDockLeftEdge() -> CGFloat {
        return dockFrame.minX
    }
    
    // Get the right edge of the dock
    func getDockRightEdge() -> CGFloat {
        return dockFrame.maxX
    }
    
    func getWidgetSafeZone() -> NSRect {
        let screenFrame = getDockScreen()?.visibleFrame ?? NSRect.zero
        let buffer: CGFloat = 20 // Buffer to avoid dock overlap
        
        return NSRect(
            x: screenFrame.minX,
            y: dockFrame.maxY + buffer,
            width: screenFrame.width,
            height: screenFrame.height - dockFrame.height - buffer
        )
    }
    
    func getDockCenterPoint() -> CGPoint {
        return CGPoint(
            x: dockFrame.midX,
            y: dockFrame.midY
        )
    }
}
