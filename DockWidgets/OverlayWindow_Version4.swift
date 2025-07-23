import Cocoa
import SwiftUI
import Combine

class OverlayWindow: NSWindow {
    private let dockPositionManager = DockPositionManager.shared
    private var dockSubscription: AnyCancellable?
    private var widgetManager: WidgetManager?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        
        self.level = .floating  // Normal floating level, not screen saver
        self.backgroundColor = .clear  // Clear background, not red
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.acceptsMouseMovedEvents = true
        
        setupWindow()
        setupDockObserver()
    }
    
    func setWidgetManager(_ manager: WidgetManager) {
        widgetManager = manager
        updateContentView()
    }
    
    private func setupDockObserver() {
        // Disable dock observer to prevent window repositioning
        // dockSubscription = dockPositionManager.objectWillChange
        //     .sink { [weak self] _ in
        //         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        //             self?.updateWindowFrame()
        //         }
        //     }
        //print("🪟 OverlayWindow: Dock observer disabled for stability")
    }
    
    private func updateWindowFrame() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let windowFrame = calculateWindowFrame(screenFrame: screenFrame)
        self.setFrame(windowFrame, display: true)
        //print("🪟 OverlayWindow repositioned to: \(self.frame)")
    }
    
    private func setupWindow() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // Get dock height using multiple methods for reliability
        let dockHeight = getDockHeight()
        
        // Use dock height for window height with minimum fallback
        let windowHeight = max(dockHeight, 70) // Minimum 70px height
        let windowFrame = NSRect(
            x: 0,
            y: 0,
            width: screenFrame.width,
            height: windowHeight
        )
        self.setFrame(windowFrame, display: true)
        
        //print("🪟 OverlayWindow setup - Screen: \(screenFrame), Dock Height: \(dockHeight), Window: \(windowFrame)")
        
        // Content view will be set later when widget manager is available
        
        // Make window visible
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        
//        print("🪟 OverlayWindow positioned at: \(self.frame)")
//        print("🪟 OverlayWindow level: \(self.level.rawValue)")
//        print("🪟 OverlayWindow isVisible: \(self.isVisible)")
    }
    
    private func getDockHeight() -> CGFloat {
        guard let screen = NSScreen.main else {
            //print("🪟 No main screen detected, using fallback dock height.")
            return 70 // Fallback to a reasonable default height in pixels
        }
        
        let scaleFactor = screen.backingScaleFactor

        // Method 1: Try DockPositionManager
        let dockFrame = dockPositionManager.dockFrame
        if dockFrame.height > 0 {
            let heightInPixels = dockFrame.height * scaleFactor
            //print("🪟 Using DockPositionManager height in pixels: \(heightInPixels)")
            return heightInPixels
        }

        // Method 2: Try UserDefaults (dock tile size)
        if let dockTileSize = UserDefaults.standard.object(forKey: "tilesize") as? CGFloat {
            let calculatedHeight = dockTileSize * scaleFactor // Removed padding
            //print("🪟 Using UserDefaults tile size in pixels: \(dockTileSize) -> height: \(calculatedHeight)")
            return calculatedHeight
        }

        // Method 3: Try getting dock process and estimate
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
            let calculatedHeight = CGFloat(tileSize) * scaleFactor // Removed padding
            //print("🪟 Using dock defaults tile size in pixels: \(tileSize) -> height: \(calculatedHeight)")
            return calculatedHeight
        }

        // Method 4: Fallback to estimated dock height
        let fallbackHeight: CGFloat = 70 * scaleFactor // Reduced fallback height
        //print("🪟 Using fallback dock height in pixels: \(fallbackHeight)")
        return fallbackHeight
    }
    private func updateContentView() {
        guard let widgetManager = widgetManager else { return }
        
        // Create content view with the shared widget manager
        let contentView = WidgetContainerView(window: self, widgetManager: widgetManager)
        self.contentView = NSHostingView(rootView: contentView)
        
        //print("🪟 OverlayWindow content view updated with widgetManager")
    }
    
    private func calculateWindowFrame(screenFrame: NSRect) -> NSRect {
        let dockFrame = dockPositionManager.dockFrame
        let buffer: CGFloat = 50
        
    
        
        return NSRect(
            x: 0,
            y: 0,
            width: screenFrame.width,
            height: dockFrame.maxY + buffer + 100
            )
        
        
    }
}


enum DockPosition {
    case bottom, left, right
}
