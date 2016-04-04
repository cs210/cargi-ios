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
class LocationServices {
    
    // Types of Maps that can be used.
    private enum MapsType {
        // Apple Maps
        case AppleMaps
        
        // Google Maps
        case GoogleMaps
    }
    
    private static var defaultMap: MapsType = MapsType.GoogleMaps // hard-coded to Google Maps, but may change depending on user's preference.
    
    /**
        Convert from street address to coordinates, and open appropriate maps/navigation app showing the directions/route to those coordinates.
     */
    static func searchLocation(address: String) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarksOptional, error) -> Void in
            if let placemarks = placemarksOptional {
//                print("placemark| \(placemarks.first)")
                if let location = placemarks.first?.location {
                    // if Google Maps exists, then use Google Maps. Otherwise, use Apple Maps.
                    if defaultMap == MapsType.GoogleMaps {
                        if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) {
                            searchLocationGoogleMaps(location.coordinate.latitude, longitude: location.coordinate.longitude)
                            return
                        }
                    }
                    // No need for checking whether Apple Maps exists, since the app exists on all iOS devices by default.
                    searchLocationAppleMaps(location.coordinate.latitude, longitude: location.coordinate.longitude)
                    
                } else {
                    // Could not get a location from the geocode request. Handle error.
                }
            } else {
                // Didn't get any placemarks. Handle error.
            }
        }
    }
    
    /**
        Open Apple Maps showing the route to the given coordinates.
     */
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
    
    /**
        Open Google Maps showing the route to the given coordinates.
     */
    static func searchLocationGoogleMaps(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) {
            UIApplication.sharedApplication().openURL(NSURL(string:
                "comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)&directionsmode=driving")!)
            
        } else {
            print("Can't use comgooglemaps://");
        }
    }
    
    /**
        Open Apple Maps showing the route to the given address.
     */
    static func searchLocationAddress(address: String) {
        let queries = address.componentsSeparatedByString("\n")
        let addr = queries[0]
        let query = "?addr=\(addr)"
        let path = "http://maps.apple.com/" + query // might need to convert to percent-escape encoding.
        print(path)
        if let url = NSURL(string: path) {
            // UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?q=cupertino")!)
            print(path)
            UIApplication.sharedApplication().openURL(url)
        } else {
            // Could not construct url. Handle error.
        }
    }
    
//    static func getCoords(address: String) {
//        let geocoder = CLGeocoder()
//        
//        geocoder.geocodeAddressString(address) { (placemarksOptional, error) -> Void in
//            if let placemarks = placemarksOptional {
//                //                print("placemark| \(placemarks.first)")
//                if let location = placemarks.first?.location {
//                    return location
//                } else {
//                    // Could not get a location from the geocode request. Handle error.
//                }
//            } else {
//                // Didn't get any placemarks. Handle error.
//            }
//        }
//    }
    
}