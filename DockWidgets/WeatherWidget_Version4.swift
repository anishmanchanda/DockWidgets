import SwiftUI
import CoreLocation

class WeatherWidget: BaseWidget {
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    private let weatherAPI = WeatherAPI()
    
    override init(position: CGPoint, size: CGSize = CGSize(width: 300, height: 120)) {
        super.init(position: position, size: size)
        loadWeatherData()
    }
    
    private func loadWeatherData() {
        isLoading = true
        
        LocationManager.shared.getCurrentLocation { [weak self] location in
            guard let location = location else { return }
            
            self?.weatherAPI.fetchWeather(for: location) { result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let data):
                        self?.weatherData = data
                    case .failure(let error):
                        print("Weather API error: \(error)")
                    }
                }
            }
        }
    }
    
    override func createView() -> AnyView {
        AnyView(WeatherView(widget: self))
    }
}

struct WeatherView: View {
    @ObservedObject var widget: WeatherWidget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if widget.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let weather = widget.weatherData {
                HStack {
                    VStack(alignment: .leading) {
                        Text(weather.location)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(weather.condition)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    VStack {
                        Text(weather.weatherIcon)
                            .font(.system(size: 32))
                        Text("\(weather.temperature)°")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text("Weather unavailable")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

struct WeatherData {
    let location: String
    let temperature: Int
    let condition: String
    let weatherIcon: String
}