import Foundation
import Combine

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    private let userDefaults = UserDefaults.standard
    
    // Clock Settings
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
    
    // Weather Settings
    @Published var temperatureUnit: TemperatureUnit {
        didSet {
            userDefaults.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
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
    
    @Published var textSize: TextSize {
        didSet {
            userDefaults.set(textSize.rawValue, forKey: "textSize")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    // Widget Position
    @Published var clockPosition: WidgetPosition {
        didSet {
            userDefaults.set(clockPosition.rawValue, forKey: "clockPosition")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var showWeather: Bool {
        didSet {
            userDefaults.set(showWeather, forKey: "showWeather")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var showMusic: Bool {
        didSet {
            userDefaults.set(showMusic, forKey: "showMusic")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    private init() {
        // Load settings from UserDefaults
        self.is24HourFormat = userDefaults.bool(forKey: "is24HourFormat")
        self.showSeconds = userDefaults.object(forKey: "showSeconds") as? Bool ?? true
        
        self.temperatureUnit = TemperatureUnit(rawValue: userDefaults.string(forKey: "temperatureUnit") ?? "celsius") ?? .celsius
        self.customLocation = userDefaults.string(forKey: "customLocation") ?? "New Delhi"
        self.weatherUpdateInterval = userDefaults.object(forKey: "weatherUpdateInterval") as? Int ?? 600
        
        self.widgetOpacity = userDefaults.object(forKey: "widgetOpacity") as? Double ?? 1.0
        self.textSize = TextSize(rawValue: userDefaults.string(forKey: "textSize") ?? "medium") ?? .medium
        
        self.clockPosition = WidgetPosition(rawValue: userDefaults.string(forKey: "clockPosition") ?? "left") ?? .left
        self.showWeather = userDefaults.object(forKey: "showWeather") as? Bool ?? true
        self.showMusic = userDefaults.object(forKey: "showMusic") as? Bool ?? true
    }
    
    func resetToDefaults() {
        is24HourFormat = false
        showSeconds = true
        temperatureUnit = .celsius
        customLocation = "New Delhi"
        weatherUpdateInterval = 600
        widgetOpacity = 1.0
        textSize = .medium
        clockPosition = .left
        showWeather = true
        showMusic = true
    }
    
    // Helper methods for widgets
    func getFontSize() -> CGFloat {
        switch textSize {
        case .small:
            return 12
        case .medium:
            return 16
        case .large:
            return 20
        }
    }
    
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
