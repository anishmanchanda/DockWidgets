import Foundation
import Cocoa

class DockPositionManager: ObservableObject {
    static let shared = DockPositionManager()
    
    @Published var dockPosition: DockPosition = .bottom
    @Published var dockFrame: NSRect = NSRect.zero
    @Published var dockMagnification: CGFloat = 1.0
    
    private var timer: Timer?
    private let defaults = UserDefaults.standard
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // Monitor dock position changes
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDockInfo()
        }
        
        // Initial update
        updateDockInfo()
    }
    
    private func updateDockInfo() {
        let dockInfo = getDockInfo()
        
        print("🎯 DockPositionManager: Position=\(dockInfo.position), Frame=\(dockInfo.frame), Magnification=\(dockInfo.magnification)")
        
        DispatchQueue.main.async {
            self.dockPosition = dockInfo.position
            self.dockFrame = dockInfo.frame
            self.dockMagnification = dockInfo.magnification
        }
    }
    
    private func getDockInfo() -> (position: DockPosition, frame: NSRect, magnification: CGFloat) {
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let dockDefaults = UserDefaults(suiteName: "com.apple.dock")
        let fixedDockSize = getDockTileSize()
        let persistentApps = dockDefaults?.array(forKey: "persistent-apps")?.count ?? 0
        let persistentOthers = dockDefaults?.array(forKey: "persistent-others")?.count ?? 0
        // +1 for trash, +1 for separator
        let iconCount = max(persistentApps + persistentOthers + 2, 1)
        let dockWidth = CGFloat(iconCount) * fixedDockSize
        let dockX = (screenFrame.width - dockWidth) / 2 + screenFrame.minX
        let dockFrame = NSRect(x: dockX, y: screenFrame.minY, width: dockWidth, height: fixedDockSize)
        return (.bottom, dockFrame, 1.0)
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
            print("🎯 DockPositionManager: Got tile size from defaults: \(tileSize)")
            return CGFloat(tileSize)
        }
        
        // Fallback to default dock size
        let fallbackSize: CGFloat = 60
        print("🎯 DockPositionManager: Using fallback tile size: \(fallbackSize)")
        return fallbackSize
    }
    private func getDockScreen() -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(dockFrame.origin) }) ?? NSScreen.main
    }
    func getWidgetSafeZone() -> NSRect {
        //let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let screenFrame = getDockScreen()?.frame ?? NSRect.zero
        let buffer: CGFloat = 20 // Buffer to avoid dock overlap
        
        switch dockPosition {
        case .bottom:
            return NSRect(
                x: screenFrame.minX,
                y: dockFrame.maxY + buffer,
                width: screenFrame.width,
                height: screenFrame.height - dockFrame.height - buffer
            )
        case .left:
            return NSRect(
                x: dockFrame.maxX + buffer,
                y: screenFrame.minY,
                width: screenFrame.width - dockFrame.width - buffer,
                height: screenFrame.height
            )
        case .right:
            return NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width - dockFrame.width - buffer,
                height: screenFrame.height
            )
        }
    }
    
    func getDockCenterPoint() -> CGPoint {
        return CGPoint(
            x: dockFrame.midX,
            y: dockFrame.midY
        )
    }
    
    deinit {
        timer?.invalidate()
    }
}
