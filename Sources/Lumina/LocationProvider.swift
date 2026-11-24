import Foundation
import CoreLocation

final class LocationProvider: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    static let shared = LocationProvider()
    
    private let manager = CLLocationManager()
    private var lastCoordinate: CLLocationCoordinate2D?
    private let lock = NSLock()
    
    var onCoordinateUpdate: ((CLLocationCoordinate2D) -> Void)?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    func requestLocationIfAuthorized() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func currentCoordinates() -> (latitude: Double, longitude: Double) {
        lock.lock()
        defer { lock.unlock() }
        
        if let coord = lastCoordinate {
            return (coord.latitude, coord.longitude)
        }
        
        // Approximate location from system timezone when location access is unavailable.
        let hoursFromGMT = Double(TimeZone.current.secondsFromGMT()) / 3600.0
        let estimatedLongitude = hoursFromGMT * 15.0
        let estimatedLatitude = 37.7749 // Mid-latitude temperate baseline
        
        return (estimatedLatitude, estimatedLongitude)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorized || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lock.lock()
        lastCoordinate = location.coordinate
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.onCoordinateUpdate?(location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Fall back quietly to timezone approximation without interrupting user workflow.
    }
}
