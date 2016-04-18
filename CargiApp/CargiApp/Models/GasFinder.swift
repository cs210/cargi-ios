//
//  GasFinder.swift
//  Cargi
//
//  Created by Maya Balakrishnan on 4/18/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import GoogleMaps

class GasFinder {
    // Google Maps API Key for Cargi
    let APIKey: String = "AIzaSyB6LumdXIastAI0rhSiSVTdLNStQb9UUP8"
    
    func getNearbyGas(currCoordinates: String?, completionHandler: ((status: String, success: Bool) -> Void)) {
        let placesURL: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        let radius: Int = 2000
        //        guard let location = currCoordinates?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) else {
        //            completionHandler(status: "current location is nil", success: false)
        //            return
        //        }
        //        print(location)
        
        let location: String = "37.4275,-122.1697"
        let type: String = "gas_station"
        let requestURL: String = "\(placesURL)location=\(location)&radius=\(radius)&type=\(type)&key=\(APIKey)"
        let request = NSURL(string: requestURL)
        // Get and parse the response.
        
        dispatch_async(dispatch_get_main_queue()) {
            guard let url = request else {
                completionHandler(status: "url is not valid", success: false)
                return
            }
            let data = NSData(contentsOfURL: url)
            print("JSON")
            
            // Convert JSON response into an NSDictionary.
            var json: [NSObject:AnyObject]?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? [NSObject:AnyObject]
            } catch {
                completionHandler(status: "Parsing JSON failed.", success: false)
                return
            }
            
            guard let dict = json else {
                completionHandler(status: "Parsing JSON failed.", success: false)
                return
            }
            
            print("HI")
            let status = dict["status"] as! String
            if status == "OK" {
                // General Route Information
                
                let gasStations = dict["results"] as! [[NSObject:AnyObject]]
                let selectedStation = gasStations.first!
                let stationName = selectedStation["name"] as! String
                let stationCoord = selectedStation["geometry"]!["location"] as! [NSObject:AnyObject]
                let stationLatitude = stationCoord["lat"] as! Double
                let stationLongitude = stationCoord["lng"] as! Double
                
                completionHandler(status: status, success: true)
            } else {
                completionHandler(status: status, success: false)
            }
        }
    }
    
}