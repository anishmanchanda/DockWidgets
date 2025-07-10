import Foundation
import CoreLocation
import OSLog

class WeatherAPI {
    private let apiKey = "05b6ac7969dbf1e0d32041e646e75fd8" // Replace with your OpenWeatherMap API key
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let logger = Logger(subsystem: "com.dockwidgets", category: "WeatherAPI")
    private let maxRetries = 3
    
    func fetchWeatherByCity(_ city: String, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        fetchWeatherByCity(city, retryCount: 0, completion: completion)
    }
    
    private func fetchWeatherByCity(_ city: String, retryCount: Int, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        // Properly encode the city name for URL
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Failed to encode city name: \(city)")
            completion(.failure(WeatherError.invalidCity))
            return
        }
        
        let urlString = "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)&units=metric"
        logger.info("Fetching weather for city: \(city) (attempt \(retryCount + 1))")
        
        guard let url = URL(string: urlString) else {
            logger.error("Failed to create URL from: \(urlString)")
            completion(.failure(WeatherError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.logger.error("Network error: \(error.localizedDescription)")
                
                // Retry on network errors
                if retryCount < self?.maxRetries ?? 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                        self?.fetchWeatherByCity(city, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                
                completion(.failure(WeatherError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self?.logger.error("Invalid response type")
                completion(.failure(WeatherError.invalidResponse))
                return
            }
            
            guard let data = data else {
                self?.logger.error("No data received")
                completion(.failure(WeatherError.noData))
                return
            }
            
            // Log response for debugging
            self?.logger.info("HTTP Status: \(httpResponse.statusCode)")
            
            // Handle HTTP errors
            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorData["message"] as? String {
                    self?.logger.error("API Error (\(httpResponse.statusCode)): \(message)")
                    completion(.failure(WeatherError.apiError(httpResponse.statusCode, message)))
                } else {
                    self?.logger.error("HTTP Error: \(httpResponse.statusCode)")
                    completion(.failure(WeatherError.httpError(httpResponse.statusCode)))
                }
                return
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let weatherData = WeatherData(
                    location: weatherResponse.name,
                    temperature: Int(weatherResponse.main.temp),
                    condition: weatherResponse.weather.first?.description.capitalized ?? "Unknown",
                    weatherIcon: self?.getWeatherIcon(for: weatherResponse.weather.first?.main ?? "") ?? "🌤️"
                )
                self?.logger.info("Successfully fetched weather for \(weatherResponse.name): \(weatherData.temperature)°C, \(weatherData.condition)")
                completion(.success(weatherData))
            } catch {
                self?.logger.error("JSON parsing error: \(error.localizedDescription)")
                completion(.failure(WeatherError.decodingError(error)))
            }
        }.resume()
    }
    
    func fetchWeather(for location: CLLocation, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        fetchWeather(for: location, retryCount: 0, completion: completion)
    }
    
    private func fetchWeather(for location: CLLocation, retryCount: Int, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        let urlString = "\(baseURL)?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=metric"
        logger.info("Fetching weather for coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude) (attempt \(retryCount + 1))")
        
        guard let url = URL(string: urlString) else {
            logger.error("Failed to create URL from: \(urlString)")
            completion(.failure(WeatherError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.logger.error("Network error: \(error.localizedDescription)")
                
                // Retry on network errors
                if retryCount < self?.maxRetries ?? 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                        self?.fetchWeather(for: location, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                
                completion(.failure(WeatherError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self?.logger.error("Invalid response type")
                completion(.failure(WeatherError.invalidResponse))
                return
            }
            
            guard let data = data else {
                self?.logger.error("No data received")
                completion(.failure(WeatherError.noData))
                return
            }
            
            // Log response for debugging
            self?.logger.info("HTTP Status: \(httpResponse.statusCode)")
            
            // Handle HTTP errors
            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorData["message"] as? String {
                    self?.logger.error("API Error (\(httpResponse.statusCode)): \(message)")
                    completion(.failure(WeatherError.apiError(httpResponse.statusCode, message)))
                } else {
                    self?.logger.error("HTTP Error: \(httpResponse.statusCode)")
                    completion(.failure(WeatherError.httpError(httpResponse.statusCode)))
                }
                return
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let weatherData = WeatherData(
                    location: weatherResponse.name,
                    temperature: Int(weatherResponse.main.temp),
                    condition: weatherResponse.weather.first?.description.capitalized ?? "Unknown",
                    weatherIcon: self?.getWeatherIcon(for: weatherResponse.weather.first?.main ?? "") ?? "🌤️"
                )
                self?.logger.info("Successfully fetched weather for \(weatherResponse.name): \(weatherData.temperature)°C, \(weatherData.condition)")
                completion(.success(weatherData))
            } catch {
                self?.logger.error("JSON parsing error: \(error.localizedDescription)")
                completion(.failure(WeatherError.decodingError(error)))
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

enum WeatherError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case networkError(Error)
    case httpError(Int)
    case apiError(Int, String)
    case decodingError(Error)
    case invalidCity
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for weather request"
        case .noData:
            return "No data received from weather service"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let code, let message):
            return "Weather API error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to parse weather data: \(error.localizedDescription)"
        case .invalidCity:
            return "Invalid city name"
        }
    }
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
