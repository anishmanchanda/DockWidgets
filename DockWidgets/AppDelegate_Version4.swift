import Cocoa
import SwiftUI

// @NSApplicationMain removed - using main.swift instead
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow?
    var widgetManager: WidgetManager?
    var preferencesWindow: PreferencesWindow?
    
    override init() {
        super.init()
        print("🎯 AppDelegate: init() called")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate: applicationDidFinishLaunching called")
        
        // Force the app to activate
        NSApp.activate(ignoringOtherApps: true)
        
        // Create the overlay window
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        print("📱 Screen frame: \(screenFrame)")
        
        overlayWindow = OverlayWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        print("🪟 OverlayWindow created")
        
        widgetManager = WidgetManager(window: overlayWindow!)
        print("📦 WidgetManager created")
        
        // Connect widget manager to window
        overlayWindow?.setWidgetManager(widgetManager!)
        print("🔗 WidgetManager connected to window")
        
        // Request permissions
        requestPermissions()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("🔄 AppDelegate: applicationWillFinishLaunching called")
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("✅ AppDelegate: applicationDidBecomeActive called")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Keep app running even if windows are closed
    }
    
    @objc func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow()
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        preferencesWindow?.center()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func reloadWidgets() {
        // Recreate the widget manager to refresh all widgets
        if let window = overlayWindow {
            widgetManager = WidgetManager(window: window)
        }
    }
    
    private func requestPermissions() {
        print("🔐 Requesting location permissions...")
        // Request location permission for weather
        LocationManager.shared.requestPermission()
    }
}
