import SwiftUI
import Cocoa

class PreferencesWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "Preferences"
        self.center()
        self.isReleasedWhenClosed = false
        
        // Create the SwiftUI content view
        let contentView = PreferencesView()
        self.contentView = NSHostingView(rootView: contentView)
    }
}

struct PreferencesView: View {
    @StateObject private var settings = UserSettings.shared
    @State private var customLocation = ""
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                Spacer()
                TabButton(
                    title: "General",
                    systemImage: "gearshape.fill",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabButton(
                    title: "Info",
                    systemImage: "info.circle",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                Spacer()
            }
            .padding(.top, 12)
            
            Divider()
                .padding(.top, 4)
            
            // Tab Content
            if selectedTab == 0 {
                GeneralTabView(settings: settings, customLocation: $customLocation)
            } else {
                InfoTabView()
            }
        }
        .frame(minWidth: 500, minHeight: 550)
        .onAppear {
            customLocation = settings.customLocation
        }
    }
}

struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

struct GeneralTabView: View {
    @ObservedObject var settings: UserSettings
    @Binding var customLocation: String
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Clock Settings
                    GroupBox(label: Label("Clock Settings", systemImage: "clock")) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Time Format:")
                                    .frame(width: 100, alignment: .leading)
                                Picker("Time Format", selection: $settings.is24HourFormat) {
                                    Text("12 Hour").tag(false)
                                    Text("24 Hour").tag(true)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                Spacer()
                            }

                            HStack {
                                Text("Show Seconds:")
                                    .frame(width: 100, alignment: .leading)
                                Toggle("", isOn: $settings.showSeconds)
                                    .toggleStyle(SwitchToggleStyle())
                                Spacer()
                            }
                        }
                        .padding()
                    }

                    // Weather Settings
                    GroupBox(label: Label("Weather Settings", systemImage: "cloud.sun")) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Update Interval:")
                                    .frame(width: 120, alignment: .leading)
                                Picker("Update Interval", selection: $settings.weatherUpdateInterval) {
                                    Text("5 minutes").tag(300)
                                    Text("10 minutes").tag(600)
                                    Text("30 minutes").tag(1800)
                                    Text("1 hour").tag(3600)
                                }
                                .pickerStyle(MenuPickerStyle())
                                Spacer()
                            }

                            HStack {
                                Text("Location:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Enter city name", text: $customLocation)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        settings.customLocation = customLocation
                                    }
                                Button("Save") {
                                    settings.customLocation = customLocation
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    }

                    // Widget Appearance
                    GroupBox(label: Label("Widget Appearance", systemImage: "paintbrush")) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Widget Opacity:")
                                    .frame(width: 120, alignment: .leading)
                                Slider(value: $settings.widgetOpacity, in: 0.3...1.0, step: 0.1)
                                Text("\(Int(settings.widgetOpacity * 100))%")
                                    .frame(width: 40)
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }

            // Footer buttons
            HStack {
                Spacer()
                Button("Close") {
                    if let window = NSApplication.shared.windows.first(where: { $0.title == "Preferences" }) {
                        window.close()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct InfoTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    GroupBox(label: Label("About DockWidgets", systemImage: "info.circle")) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(nsImage: NSApp.applicationIconImage)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                
                                VStack(alignment: .leading) {
                                    Text("DockWidgets")
                                        .font(.title)
                                        .bold()
                                    Text("Version 1.0")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            Text("DockWidgets is a customizable widget application for macOS that utilises the unoccupied space at the sides of the dock with transparent interactive tools.")
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack {
                                Text("For queries and feedback write to:")
                                Link("anishmanchanda2006@gmail.com", destination: URL(string: "mailto:anishmanchanda2006@gmail.com")!)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("© 2025 DockWidgets \n  -Anish Manchanda")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Footer buttons
            HStack {
                Spacer()
                Button("Close") {
                    if let window = NSApplication.shared.windows.first(where: { $0.title == "Preferences" }) {
                        window.close()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
// MARK: - Settings Enums

enum TextSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
}

enum WidgetPosition: String, CaseIterable {
    case left = "left"
    case center = "center"
    case right = "right"
}
