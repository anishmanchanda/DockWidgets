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
        
        if settings.locationSource == .custom && !settings.customLocation.isEmpty {
            // Use custom location
            weatherAPI.fetchWeatherByCity(settings.customLocation) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let data):
                        self?.weatherData = self?.convertTemperature(data)
                    case .failure(let error):
                        print("Weather API error: \(error)")
                    }
                }
            }
        } else {
            // Use GPS location
            LocationManager.shared.getCurrentLocation { [weak self] location in
                guard let location = location else { return }
                
                self?.weatherAPI.fetchWeather(for: location) { result in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        switch result {
                        case .success(let data):
                            self?.weatherData = self?.convertTemperature(data)
                        case .failure(let error):
                            print("Weather API error: \(error)")
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