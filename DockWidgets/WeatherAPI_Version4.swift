import Foundation
import CoreLocation

class WeatherAPI {
    private let apiKey = "05b6ac7969dbf1e0d32041e646e75fd8" // Replace with your OpenWeatherMap API key
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func fetchWeatherByCity(_ city: String, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        let urlString = "\(baseURL)?q=\(city)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(.failure(WeatherError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(WeatherError.noData))
                return
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let weatherData = WeatherData(
                    location: weatherResponse.name,
                    temperature: Int(weatherResponse.main.temp),
                    condition: weatherResponse.weather.first?.description.capitalized ?? "Unknown",
                    weatherIcon: self.getWeatherIcon(for: weatherResponse.weather.first?.main ?? "")
                )
                completion(.success(weatherData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchWeather(for location: CLLocation, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        let urlString = "\(baseURL)?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(WeatherError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(WeatherError.noData))
                return
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let weatherData = WeatherData(
                    location: weatherResponse.name,
                    temperature: Int(weatherResponse.main.temp),
                    condition: weatherResponse.weather.first?.description.capitalized ?? "Unknown",
                    weatherIcon: self.getWeatherIcon(for: weatherResponse.weather.first?.main ?? "")
                )
                completion(.success(weatherData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func getWeatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear": return "☀️"
        case "clouds": return "☁️"
        case "rain": return "🌧️"
        case "snow": return "❄️"
        case "thunderstorm": return "⛈️"
        default: return "🌤️"
        }
    }
}

enum WeatherError: Error {
    case invalidURL
    case noData
}

struct WeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    
    struct Main: Codable {
        let temp: Double
    }
    
    struct Weather: Codable {
        let main: String
        let description: String
    }
}
