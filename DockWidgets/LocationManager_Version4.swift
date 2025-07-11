import Foundation
import CoreLocation

class LocationManager: ObservableObject {
    static let shared = LocationManager()
    
    @Published var location: CLLocation = CLLocation(latitude: 28.6139, longitude: 77.2090) // Default: New Delhi
    
    // Users can change location from preferences by setting this property
    func updateLocation(latitude: Double, longitude: Double) {
        location = CLLocation(latitude: latitude, longitude: longitude)
        print("📍 Location updated to: \(latitude), \(longitude)")
    }
}
