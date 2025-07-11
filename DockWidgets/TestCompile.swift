import Foundation

// Test compilation of our fixed classes
class TestCompile {
    static func test() {
        // Test MediaController
        let mediaController = AppleScriptMediaController()
        mediaController.startMonitoring()
        
        // Note: MPNowPlayingInfoDidChange notification doesn't exist in MediaPlayer framework
        // The MediaController now uses timer-based polling instead
        print("MediaController initialized successfully")
        
        // Test WeatherData creation
        let weatherData = WeatherData(
            location: "Test",
            temperature: 25,
            condition: "Sunny",
            weatherIcon: "☀️",
            humidity: 50,
            windSpeed: 5.0,
            feelsLike: 27
        )
        print("Weather data created: \(weatherData.location)")
        
        // Test NowPlayingInfo creation
        let nowPlayingInfo = NowPlayingInfo(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            app: AppleScriptMediaController.MediaApp.none
        )
        print("Now playing info created: \(nowPlayingInfo.title)")
        
        print("All tests passed!")
    }
}
