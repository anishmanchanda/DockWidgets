import Cocoa
import SwiftUI
import Combine

class OverlayWindow: NSWindow {
    private let dockPositionManager = DockPositionManager.shared
    private var dockSubscription: AnyCancellable?
    private var widgetManager: WidgetManager?
    private enum FSState { case normal, fullscreen }
    private var fsState: FSState = .normal
    private var spaceChangeObserver: Any?
    private var appActivationObserver: Any?
    private var samplingTimer: DispatchSourceTimer?
    // legacy counters (still usable for diagnostics)
    private var enterConsistency = 0
    private var exitConsistency = 0
    // Update timing constants for better responsiveness and stability
    private let sampleInterval: TimeInterval = 0.5 // Much slower, very stable detection
    private let requiredExitStable: TimeInterval = 0.7 // Even longer exit time
    private let minEnterStable: TimeInterval = 0.5 // Reasonable entry time
    private var resampleBurstWork: DispatchWorkItem?
    private var debugFS = true
    // Simplified state tracking
    private var lastFullscreenCheck: Bool = false
    private var fullscreenStateChangeTime: Date?
    // Missing properties that were referenced in the code
    private var firstExitCandidateAt: Date?
    private var firstFullscreenCandidateAt: Date?
    private var optimisticShownAt: Date?
    
