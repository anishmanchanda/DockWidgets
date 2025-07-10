import Cocoa
import SwiftUI

class RightClickableView: NSView {
    private var contextMenu: NSMenu?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupContextMenu()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContextMenu()
    }
    
    private func setupContextMenu() {
        let menu = NSMenu()
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: "")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let reloadItem = NSMenuItem(title: "Reload Widgets", action: #selector(reloadWidgets), keyEquivalent: "")
        reloadItem.target = self
        menu.addItem(reloadItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit DockWidgets", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.menu = menu
    }
    
    @objc private func showPreferences() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.showPreferences()
        }
    }
    
    @objc private func reloadWidgets() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.reloadWidgets()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if let contextMenu = self.menu {
            NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
        }
    }
}

struct RightClickableContainer: NSViewRepresentable {
    let content: AnyView
    
    func makeNSView(context: Context) -> NSView {
        let containerView = RightClickableView()
        
        // Add the SwiftUI content as a subview
        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hostingView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the content if needed
    }
}
