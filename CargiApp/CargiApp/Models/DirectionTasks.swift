//
//  RouteTasks.swift
//  Cargi
//
//  Created by Edwin Park on 3/20/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import GoogleMaps


/**
 Class that handles making requests to the Google Directions API and parsing responses.
 */
class DirectionTasks {
    
    // Google Maps API generic URL
    let baseURL: String = "https://maps.googleapis.com/maps/api/directions/json?"
    
    // Google Maps API Key for Cargi
    let APIKey: String = "AIzaSyB6LumdXIastAI0rhSiSVTdLNStQb9UUP8"
    
    // First route returned from the Directions API
    var selectedRoute: [NSObject:AnyObject]!
    
    // Contains points through which lines should be drawn.
    var overviewPolyline: [NSObject:AnyObject]!
    
    // Contains latitude and longitudes of origin and destination, respectively.
    var originCoordinate: CLLocationCoordinate2D!
    var destCoordinate: CLLocationCoordinate2D!
    
    // Formatted addresses contained in response returned by Directions API.
    var originAddress: String!
    var destAddress: String!
    
    // Used for calculating distance and time for the route, but not implemented yet.
    /*
    var totalDistanceMeters: UInt = 0
    var totalDistanceString: String!
    var totalTimeSeconds: UInt = 0
    var totalTimeString: String!
    */
    
    /**
        Gets the direction from origin to destination and populates the instance variables defined above.
        
        - Origin/Destination should be properly formatted using either:
            1) formatted address,
            2) coordinates (latitude & longitude) separated by comma.
        - Waypoints (optional) are required points that the route must go through.
        - Completion Handler will be called once the response is successfully received, so that ViewControllers can properly update the views.
    
        Note: travelMode will be driving by default.
     */
    func getDirections(origin: String?, dest: String?, waypoints: [String]?, completionHandler: ((status: String, success: Bool) -> Void)) {
        print("origin")
        guard let originLocation = origin?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) else {
            completionHandler(status: "Origin is nil", success: false)
            return
        }
        print("dest")
        guard let destLocation = dest?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) else {
            completionHandler(status: "Destination is nil", success: false)
            return
        }
        if destLocation.isEmpty {
            completionHandler(status: "Destination is nil", success: false)
            return
        }
        
        var waypoint = String()
        if let waypointsString = waypoints?.joinWithSeparator("|") {
            waypoint = "waypoints=\(waypointsString)"
        }
        print(waypoint)
        
        // URL for making request to the Google Directions API.
        let requestURL: String = "\(baseURL)origin=\(originLocation)&destination=\(destLocation)&\(waypoint)&key=\(APIKey)"
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
            print(dict.description)
            
            let status = dict["status"] as! String
            if status == "OK" {
                // General Route Information
                let routes = dict["routes"] as! [[NSObject:AnyObject]]
                self.selectedRoute = routes.first!
                self.overviewPolyline = self.selectedRoute["overview_polyline"] as! [NSObject:AnyObject]
                
                // Legs
                let legs = self.selectedRoute["legs"] as! [[NSObject:AnyObject]]
                
                // Start Location
                let startLocationDictionary = legs.first!["start_location"] as! [NSObject:AnyObject]
                self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! CLLocationDegrees, startLocationDictionary["lng"] as! CLLocationDegrees)
                
                // End Location
                let endLocationDictionary = legs.last!["end_location"] as! [NSObject:AnyObject]
                self.destCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! CLLocationDegrees, endLocationDictionary["lng"] as! CLLocationDegrees)
                
                // Addresses
                self.originAddress = legs.first!["start_address"] as! String
                self.destAddress = legs.last!["end_address"] as! String
                
                completionHandler(status: status, success: true)
            } else {
                completionHandler(status: status, success: false)
            }
            
        }
    }
    
}

