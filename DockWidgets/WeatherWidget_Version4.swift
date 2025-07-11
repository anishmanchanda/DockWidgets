
import SwiftUI

struct WeatherWidget_Version4: View {
    @StateObject private var widget = WeatherData_Version4()
    @State private var isLoading = false
    @State private var timeoutTimer: Timer?
    @State private var customLocation: String = UserDefaults.standard.string(forKey: "customLocation") ?? "New Delhi"
    
    var body: some View {
        print("WeatherWidget_Version4 body rendered")
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Weather")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let weatherData = widget.weatherData {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(Int(weatherData.temperature))°")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(weatherData.condition)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text(weatherData.location)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Weather unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        //.padding(12)
        .background(Color.clear) // Completely transparent background
        .cornerRadius(8)
        .onAppear {
            loadWeatherData()
        }
    }
    
    private func loadWeatherData() {
        print("🌤️ WeatherWidget: Loading weather data...")
        isLoading = true
        
        // Add timeout to prevent infinite loading
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            if self.widget.weatherData == nil && self.isLoading {
                print("🌤️ WeatherWidget: Timeout - falling back to default location")
                self.isLoading = false
                self.loadWeatherForCity("New Delhi")
            }
        }
        
        let useCustomLocation = UserDefaults.standard.bool(forKey: "useCustomLocation")
        let city = useCustomLocation ? (UserDefaults.standard.string(forKey: "customLocation") ?? "New Delhi") : "New Delhi"
        print("🌤️ WeatherWidget: Using city: \(city)")
        timeoutTimer?.invalidate()
        loadWeatherForCity(city)
    }
    
    private func loadWeatherForCity(_ city: String) {
        isLoading = true
        WeatherAPI.shared.getWeatherData(for: city) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let weatherData):
                    print("🌤️ WeatherWidget: Successfully fetched weather data for \(city)")
                    self.widget.weatherData = weatherData
                case .failure(let error):
                    print("🌤️ WeatherWidget: Weather API error for \(city): \(error)")
                    self.widget.weatherData = nil
                }
            }
        }
    }
}

// MARK: - WeatherData_Version4 Class
class WeatherData_Version4: ObservableObject {
    @Published var weatherData: WeatherData?
}

// MARK: - WeatherWidget Wrapper Class
class WeatherWidget: BaseWidget {
    override func createView() -> AnyView {
        AnyView(WeatherWidget_Version4())
    }
}
