import CoreLocation
import Observation

@Observable
@MainActor
final class LocationProvider {
    var coordinate: CLLocationCoordinate2D?
    var placeName: String?
    var error: String?

    private let manager = CLLocationManager()
    private let delegate = Delegate()

    init() {
        delegate.owner = self
        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    fileprivate func didUpdate(_ location: CLLocation) {
        let coord = location.coordinate
        self.coordinate = coord
        manager.stopUpdatingLocation()

        let geocoder = CLGeocoder()
        Task {
            if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                self.placeName = placemark.locality ?? placemark.administrativeArea
            }
        }
    }

    fileprivate func didFail(_ err: Error) {
        if let clErr = err as? CLError, clErr.code == .denied {
            self.error = "Location access needed for weather"
        } else {
            self.error = err.localizedDescription
        }
    }

    // MARK: - Delegate

    private final class Delegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
        weak var owner: LocationProvider?

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            Task { @MainActor [weak owner] in
                owner?.didUpdate(location)
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            Task { @MainActor [weak owner] in
                owner?.didFail(error)
            }
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            let status = manager.authorizationStatus
            #if os(macOS)
            let authorized = status == .authorizedAlways
            #else
            let authorized = status == .authorizedAlways || status == .authorizedWhenInUse
            #endif
            if authorized {
                manager.startUpdatingLocation()
            } else if status == .denied || status == .restricted {
                Task { @MainActor [weak owner] in
                    owner?.error = "Location access needed for weather"
                }
            }
        }
    }
}
