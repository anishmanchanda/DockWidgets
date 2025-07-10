import SwiftUI
import Cocoa

class PreferencesWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "DockWidgets Preferences"
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "gear")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("DockWidgets Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            
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
                                Text("Temperature Unit:")
                                    .frame(width: 120, alignment: .leading)
                                Picker("Temperature Unit", selection: $settings.temperatureUnit) {
                                    Text("Celsius (°C)").tag(TemperatureUnit.celsius)
                                    Text("Fahrenheit (°F)").tag(TemperatureUnit.fahrenheit)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                Spacer()
                            }
                            
                            HStack {
                                Text("Location Source:")
                                    .frame(width: 120, alignment: .leading)
                                Picker("Location Source", selection: $settings.locationSource) {
                                    Text("Auto (GPS)").tag(LocationSource.automatic)
                                    Text("Custom").tag(LocationSource.custom)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                Spacer()
                            }
                            
                            if settings.locationSource == .custom {
                                HStack {
                                    Text("Custom Location:")
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
                            
                            HStack {
                                Text("Text Size:")
                                    .frame(width: 120, alignment: .leading)
                                Picker("Text Size", selection: $settings.textSize) {
                                    Text("Small").tag(TextSize.small)
                                    Text("Medium").tag(TextSize.medium)
                                    Text("Large").tag(TextSize.large)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                Spacer()
                            }
                        }
                        .padding()
                    }
                    
                    // Widget Positioning
                    GroupBox(label: Label("Widget Position", systemImage: "move.3d")) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Clock Position:")
                                    .frame(width: 120, alignment: .leading)
                                Picker("Clock Position", selection: $settings.clockPosition) {
                                    Text("Left").tag(WidgetPosition.left)
                                    Text("Center").tag(WidgetPosition.center)
                                    Text("Right").tag(WidgetPosition.right)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                Spacer()
                            }
                            
                            HStack {
                                Text("Show Weather:")
                                    .frame(width: 120, alignment: .leading)
                                Toggle("", isOn: $settings.showWeather)
                                    .toggleStyle(SwitchToggleStyle())
                                Spacer()
                            }
                            
                            HStack {
                                Text("Show Music:")
                                    .frame(width: 120, alignment: .leading)
                                Toggle("", isOn: $settings.showMusic)
                                    .toggleStyle(SwitchToggleStyle())
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
            
            // Footer buttons
            HStack {
                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                    customLocation = settings.customLocation
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close") {
                    if let window = NSApplication.shared.windows.first(where: { $0.title == "DockWidgets Preferences" }) {
                        window.close()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            customLocation = settings.customLocation
        }
    }
}

// MARK: - Settings Enums
enum TemperatureUnit: String, CaseIterable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"
}

enum LocationSource: String, CaseIterable {
    case automatic = "automatic"
    case custom = "custom"
}

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
