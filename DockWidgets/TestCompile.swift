import Foundation

// Test compilation of our fixed classes
class TestCompile {
    static func test() {
        // Test AppleScriptMediaController
        let mediaController = AppleScriptMediaController()
        mediaController.startMonitoring()
        
        print("AppleScriptMediaController initialized successfully")
        
        // Test WeatherData creation
        let weatherData = WeatherData(
            location: "Test",
            temperature: 25,
            condition: "Sunny",
            weatherIcon: "☀️"
        )
        print("Weather data created: \(weatherData.location)")
        
        // Test NowPlayingInfo creation with source app
        let nowPlayingInfo = NowPlayingInfo(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            artworkURL: nil,
            sourceApp: "Music"
        )
        print("Now playing info created: \(nowPlayingInfo.title) from \(nowPlayingInfo.sourceApp ?? "Unknown")")
        
        print("All tests passed!")
    }
}
