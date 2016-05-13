//
//  DistanceMatrixTasks.swift
//  Cargi
//
//  Created by Edwin Park on 4/3/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import GoogleMaps


/**
 Class that handles making requests to the Google Directions API and parsing responses.
 */
class DistanceMatrixTasks {
    
    // Google Maps API generic URL
    let baseURL: String = "https://maps.googleapis.com/maps/api/distancematrix/json?"
    
    // Google Maps API Key for Cargi
    let APIKey: String = "AIzaSyB6LumdXIastAI0rhSiSVTdLNStQb9UUP8"
    
    // For traffic model, we have best_guess, pessimistic, or optimistic.
    let trafficModel: TrafficModel = .BestGuess
    
    // Formatted addresses contained in response returned by Directions API.
    var originAddress: String!
    var destAddress: String!
    
    // Distance
    var distanceText: String!
    var distanceValue: Int!
    
    // Duration
    var durationText: String!
    var durationValue: Int!
    
    // Duration in Traffic
    var durationInTrafficText: String!
    var durationInTrafficValue: Int!
    
    enum TrafficModel: String {
        case BestGuess = "best_guess"
        case Pessimistic = "pessimistic"
        case Optimistic = "optimistic"
    }
    
    /// Makes a request to get the estimated time from origin to destination using addresses.
    func getETA(origin: String?, dest: String?, completionHandler: ((status: String, success: Bool) -> Void)) {
        // Verify that the passed parameters for origin and destination are valid.
        guard let originLocation = origin?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) else {
            completionHandler(status: "Origin is nil", success: false)
            return
        }
        guard let destLocation = dest?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) else {
            completionHandler(status: "Destination is nil", success: false)
            return
        }
        
        // URL for making request to the Google Distance Matrix API.
        let requestURL: String = "\(baseURL)origins=\(originLocation)&destinations=\(destLocation)&model=driving&key=\(APIKey)&departure_time=now&traffic_model=\(trafficModel.rawValue)"
        let request = NSURL(string: requestURL)
        parseResponse(request, completionHandler: completionHandler)
    }
    
    
    /*
     Get ETA to a destination using GPS coordinates.
     Makes a request to get the estimated time from origin to destination.
     */
    func getETA(origin1: CLLocationDegrees, origin2: CLLocationDegrees, dest1: CLLocationDegrees, dest2: CLLocationDegrees, completionHandler: ((status: String, success: Bool) -> Void)) {
        // URL for making request to the Google Distance Matrix API.
        let dest = "\(dest1),\(dest2))"
        getETA(origin1, origin2: origin2, dest: dest, completionHandler: completionHandler)
        
        /*
        let requestURL: String = "\(baseURL)origins=\(origin1),\(origin2)&destinations=\(dest1),\(dest2)&model=driving&key=\(APIKey)&departure_time=now&traffic_model=\(trafficModel.rawValue)"
        let request = NSURL(string: requestURL)
        parseResponse(request, completionHandler: completionHandler)
         */
    }
    
    /*
     Get ETA to a destination using address.
     Makes a request to get the estimated time from origin to destination.
     */
    func getETA(origin1: CLLocationDegrees, origin2: CLLocationDegrees, dest: String, completionHandler: ((status: String, success: Bool) -> Void)) {
        // URL for making request to the Google Distance Matrix API.
        guard let destLocation = dest.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) else {
            completionHandler(status: "Destination is nil", success: false)
            return
        }
        if destLocation.isEmpty {
            completionHandler(status: "Destination is nil", success: false)
            return
        }
        
        let requestURL: String = "\(baseURL)origins=\(origin1),\(origin2)&destinations=\(destLocation)&model=driving&key=\(APIKey)&departure_time=now&traffic_model=\(trafficModel.rawValue)"
        let request = NSURL(string: requestURL)
        parseResponse(request, completionHandler: completionHandler)
    }
    
    // Parse response and store into the instance variables defined above.
    private func parseResponse(request: NSURL?, completionHandler: ((status: String, success: Bool) -> Void)) {
        // Get and parse the response.
        dispatch_async(dispatch_get_main_queue()) {
            guard let url = request else {
                print("url is not valid")
                return
            }
            let data = NSData(contentsOfURL: url)
            
            // Convert JSON response into an NSDictionary.
            var json: [NSObject:AnyObject]?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? [NSObject:AnyObject]
            } catch {
                completionHandler(status: "", success: false)
            }
            
            guard let dict = json else {
                completionHandler(status: "Parsing JSON failed.", success: false)
                return
            }
            print(dict.description)
            
            let status = dict["status"] as! String
            if status == "OK" {
                self.originAddress = dict["origin_addresses"]?.firstObject as! String
                self.destAddress = dict["destination_addresses"]?.firstObject as! String
                
                let rows = dict["rows"] as! [[NSObject:AnyObject]]
                let row = rows.first!
                let elems = row["elements"] as! [[NSObject:AnyObject]]
                let elem = elems.first!
                
                let distance = elem["distance"] as! [NSObject:AnyObject]
                self.distanceText = distance["text"] as! String
                self.distanceValue = distance["value"] as! Int
                
                let duration = elem["duration"] as! [NSObject:AnyObject]
                self.durationText = duration["text"] as! String
                self.durationValue = duration["value"] as! Int
                
                let durationInTraffic = elem["duration_in_traffic"] as! [NSObject:AnyObject]
                self.durationInTrafficText = durationInTraffic["text"] as! String
                self.durationInTrafficValue = durationInTraffic["value"] as! Int
                
                print(self.durationInTrafficText)
                completionHandler(status: status, success: true)
            } else {
                completionHandler(status: status, success: false)
            }
        }
    }
    
}