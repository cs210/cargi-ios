//
//  CheapGasFinder.swift
//  Cargi
//
//  Created by Edwin Park on 5/1/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation

class CheapGasFinder {
    
    struct GasStation {
        var name: String?
        var price: String?
        var address: String?
        var number: String?
        var zip: String?
    }
    
    var stations: [GasStation] = []
    
    let baseURL: String = "https://gas-price-api.herokuapp.com/stations"
    
    func getCheapGasByPostalCode(postalCode: String, completionHandler: ((status: String, success: Bool) -> Void)) {
        getCheapGasByPostalCode(postalCode, count: Int.max, completionHandler: completionHandler)
    }
    
    func getCheapGasByPostalCode(postalCode: String, count: Int, completionHandler: ((status: String, success: Bool) -> Void)) {
        self.stations = [GasStation]()
        let requestURL: String = "\(baseURL)/\(postalCode)"
        let request = NSURL(string: requestURL)
        
        // Get and parse the response.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
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
            
            let retrievedStations = dict["stations"] as! [[NSObject:NSObject]]
            var i: Int = 0
            for st in retrievedStations {
                if i < count {
                var station = GasStation()
                    station.name = st["name"] as? String
                    station.address = st["address"] as? String
                    station.price = st["price"] as? String
                    station.number = st["number"] as? String
                    station.zip = st["zip"] as? String
                    self.stations.append(station)
                    i += 1
                } else {
                    break
                }
            }
            completionHandler(status: "OK", success: true)
        }
    }
    
}

// creds to Maya

