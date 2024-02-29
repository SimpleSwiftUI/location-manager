//
//  LocationManager.swift
//  location-manager
//
//  Created by Robert Brennan on 2/28/24.
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocationCoordinate2D?
    @Published var searchResults = [MKLocalSearchCompletion]()
    @Published var locationPermissionDenied = false
    @Published var getCurrentLocationInProgress = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func getCurrentLocation() {
        self.getCurrentLocationInProgress = true
        locationManager.requestLocation()   // when this resolves, didUpdateLocations or didFailWithError (see below) will be called
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.first?.coordinate
        getCurrentLocationInProgress = false
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager.requestLocation failed. error: \(error.localizedDescription)")
    }
    
    func searchAddress(_ query: String) {
        searchCompleter.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("MKSearch completer failed. error: \(error.localizedDescription)")
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()     // alternatively: locationManager.requestAlwaysAuthorization()
    }
    
    private func locationManager(_ manager: CLLocation, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            getCurrentLocation()
            break
        case .denied, .restricted:
            locationPermissionDenied = true
            break
        case .notDetermined:
            print("location permission not determined")
            break
        default:
            break
        }
    }
    
    func geocodeAddress(_ address: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let error = error {
                completion(.failure(error))
            } else if let coordinate = placemarks?.first?.location?.coordinate {
                completion(.success(coordinate))
            }
        }
    }
    
    func getNearestAddress(latitude: Double, longitude: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(.failure(error))
            } else if let placemark = placemarks?.first {
                let addressParts = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.country].compactMap { $0 }
                let address = addressParts.joined(separator: ", ")
                completion(.success(address))
            } else {
                completion(.failure(NSError(domain: "LocationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to find address"])))
            }
        }
    }
}
