//
//  LocationServices.swift
//  Cargi
//
//  Created by Edwin Park on 3/6/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import GoogleMaps

class LocationServices {
    
    private enum MapsType {
        case AppleMaps
        case GoogleMaps
    }
    
    private static var type: MapsType = MapsType.GoogleMaps
    
    static func searchLocation(address: String) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarksOptional, error) -> Void in
            if let placemarks = placemarksOptional {
//                print("placemark| \(placemarks.first)")
                if let location = placemarks.first?.location {
                    if type == MapsType.AppleMaps {
                        searchLocationAppleMaps(location.coordinate.latitude, longitude: location.coordinate.longitude)
                    } else {
                        searchLocationGoogleMaps(location.coordinate.latitude, longitude: location.coordinate.longitude)
                    }
                } else {
                    // Could not get a location from the geocode request. Handle error.
                }
            } else {
                // Didn't get any placemarks. Handle error.
            }
        }
    }
    
    static func searchLocationAppleMaps(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let query = "?q=\(latitude),\(longitude)"
        let path = "http://maps.apple.com/" + query
        if let url = NSURL(string: path) {
            // UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?q=cupertino")!)
            UIApplication.sharedApplication().openURL(url)
        } else {
            // Could not construct url. Handle error.
        }
    }
    
    static func searchLocationGoogleMaps(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) {
            UIApplication.sharedApplication().openURL(NSURL(string:
                "comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)&directionsmode=driving")!)
            
        } else {
            print("Can't use comgooglemaps://");
        }
    }
    
    static func searchLocationAddress(address: String) {
        let queries = address.componentsSeparatedByString("\n")
        let addr = queries[0]
        let query = "?addr=\(addr)"
        let path = "http://maps.apple.com/" + query
        print(path)
        if let url = NSURL(string: path) {
            // UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?q=cupertino")!)
            print(path)
            UIApplication.sharedApplication().openURL(url)
        } else {
            // Could not construct url. Handle error.
        }
    }
    
    static func getCoords(address: String) -> CLLocation {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarksOptional, error) -> Void in
            if let placemarks = placemarksOptional {
                //                print("placemark| \(placemarks.first)")
                if let location = placemarks.first?.location {
                    return location
                } else {
                    // Could not get a location from the geocode request. Handle error.
                }
            } else {
                // Didn't get any placemarks. Handle error.
            }
        }
    }
    
}