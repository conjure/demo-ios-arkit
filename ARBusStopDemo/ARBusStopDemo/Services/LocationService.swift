//
//  LocationService.swift
//  BusTimes-MVVM
//
//  Created by Ade Adegoke on 04/02/2023.
//

import Foundation
import CoreLocation

protocol LocationServicesDelegate: AnyObject {
    func getUserAuthorizationStatus(_ status: Status)
    func getUserCurrentLatLonCoordinates(_ coordinate: Coordinate)
}

enum Status {
    case notDetermined, disabled, denied, authorised
}

final class LocationService: NSObject {
    static var shared = LocationService()
    private var didReceiveLocation = false
    private let locationManager = CLLocationManager()
    private var status: Status = .notDetermined
    
    weak var delegate: LocationServicesDelegate?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        usersCurrentLocation()
    }
    
    func usersCurrentLocation() {
        let authorizationStatus = locationManager.authorizationStatus

        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                switch authorizationStatus {
                case .notDetermined:
                    self.status = .notDetermined
                    self.locationManager.requestWhenInUseAuthorization()
                    self.delegate?.getUserAuthorizationStatus(self.status)
                case .restricted, .denied:
                    self.status = .denied
                    self.delegate?.getUserAuthorizationStatus(self.status)
                case .authorizedAlways, .authorizedWhenInUse:
                    self.status = .authorised
                    self.locationManager.startUpdatingLocation()
                    self.delegate?.getUserAuthorizationStatus(self.status)
                @unknown default:
                    self.status = .notDetermined
                    self.delegate?.getUserAuthorizationStatus(self.status)
                }
            } else {
                self.status = .authorised
                self.delegate?.getUserAuthorizationStatus(self.status)
            }
        }
        
    }
}

extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined, .restricted, .denied:
            self.status = .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            self.status = .authorised
            self.locationManager.startUpdatingLocation()
        @unknown default:
            self.status = .authorised
        }
    }
    
    func locationManager(_ coreLocationManager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if didReceiveLocation { return }
        guard let location = locations.last else { return }
        didReceiveLocation = true
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        coreLocationManager.stopUpdatingLocation()
        let currentCoordinate = (latitude, longitude)
        
        delegate?.getUserCurrentLatLonCoordinates(currentCoordinate)
    }
}
