//
//  LatestKnowLocationManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 31/12/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import CoreLocation

class LatestKnowLocationManager: NSObject {
    public static let shared = LatestKnowLocationManager()
    
    private let locationManager = CLLocationManager()
    private var latestKnownLocationOfUser: CLLocation?
    
    private override init() {
        super.init()
        if (getCurrentStatus() == .authorizedWhenInUse || getCurrentStatus() == .authorizedAlways) {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        
        // TODO: Handle all state of authorization
    }
    
    func getCurrentStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    func getLatestPosition() -> CLLocation? {
        if locationManager.location != nil {
            return locationManager.location
        } else if latestKnownLocationOfUser != nil {
            return latestKnownLocationOfUser
        }
        return nil
    }
}

extension LatestKnowLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastKnownLocation = locations.last {
            latestKnownLocationOfUser = lastKnownLocation
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager error: \(error.code) - \(error.desc) - \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Latest know status: \(status)")
    }
}
