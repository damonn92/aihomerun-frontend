import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationName: String = "Locating..."
    @Published var errorMessage: String?

    private let clManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var geocodeRetryCount = 0
    private var lastGeocodedLocation: CLLocation?
    private var isGeocoding = false

    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isLocationAvailable: Bool {
        hasPermission && userLocation != nil
    }

    private override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        clManager.distanceFilter = 200
        authorizationStatus = clManager.authorizationStatus
    }

    func requestPermission() {
        clManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard hasPermission else { return }
        clManager.startUpdatingLocation()
    }

    func stopUpdating() {
        clManager.stopUpdatingLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        // Skip if already geocoding
        guard !isGeocoding else { return }

        // Skip if location hasn't changed significantly (> 500m) from last successful geocode
        if let last = lastGeocodedLocation,
           location.distance(from: last) < 500,
           locationName != "Locating...",
           locationName != "Unknown Location" {
            return
        }

        isGeocoding = true
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isGeocoding = false

                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.subAdministrativeArea ?? ""
                    let state = placemark.administrativeArea ?? ""
                    if !city.isEmpty && !state.isEmpty {
                        self.locationName = "\(city), \(state)"
                    } else if !city.isEmpty {
                        self.locationName = city
                    } else {
                        self.locationName = placemark.name ?? "Unknown Location"
                    }
                    self.lastGeocodedLocation = location
                    self.geocodeRetryCount = 0
                } else if error != nil {
                    // Retry up to 3 times with increasing delay
                    if self.geocodeRetryCount < 3 {
                        self.geocodeRetryCount += 1
                        let delay = Double(self.geocodeRetryCount) * 2.0
                        Task {
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            self.reverseGeocode(location)
                        }
                    } else {
                        self.locationName = "Unknown Location"
                    }
                } else {
                    self.locationName = "Unknown Location"
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Filter out stale or inaccurate locations
        let age = -location.timestamp.timeIntervalSinceNow
        guard age < 15, location.horizontalAccuracy >= 0, location.horizontalAccuracy < 1000 else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.userLocation = location.coordinate
            self.errorMessage = nil
            // Geocode on every significant location update (reverseGeocode has dedup logic)
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdating()
            } else if status == .denied || status == .restricted {
                self.locationName = "Location Unavailable"
                self.errorMessage = "Location access denied. You can search by address instead."
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let clError = error as? CLError, clError.code == .denied {
                self.locationName = "Location Unavailable"
            } else {
                self.errorMessage = "Unable to determine location."
            }
        }
    }
}
