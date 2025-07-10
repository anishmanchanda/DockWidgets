import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow?
    var widgetManager: WidgetManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the overlay window
        overlayWindow = OverlayWindow()
        widgetManager = WidgetManager(window: overlayWindow!)
        
        // Set up menu bar
        setupMenuBar()
        
        // Request permissions
        requestPermissions()
    }
    
    private func setupMenuBar() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DockWidgets", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🔧"
        statusItem.menu = menu
    }
    
    @objc private func showPreferences() {
        // Show preferences window
        let preferencesWindow = PreferencesWindow()
        preferencesWindow.makeKeyAndOrderFront(nil)
    }
    
    private func requestPermissions() {
        // Request location permission for weather
        LocationManager.shared.requestPermission()
    }
}