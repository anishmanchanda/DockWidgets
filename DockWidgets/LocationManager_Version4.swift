import CoreLocation
import OSLog

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.dockwidgets", category: "LocationManager")
    private var locationCallback: ((CLLocation?) -> Void)?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        logger.info("Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        locationCallback = completion
        
        switch authorizationStatus {
        case .notDetermined:
            logger.info("Location permission not determined, requesting permission")
            requestPermission()
        case .denied, .restricted:
            logger.warning("Location permission denied or restricted")
            completion(nil)
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location permission granted, requesting location")
            locationManager.requestLocation()
        @unknown default:
            logger.error("Unknown location authorization status")
            completion(nil)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { 
            logger.warning("No location in didUpdateLocations")
            return 
        }
        logger.info("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        locationCallback?(location)
        locationCallback = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location error: \(error.localizedDescription)")
        locationCallback?(nil)
        locationCallback = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        logger.info("Location authorization changed to: \(status.rawValue)")
        authorizationStatus = status
        
        // If we have a pending location request and permission was just granted
        if let callback = locationCallback,
           (status == .authorizedWhenInUse || status == .authorizedAlways) {
            locationManager.requestLocation()
        } else if let callback = locationCallback,
                  (status == .denied || status == .restricted) {
            logger.warning("Location permission denied, calling back with nil")
            callback(nil)
            locationCallback = nil
        }
    }
}