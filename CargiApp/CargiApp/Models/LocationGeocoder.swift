//
//  LocationServices.swift
//  Cargi
//
//  Created by Edwin Park on 3/6/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import GoogleMaps


/**
    Class for converting between addresses and coordinates using geocoders.
 
    Can use Google Maps or Apple Maps, depending on preference.
 */
class LocationGeocoder {
    
    var address: String?
    var coordinate: CLLocationCoordinate2D?
    var postalCode: String?
    
    func getCoordinates(address: String, completionHandler: ((status: String, success: Bool) -> Void)) {
        self.address = address
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) -> Void in
            if let err = error {
                completionHandler(status: String(err), success: false)
                return
            }
            
            guard let location = placemarks?.first?.location else {
                completionHandler(status: "no address found", success: false)
                return
            }
            
            self.coordinate = location.coordinate
            completionHandler(status: "OK", success: true)
        }
    }
    
    func getPostalCode(location: CLLocation, completionHandler: ((status: String, success: Bool) -> Void)) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let err = error {
                completionHandler(status: String(err), success: false)
                return
            }
            
            guard let pms = placemarks else {
                completionHandler(status: "No placemarks found", success: false)
                return
            }
            
            for pm in pms {
                if let zipCode = pm.postalCode {
                    self.postalCode = zipCode
                    completionHandler(status: "OK", success: true)
                    return
                }
            }
            completionHandler(status: "No ZIP Code found", success: false)
        }
    }
}