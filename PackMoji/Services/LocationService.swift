import Foundation
import MapKit
import Combine
import CoreLocation

// 1. 创建一个遵守NSObject和MKLocalSearchCompleterDelegate协议的类
class LocationService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate, CLLocationManagerDelegate {
    
    // 2. 使用@Published包装补全结果，以便UI可以订阅变化
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var userCountryCode: String?
    
    private var completer: MKLocalSearchCompleter
    private let locationManager = CLLocationManager()
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.locationManager.delegate = self
        
        // Configure completer to prioritize cities
        self.completer.resultTypes = [.address]
        self.completer.pointOfInterestFilter = .excludingAll
    }
    
    // MARK: - Location Search
    
    // 3. 创建一个方法来更新查询词
    func updateQuery(_ queryFragment: String) {
        completer.queryFragment = queryFragment
    }
    
    // 4. 实现代理方法，当有新的补全结果时，此方法会被调用
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter results to only include city-level locations
        let cityResults = completer.results.filter { result in
            // Check if the result is likely a city
            let title = result.title.lowercased()
            let subtitle = result.subtitle.lowercased()
            
            // Exclude specific POIs, streets, or building numbers
            let excludeKeywords = ["street", "st.", "ave", "road", "rd.", "suite", "floor", "unit", "apartment", "apt", "#"]
            let hasExcludedKeywords = excludeKeywords.contains { keyword in
                title.contains(keyword.lowercased())
            }
            
            // Check for city indicators
            let cityIndicators = ["city", "town", "district", "province", "state", "region", "county"]
            let hasCityIndicator = cityIndicators.contains { indicator in
                subtitle.contains(indicator.lowercased())
            }
            
            // If the result has a number at the start, it's likely a street address
            let startsWithNumber = title.first?.isNumber ?? false
            
            // Accept results that:
            // 1. Don't start with numbers (not street addresses)
            // 2. Don't contain excluded keywords
            // 3. Either have a city indicator or have a simple format (city name + region)
            return !startsWithNumber && !hasExcludedKeywords && (hasCityIndicator || subtitle.split(separator: ",").count <= 2)
        }
        
        // Limit to top 5 results to keep the list manageable
        self.completions = Array(cityResults.prefix(5))
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // 处理错误
        print("Error fetching completions: \(error.localizedDescription)")
    }
    
    // MARK: - User Location
    
    func requestUserLocation() {
        print("LocationService: Requesting user location...")
        // We only need to know the country, so "when in use" is sufficient.
        locationManager.requestWhenInUseAuthorization()
        // The delegate method `didChangeAuthorization` will handle the next steps.
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("LocationService: Authorization status changed")
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("LocationService: Location authorized, requesting location...")
                manager.requestLocation() // Request a one-time location update
            case .denied, .restricted:
                print("Location access denied or restricted.")
                // Handle case where user denies permission. Maybe default to a specific country?
                self.userCountryCode = "US" // Fallback for testing
            case .notDetermined:
                print("LocationService: Authorization not determined yet")
                // This case is handled by the initial request.
                break
            @unknown default:
                break
            }
        } else {
            // Fallback for iOS 13 and earlier
            switch CLLocationManager.authorizationStatus() {
            case .authorizedWhenInUse, .authorizedAlways:
                print("LocationService: Location authorized (iOS 13), requesting location...")
                manager.requestLocation()
            case .denied, .restricted:
                print("Location access denied or restricted.")
                self.userCountryCode = "US"
            case .notDetermined:
                print("LocationService: Authorization not determined yet (iOS 13)")
                break
            @unknown default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // Reverse geocode to get the country code
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if let error = error {
                print("Reverse geocode failed with error: \(error.localizedDescription)")
                self?.userCountryCode = "US" // Fallback
                return
            }
            
            if let placemark = placemarks?.first, let countryCode = placemark.isoCountryCode {
                print("User's country code: \(countryCode)")
                self?.userCountryCode = countryCode
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
        self.userCountryCode = "US" // Fallback
    }
} 