//
//  ViewModel.swift
//  location-manager
//
//  Created by Robert Brennan on 2/28/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import MapKit
import CoreLocation

class ViewModel: ObservableObject {
    private var managedObjectContext: NSManagedObjectContext
    private var locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var userLatitude: Double = 0.0
    @Published var userLongitude: Double = 0.0
    @Published var userAddress: String = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var useCurrentLocationTapped = false
    @Published var getCurrentLocationInProgress = false
    
    @AppStorage("locationPermissionDenied") var locationPermissionDenied = false
    
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
                
        locationManager.$lastLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                if self?.useCurrentLocationTapped != false {
                    self?.userLatitude = coordinate.latitude
                    self?.userLongitude = coordinate.longitude
                    self?.fetchAddress()
                }
            }
            .store(in: &cancellables)
        
        locationManager.$searchResults
            .sink { [weak self] results in
                self?.searchResults = results
            }
            .store(in: &cancellables)
        
        locationManager.$locationStatus
            .sink { [weak self] result in
                self?.locationStatus = result
            }
            .store(in: &cancellables)
        
        locationManager.$locationPermissionDenied
            .sink { [weak self] result in
                self?.locationPermissionDenied = result
            }
            .store(in: &cancellables)
        
        locationManager.$getCurrentLocationInProgress
            .sink { [weak self] result in
                self?.getCurrentLocationInProgress = result
            }
            .store(in: &cancellables)
    }
    
    func getCurrentLocation() {
        locationManager.getCurrentLocation()
    }
    
    func searchAddress(_ query: String) {
        locationManager.searchAddress(query)
    }
    
    func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request: searchRequest).start { [weak self] (response, error) in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            self?.userLatitude = coordinate.latitude
            self?.userLongitude = coordinate.longitude
            self?.userAddress = "\(result.title), \(result.subtitle)"
            self?.geocodeAddress("\(result.title), \(result.subtitle)")
        }
    }
    
    func clearSearchResults() {
        self.searchResults = []
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
        self.objectWillChange.send()
    }
    
    func checkLocationPermission() -> String {
        guard let status = locationManager.locationStatus else {
            return "unavailable"
        }
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return "available"
        case .notDetermined, .restricted, .denied:
            return "unavailable"
        default:
            return "unavailable"
        }
    }
    
    func geocodeAddress(_ address: String) {
        locationManager.geocodeAddress(address) { [weak self] result in
            switch result {
            case .success(let coordinate):
                self?.userLatitude = coordinate.latitude
                self?.userLongitude = coordinate.longitude
                self?.fetchAddress()
            case .failure(let error):
                print("geocodeAddress failed. error: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAddress() {
        guard userLatitude != 0.0 && userLongitude != 0.0 else { return }
        
        locationManager.getNearestAddress(latitude: userLatitude, longitude: userLongitude) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let address):
                    print("fetchAddress address:", address)
                    self?.userAddress = address
                    self?.getCurrentLocationInProgress = false
                case .failure:
                    self?.userAddress = "Location error"
                    self?.getCurrentLocationInProgress = false
                }
            }
        }
    }
}
