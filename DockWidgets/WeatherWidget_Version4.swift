import SwiftUI
import CoreLocation
import Combine

class WeatherWidget: BaseWidget {
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    private let weatherAPI = WeatherAPI()
    private let settings = UserSettings.shared
    private var settingsSubscription: AnyCancellable?
    private var updateTimer: Timer?
    private var timeoutTimer: Timer?
    
    override init(position: CGPoint, size: CGSize = CGSize(width: 160, height: 50)) {
        super.init(position: position, size: size)
        setupSettingsObserver()
        loadWeatherData()
        startUpdateTimer()
    }
    
    private func setupSettingsObserver() {
        settingsSubscription = NotificationCenter.default.publisher(for: .settingsChanged)
            .sink { [weak self] _ in
                self?.loadWeatherData()
                self?.startUpdateTimer()
            }
    }
    
    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.weatherUpdateInterval), repeats: true) { [weak self] _ in
            self?.loadWeatherData()
        }
    }
    
    private func loadWeatherData() {
        isLoading = true
        print("🌤️ WeatherWidget: Loading weather data...")
        print("🌤️ WeatherWidget: Location source: \(settings.locationSource)")
        
        // Add timeout to prevent infinite loading
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            if self?.isLoading == true {
                print("🌤️ WeatherWidget: Timeout - falling back to default location")
                self?.isLoading = false
                self?.loadWeatherForCity("New York")
            }
        }
        
        if settings.locationSource == .custom && !settings.customLocation.isEmpty {
            // Use custom location
            print("🌤️ WeatherWidget: Using custom location: \(settings.customLocation)")
            loadWeatherForCity(settings.customLocation)
        } else {
            // Use GPS location with better error handling
            print("🌤️ WeatherWidget: Using GPS location")
            
            // Check if location services are available
            if CLLocationManager.locationServicesEnabled() {
                LocationManager.shared.getCurrentLocation { [weak self] location in
                    guard let location = location else {
                        print("🌤️ WeatherWidget: Failed to get location - using default location")
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            self?.loadWeatherForCity("New York")
                        }
                        return
                    }
                    
                    print("🌤️ WeatherWidget: Got location: \(location)")
                    self?.weatherAPI.fetchWeather(for: location) { result in
                        DispatchQueue.main.async {
                            self?.timeoutTimer?.invalidate()
                            self?.isLoading = false
                            switch result {
                            case .success(let data):
                                print("🌤️ WeatherWidget: Successfully fetched weather data: \(data)")
                                self?.weatherData = self?.convertTemperature(data)
                            case .failure(let error):
                                print("🌤️ WeatherWidget: Weather API error: \(error)")
                                // Fall back to default location on API error
                                self?.loadWeatherForCity("New York")
                            }
                        }
                    }
                }
            } else {
                print("🌤️ WeatherWidget: Location services disabled - using default location")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadWeatherForCity("New York")
                }
            }
        }
    }
    
    private func loadWeatherForCity(_ city: String) {
        timeoutTimer?.invalidate()
        isLoading = true
        print("🌤️ WeatherWidget: Loading weather for city: \(city)")
        
        weatherAPI.fetchWeatherByCity(city) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let data):
                    print("🌤️ WeatherWidget: Successfully fetched weather data for \(city)")
                    self?.weatherData = self?.convertTemperature(data)
                case .failure(let error):
                    print("🌤️ WeatherWidget: Weather API error for \(city): \(error)")
                    self?.weatherData = nil
                }
            }
        }
    }
    
    private func convertTemperature(_ data: WeatherData) -> WeatherData {
        let convertedTemp: Int
        if settings.temperatureUnit == .fahrenheit {
            convertedTemp = Int(Double(data.temperature) * 9/5 + 32)
        } else {
            convertedTemp = data.temperature
        }
        
        return WeatherData(
            location: data.location,
            temperature: convertedTemp,
            condition: data.condition,
            weatherIcon: data.weatherIcon
        )
    }
    
    override func createView() -> AnyView {
        AnyView(WeatherView(widget: self))
    }
}

struct WeatherView: View {
    @ObservedObject var widget: WeatherWidget
    @ObservedObject private var settings = UserSettings.shared
    
    var body: some View {
        HStack(spacing: 8) {
            if widget.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .foregroundColor(.white)
            } else if let weather = widget.weatherData {
                VStack(alignment: .leading, spacing: 2) {
                    Text(weather.location)
                        .font(.system(size: getFontSize() * 0.8))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                    Text(weather.condition)
                        .font(.system(size: getFontSize() * 0.6))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(weather.weatherIcon)
                        .font(.system(size: getFontSize() * 1.2))
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                    Text("\(weather.temperature)°\(settings.temperatureUnit == .fahrenheit ? "F" : "C")")
                        .font(.system(size: getFontSize(), weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                }
            } else {
                Text("Weather unavailable")
                    .font(.system(size: getFontSize() * 0.7))
                    .foregroundColor(.white.opacity(0.6))
                    .shadow(color: .black, radius: 1, x: 0, y: 0)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
        )
        .opacity(settings.widgetOpacity)
    }
    
    private func getFontSize() -> CGFloat {
        // Base font size for weather widget, scaled by widget height
        let baseSize: CGFloat = 16
        let scaleFactor = widget.size.height / 50  // 50 is our base height
        return max(baseSize * scaleFactor, 12)  // Minimum 12pt font
    }
}

struct WeatherData {
    let location: String
    let temperature: Int
    let condition: String
    let weatherIcon: String
}
