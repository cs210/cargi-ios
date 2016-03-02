//
//  NavigationViewController.swift
//  CargiApp
//
//  Created by Edwin Park on 2/25/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit
import GoogleMaps

class NavigationViewController: UIViewController, NSURLConnectionDataDelegate {
    
    @IBOutlet var mapView: UIView!
    
    var map: GMSMapView?
    var marker: GMSMarker = GMSMarker()
    var data: NSData?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let camera = GMSCameraPosition.cameraWithLatitude(-33.86,
            longitude: 151.20, zoom: 6)
//        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        let mapView = GMSMapView.mapWithFrame(CGRectMake(20, 20, 340, 600), camera: camera)
        
        mapView.myLocationEnabled = true
        self.mapView = mapView
        self.map = mapView
        
        marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(-33.86, 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = mapView

        view.addSubview(self.mapView)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        print("connectionDidFinishLoading")
        let stringData: NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        print(stringData)
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        print("YAY!")
        self.data = data
    }
    
    @IBAction func searchButtonClicked(sender: UIButton) {
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        self.presentViewController(acController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension NavigationViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        print("Place coordinates: \(place.coordinate)")
        self.dismissViewControllerAnimated(true, completion: nil)
        map?.camera = GMSCameraPosition.cameraWithTarget(place.coordinate, zoom: 12)
        marker.position = place.coordinate
        marker.title = place.name
        marker.map = map
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        // TODO: handle the error.
        print("Error: \(error.description)", terminator: "")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // User canceled the operation.
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        print("Autocomplete was cancelled.", terminator: "")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
