import Foundation
import Combine

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    private let userDefaults = UserDefaults.standard
    
    // Clock Settingsx
    @Published var is24HourFormat: Bool {
        didSet {
            userDefaults.set(is24HourFormat, forKey: "is24HourFormat")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var showSeconds: Bool {
        didSet {
            userDefaults.set(showSeconds, forKey: "showSeconds")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    
    
    @Published var customLocation: String {
        didSet {
            userDefaults.set(customLocation, forKey: "customLocation")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var weatherUpdateInterval: Int {
        didSet {
            userDefaults.set(weatherUpdateInterval, forKey: "weatherUpdateInterval")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    // Widget Appearance
    @Published var widgetOpacity: Double {
        didSet {
            userDefaults.set(widgetOpacity, forKey: "widgetOpacity")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    

    private init() {
        // Load settings from UserDefaults
        self.is24HourFormat = userDefaults.bool(forKey: "is24HourFormat")
        self.showSeconds = userDefaults.object(forKey: "showSeconds") as? Bool ?? true
        self.customLocation = userDefaults.string(forKey: "customLocation") ?? "New Delhi"
        self.weatherUpdateInterval = userDefaults.object(forKey: "weatherUpdateInterval") as? Int ?? 600
        
        self.widgetOpacity = userDefaults.object(forKey: "widgetOpacity") as? Double ?? 1.0
        
    }
    
    // Helper methods for widgets
    func getDateFormat() -> String {
        if is24HourFormat {
            return showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            return showSeconds ? "h:mm:ss a" : "h:mm a"
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}
