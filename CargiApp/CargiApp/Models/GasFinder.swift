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
    
    struct GasStation {
        var name: String!
        var coordinates: CLLocationCoordinate2D!
        var placeID: String!
        var address: String!
    }
    
    // Google Maps API Key for Cargi
    let APIKey: String = "AIzaSyB6LumdXIastAI0rhSiSVTdLNStQb9UUP8"
    let baseURL: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"

    var stationName: String!
    var coordinates: CLLocationCoordinate2D!
    var placeID: String!
    var address: String!
    
    func getNearbyGas(origin: String?, completionHandler: ((status: String, success: Bool) -> Void)) {
        guard let originLocation = origin?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) else {
            completionHandler(status: "Origin is nil", success: false)
            return
        }
    
        let type: String = "gas_station"
        let rankBy: String = "distance"
//        let openNow: String = "opennow"
        let requestURL: String = "\(baseURL)location=\(originLocation)&type=\(type)&rankby=\(rankBy)&key=\(APIKey)"
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
            print("\n\n\n\n\n\n\n")
//            print(dict.description)
            let status = dict["status"] as! String
            if status == "OK" {
                // General Gas Information
                let gasStations = dict["results"] as! [[NSObject:AnyObject]]
                let selectedStation = gasStations.first!
                print(selectedStation.description)
                self.stationName = selectedStation["name"] as! String
                self.placeID = selectedStation["place_id"] as! String
                self.address = selectedStation["vicinity"] as! String
                let stationCoord = selectedStation["geometry"]!["location"] as! [NSObject:AnyObject]
                let stationLatitude = stationCoord["lat"] as! Double
                let stationLongitude = stationCoord["lng"] as! Double
                self.coordinates = CLLocationCoordinate2D(latitude: stationLatitude, longitude: stationLongitude)
                completionHandler(status: status, success: true)
            } else {
                completionHandler(status: status, success: false)
            }
        }
    }
    
}