import SwiftUI
import CoreLocation
import Combine
import OSLog

class WeatherWidget: BaseWidget {
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let weatherAPI = WeatherAPI()
    private let settings = UserSettings.shared
    private let logger = Logger(subsystem: "com.dockwidgets", category: "WeatherWidget")
    private var settingsSubscription: AnyCancellable?
    private var updateTimer: Timer?
    
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
        errorMessage = nil
        logger.info("Loading weather data")
        
        if settings.locationSource == .custom && !settings.customLocation.isEmpty {
            // Use custom location
            logger.info("Using custom location: \(settings.customLocation)")
            weatherAPI.fetchWeatherByCity(settings.customLocation) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let data):
                        self?.logger.info("Successfully loaded weather data for custom location")
                        self?.weatherData = self?.convertTemperature(data)
                        self?.errorMessage = nil
                    case .failure(let error):
                        self?.logger.error("Weather API error for custom location: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        self?.weatherData = nil
                    }
                }
            }
        } else {
            // Use GPS location
            logger.info("Using GPS location")
            LocationManager.shared.getCurrentLocation { [weak self] location in
                guard let location = location else { 
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = "Location unavailable"
                        self?.weatherData = nil
                        self?.logger.warning("Failed to get current location")
                    }
                    return 
                }
                
                self?.weatherAPI.fetchWeather(for: location) { result in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        switch result {
                        case .success(let data):
                            self?.logger.info("Successfully loaded weather data for GPS location")
                            self?.weatherData = self?.convertTemperature(data)
                            self?.errorMessage = nil
                        case .failure(let error):
                            self?.logger.error("Weather API error for GPS location: \(error.localizedDescription)")
                            self?.errorMessage = error.localizedDescription
                            self?.weatherData = nil
                        }
                    }
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
            } else if let errorMessage = widget.errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.system(size: getFontSize() * 0.6))
                    .foregroundColor(.red.opacity(0.8))
                    .shadow(color: .black, radius: 1, x: 0, y: 0)
                    .multilineTextAlignment(.center)
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