    // MARK: Init
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        acceptsMouseMovedEvents = true
        setupWindow()
        setupDockObserver()
        setupFullscreenObservers()
        startSamplingTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.processSnapshot(reason: "initial") }
    }
    
    deinit {
        if let spaceChangeObserver { NSWorkspace.shared.notificationCenter.removeObserver(spaceChangeObserver) }
        if let appActivationObserver { NSWorkspace.shared.notificationCenter.removeObserver(appActivationObserver) }
        samplingTimer?.cancel()
    }
    
    func setWidgetManager(_ manager: WidgetManager) { widgetManager = manager; updateContentView() }
    
    // MARK: Observers
    private func setupFullscreenObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        
        // 1. Observer for when the active space (Desktop) changes.
        spaceChangeObserver = nc.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            if self.debugFS { print("[FS] Space change detected. Triggering resample burst.") }
            
            // Using a burst of checks is more reliable than a single check.
            // It gives the system time to settle and increases the chance of a correct state reading.
            self.triggerResampleBurst(reason: "postSpaceChange")
        }
        
        // 2. Observer for when the frontmost application changes.
        appActivationObserver = nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            // A single check is usually fine for app activation, but a burst is even safer.
            self?.triggerResampleBurst(reason: "appActivate")
        }
    }
    
    private func startSamplingTimer() {
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + sampleInterval, repeating: sampleInterval)
        t.setEventHandler { [weak self] in self?.processSnapshot(reason: "periodic") }
        t.resume()
        samplingTimer = t
    }
    
    private func triggerResampleBurst(reason: String) {
        resampleBurstWork?.cancel()
        var remaining = 3 // fewer samples for speed
        var work: DispatchWorkItem!
        work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.processSnapshot(reason: reason + "-burst")
            remaining -= 1
            if remaining > 0 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work) }
        }
        resampleBurstWork = work
        DispatchQueue.main.async(execute: work)
    }
    
    // MARK: Sampling & State Machine
    private func processSnapshot(reason: String) {
        // The check for a space transition ignore period has been removed.
        // This allows the logic to run reactively after a space change.
        
        let currentFullscreen = detectFullscreenApp()
        
        // Track state changes with timestamps
        if currentFullscreen != lastFullscreenCheck {
            lastFullscreenCheck = currentFullscreen
            fullscreenStateChangeTime = Date()
            if debugFS {
                print("[FS] STATE CHANGE: \(currentFullscreen ? "FULLSCREEN" : "NORMAL") detected for reason=\(reason)")
            }
        }
        
        // Require stability period before acting on state changes
        guard let changeTime = fullscreenStateChangeTime,
              Date().timeIntervalSince(changeTime) >= (currentFullscreen ? minEnterStable : requiredExitStable) else {
            if debugFS {
                let elapsed = fullscreenStateChangeTime.map { Date().timeIntervalSince($0) } ?? 0
                let required = currentFullscreen ? minEnterStable : requiredExitStable
                print("[FS] WAITING for stability: \(String(format: "%.1f", elapsed))/\(String(format: "%.1f", required))s - current=\(currentFullscreen) state=\(fsState)")
            }
            return
        }
        
        // Now we have a stable state - act on it
        if currentFullscreen && fsState == .normal {
            if debugFS { print("[FS] *** STABLE FULLSCREEN - HIDING WIDGETS ***") }
            fsState = .fullscreen
            hideForFullscreen()
            fullscreenStateChangeTime = nil
        } else if !currentFullscreen && fsState == .fullscreen {
            if debugFS { print("[FS] *** STABLE NORMAL - SHOWING WIDGETS ***") }
            fsState = .normal
            showAfterFullscreen()
            fullscreenStateChangeTime = nil
        }
        
        // Ensure widgets are in correct state
        if fsState == .normal && alphaValue < 1 {
            if debugFS { print("[FS] CORRECTING: Ensuring widgets visible in normal state") }
            showAfterFullscreen()
        } else if fsState == .fullscreen && alphaValue > 0 {
            if debugFS { print("[FS] CORRECTING: Ensuring widgets hidden in fullscreen state") }
            hideForFullscreen()
        }
    }
    
    private func transitionToFullscreen() {
        guard fsState != .fullscreen else { return }
        if debugFS { print("[FS] *** ENTERING FULLSCREEN STATE ***") }
        fsState = .fullscreen
        enterConsistency = 0
        optimisticShownAt = nil
        hideForFullscreen()
    }
    
    private func transitionToNormal() {
        guard fsState == .fullscreen else { return }
        if debugFS { print("[FS] *** EXITING FULLSCREEN STATE ***") }
        fsState = .normal
        enterConsistency = 0
        firstExitCandidateAt = nil
        optimisticShownAt = nil
        if alphaValue < 1 { showAfterFullscreen() }
    }
    
    // MARK: Snapshot model (NSWorkspace detection)
    private struct FSSnapshot { let isFullscreen: Bool }
    
    private func fullscreenSnapshotDetails() -> FSSnapshot {
        let isFullscreen = detectFullscreenApp()
        
        if debugFS && isFullscreen {
            print("[FS] Fullscreen app detected")
        }
        
        return FSSnapshot(isFullscreen: isFullscreen)
    }
    
    private func detectFullscreenApp() -> Bool {
        // Get the frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            if debugFS { print("[FS] No frontmost app found") }
            return false
        }
        
        // Skip our own app
        if frontmostApp.processIdentifier == ProcessInfo.processInfo.processIdentifier {
            return false
        }
        
        guard let screen = NSScreen.main else {
            if debugFS { print("[FS] No main screen found") }
            return false
        }
        
        let appName = frontmostApp.localizedName ?? "Unknown"
        
        // Primary check: Menu bar visibility (most reliable indicator)
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY
        
        // Balanced menu bar check - if menu bar is mostly hidden
        if menuBarHeight < 8 {
            if debugFS {
                print("[FS] FULLSCREEN DETECTED via menu bar for \(appName) - menuBarHeight: \(menuBarHeight)")
            }
            return true
        }
        
        // Secondary check: Window size detection with reasonable thresholds
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        if let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            let pid = frontmostApp.processIdentifier
            
            for windowInfo in windowList {
                guard let windowPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                      windowPID == pid,
                      let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
                      let width = boundsDict["Width"] as? CGFloat,
                      let height = boundsDict["Height"] as? CGFloat else {
                    continue
                }
                
                // Balanced fullscreen detection - 90% coverage OR 85% with hidden menu bar
                let widthRatio = width / screenFrame.width
                let heightRatio = height / screenFrame.height
                
                if (widthRatio > 0.9 && heightRatio > 0.9) ||
                   (widthRatio > 0.85 && heightRatio > 0.85 && menuBarHeight < 12) {
                    if debugFS {
                        print("[FS] FULLSCREEN DETECTED via large window for \(appName)")
                        print("[FS] Window size: \(Int(width))x\(Int(height)), Screen: \(Int(screenFrame.width))x\(Int(screenFrame.height))")
                        print("[FS] Coverage: \(Int(widthRatio*100))% x \(Int(heightRatio*100))%, menuBar: \(menuBarHeight)px")
                    }
                    return true
                }
            }
        }
        
        if debugFS {
            print("[FS] No fullscreen for \(appName) - menuBar: \(String(format: "%.1f", menuBarHeight))px")
        }
        
        return false
    }
    
    // MARK: Visibility helpers
    private func hideForFullscreen() {
        if debugFS { print("[FS] Hiding window for fullscreen") }
        // More aggressive hiding
        ignoresMouseEvents = true
        alphaValue = 0
        orderOut(nil)
    }
    private func fastShowAfterFullscreen() {
        ignoresMouseEvents = false
        if isVisible && alphaValue >= 0.95 { return }
        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.08
            animator().alphaValue = 1
        }
    }
    private func showAfterFullscreen() {
        ignoresMouseEvents = false
        if alphaValue == 1 && isVisible { return }
        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.14
            animator().alphaValue = 1
        }
    }
    
    // MARK: Dock / layout (unchanged)
    private func setupDockObserver() { /* intentionally disabled */ }
    private func updateWindowFrame() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let windowFrame = calculateWindowFrame(screenFrame: screenFrame)
        setFrame(windowFrame, display: true)
    }
    private func setupWindow() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let dockHeight = getDockHeight()
        let windowHeight = max(dockHeight, 70)
        let windowFrame = NSRect(x: 0, y: 0, width: screenFrame.width, height: windowHeight)
        setFrame(windowFrame, display: true)
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()
    }
    private func getDockHeight() -> CGFloat {
        guard let screen = NSScreen.main else { return 70 }
        let scaleFactor = screen.backingScaleFactor
        let dockFrame = dockPositionManager.dockFrame
        if dockFrame.height > 0 { return dockFrame.height * scaleFactor }
        if let tileSize = UserDefaults.standard.object(forKey: "tilesize") as? CGFloat { return tileSize * scaleFactor }
        let task = Process(); task.launchPath = "/usr/bin/defaults"; task.arguments = ["read", "com.apple.dock", "tilesize"]
        let pipe = Pipe(); task.standardOutput = pipe; task.launch(); task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), let v = Double(output) { return CGFloat(v) * scaleFactor }
        return 70 * scaleFactor
    }
    private func updateContentView() {
        guard let widgetManager = widgetManager else { return }
        let contentView = WidgetContainerView(window: self, widgetManager: widgetManager)
        self.contentView = NSHostingView(rootView: contentView)
    }
    private func calculateWindowFrame(screenFrame: NSRect) -> NSRect {
        let dockFrame = dockPositionManager.dockFrame
        let buffer: CGFloat = 50
        return NSRect(x: 0, y: 0, width: screenFrame.width, height: dockFrame.maxY + buffer + 100)
    }
}

enum DockPosition { case bottom, left, right }

// You may need to add placeholder definitions for these if they are in other files
// For example:
// class DockPositionManager { static let shared = DockPositionManager(); var dockFrame: NSRect = .zero }
// class WidgetManager {}
// struct WidgetContainerView: View { var window: NSWindow?; var widgetManager: WidgetManager?; var body: some View { Text("Widgets") }}
