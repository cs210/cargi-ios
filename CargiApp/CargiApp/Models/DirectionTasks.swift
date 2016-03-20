//
//  RouteTasks.swift
//  Cargi
//
//  Created by Edwin Park on 3/20/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import GoogleMaps

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
    
    // travelMode will be driving, by default.
    func getDirections(origin: String?, dest: String?, waypoints: [String]!, travelMode: AnyObject!, completionHandler: ((status: String, success: Bool) -> Void)) {
        guard let originLocation = origin else {
            completionHandler(status: "Origin is nil", success: false)
            return
        }
        guard let destLocation = dest else {
            completionHandler(status: "Destination is nil", success: false)
            return
        }
        var requestURL: String = "\(baseURL)origin=\(originLocation)&destination=\(destLocation)&key=\(APIKey)"
        requestURL = requestURL.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let request = NSURL(string: requestURL)
        
        dispatch_async(dispatch_get_main_queue()) {
            guard let url = request else {
                print("url is not valid")
                return
            }
            let data = NSData(contentsOfURL: url)
            var json: [NSObject:AnyObject]?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? [NSObject:AnyObject]
            } catch {
                completionHandler(status: "", success: false)
            }
            
            guard let dict = json else { return }
            
            let status = dict["status"] as! String
            if status == "OK" {
                let routes = dict["routes"] as! [[NSObject:AnyObject]]
                self.selectedRoute = routes.first!
                self.overviewPolyline = self.selectedRoute["overview_polyline"] as! [NSObject:AnyObject]
                
                let legs = self.selectedRoute["legs"] as! [[NSObject:AnyObject]]
             
                let startLocationDictionary = legs.first!["start_location"] as! [NSObject:AnyObject]
                self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! CLLocationDegrees, startLocationDictionary["lng"] as! CLLocationDegrees)

                let endLocationDictionary = legs.last!["end_location"] as! [NSObject:AnyObject]
                self.destCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! CLLocationDegrees, endLocationDictionary["lng"] as! CLLocationDegrees)

                self.originAddress = legs.first!["start_address"] as! String
                self.destAddress = legs.last!["end_address"] as! String
                
                completionHandler(status: status, success: true)
            } else {
                completionHandler(status: status, success: false)
            }
            
        }
    }
    
}

