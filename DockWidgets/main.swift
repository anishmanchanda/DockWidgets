import Cocoa

//print("🎬 main.swift: Starting DockWidgets app...")

// Force the use of AppDelegate as the main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

//print("🎭 main.swift: AppDelegate set, starting main loop...")

// This ensures our AppDelegate is used instead of any SwiftUI app lifecycle
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
