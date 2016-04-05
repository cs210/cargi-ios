//
//  NavigationViewController.swift
//  CargiApp
//
//  Created by Edwin Park on 2/25/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreBluetooth
import MessageUI
import EventKit
import QuartzCore

class NavigationViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate,
                                MFMessageComposeViewControllerDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    
    // Types of Maps that can be used.
    private enum MapsType {
        // Apple Maps
        case Apple
        
        // Google Maps
        case Google
    }
    
    private var defaultMap: MapsType = MapsType.Google // hard-coded to Google Maps, but may change depending on user's preference.
    
    var marker: GMSMarker = GMSMarker()
    var data: NSMutableData = NSMutableData()
    
    @IBOutlet weak var destLabel: UILabel!
    @IBOutlet weak var addrLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var destinationView: UIView!
    
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var gasButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet var dashboardView: UIView!
    @IBOutlet var contactName: UILabel!
    
    var locationManager = CLLocationManager()
    var didFindMyLocation = false // avoid unnecessary location updates
    let defaultLatitude: CLLocationDegrees = 37.426
    let defaultLongitude: CLLocationDegrees = -122.172
    var destLatitude = String()
    var destLongitude = String()
    
    var manager: CBCentralManager! // Bluetooth Manager
    var currentEvent: EKEvent?
    
    var eventDirectory = EventDirectory()
    
    var contactDirectory = ContactDirectory()
    var contact: String?
    var contactNumbers: [String]?
    
    var directionTasks = DirectionTasks() // Google Directions
    var syncRouteSuccess: Bool?
    var destMarker = GMSMarker()
    var routePolyline = GMSPolyline() // lines that will show the route.
    var routePolylineBorder = GMSPolyline()
    var routePath = GMSPath()
    
    var distanceTasks = DistanceMatrixTasks()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.sendSubviewToBack(dashboardView)
        view.sendSubviewToBack(mapView)
        let layer: CALayer = self.dashboardView.layer
        layer.shadowOffset = CGSizeMake(1, 1)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 1.5
        layer.shadowOpacity = 0.7
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
        
        // Design of Buttons
        callButton.layer.shadowOffset = CGSizeMake(0, 3)
        callButton.layer.shadowColor = UIColor.blackColor().CGColor
        callButton.layer.shadowRadius = 2
        callButton.layer.shadowOpacity = 0.27
        
        textButton.layer.shadowOffset = CGSizeMake(0, 3)
        textButton.layer.shadowColor = UIColor.blackColor().CGColor
        textButton.layer.shadowRadius = 2
        textButton.layer.shadowOpacity = 0.27
        
        destinationView.layer.shadowOffset = CGSizeMake(0, -1)
        destinationView.layer.shadowColor = UIColor.blackColor().CGColor
        destinationView.layer.shadowRadius = 1.5
        destinationView.layer.shadowOpacity = 0.7
        
        // Observer for changes in myLocation of google's map view
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        mapView.settings.compassButton = true
        syncData()
    }
    
    /// When the app starts, update the maps view so that it shows the user's current location in the center.
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            guard let routeSuccess = syncRouteSuccess else { return }
            if !routeSuccess {
                mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 15.0)
            }
            didFindMyLocation = true
        }
    }
    
    
    /// Sync with Apple Calendar to get the current calendar event, and update the labels given this event's information.
    func syncData() {
        let contacts = contactDirectory.getAllPhoneNumbers()
        guard let events = eventDirectory.getAllCalendarEvents() else { return }
        
        for ev in events {
            guard let _ = ev.location else { continue } // ignore event if it has no location info.
            for contact in contacts.keys {
                if ev.title.rangeOfString(contact) != nil {
                    currentEvent = ev
                    self.contact = contact
                }
            }
        }
        
        contactNumbers = contactDirectory.getPhoneNumber(contact)

        guard let ev = currentEvent else { return }
        print(ev.eventIdentifier)
        contactName.text = self.contact
        eventLabel.text = ev.title
        
        guard let coordinate = ev.structuredLocation?.geoLocation?.coordinate else { return }
        destLatitude = String(coordinate.latitude)
        destLongitude = String(coordinate.longitude)
        if let loc = ev.location {
            let locArr = loc.characters.split { $0 == "\n" }.map(String.init)
            if locArr.count > 1 {
                destLabel.text = locArr[0]
                addrLabel.text = locArr[1]
            } else {
                addrLabel.text = locArr[0]
            }
        }
        print("showroute")
        showRoute()
    }

    /**
        Open Google Maps showing the route to the given coordinates.
     */
    func openGoogleMapsLocation(coordinate: CLLocationCoordinate2D) {
        UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?saddr=&daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")!)
    }
    
    
    /**
        Open Google Maps showing the route to the given address.
     */
    func openGoogleMapsLocationAddress(address: String) {
        let path = "comgooglemaps://saddr=&?daddr=\(address)&directionsmode=driving"
        print(path)
        guard let url = NSURL(string: path) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    /**
        Open Apple Maps showing the route to the given coordinates.
     */
    func openAppleMapsLocation(coordinate: CLLocationCoordinate2D) {
        guard let query = currentEvent?.location else { return }
        let address = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        let near = "\(coordinate.latitude),\(coordinate.longitude)"
        let path = "http://maps.apple.com/?q=\(address)&near=\(near)"
        guard let url = NSURL(string: path) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    /**
        Open Apple Maps showing the route to the given address.
     */
    func openAppleMapsLocationAddress(address: String) {
        let path = "http://maps.apple.com/?daddr=\(address)&dirflg=d"
        guard let url = NSURL(string: path) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    /**
        Open Maps, given the current event's location.
     */
    func openMaps() {
        guard let ev = currentEvent else { return }
        let queries = ev.location!.componentsSeparatedByString("\n")
        guard let query = queries.last else { return }
        let address = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        
        if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
            self.openGoogleMapsLocationAddress(address)
        } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
            self.openAppleMapsLocationAddress(address)
        }
        
        /* Only if Geocoder is needed */
/*
        switch CLLocationManager.authorizationStatus() {
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                let geocoder = LocationGeocoder()
                geocoder.getCoordinates(ev.location!) { (status, error) in
                    guard let coordinate = geocoder.coordinate else {
                        print(error)
                        return
                    }
                    // Use Google Maps if it exists. Otherwise, use Apple Maps.
                    print(ev.location!)
                    if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
                        self.openGoogleMapsLocation(coordinate)
                    } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
                        self.openAppleMapsLocation(coordinate)
                    }
                }
            default: break
        }
*/
    }
    
    /// Location is updated.
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("updating location")
    }
    

    
    /// Update the Google Maps view with the synced route, depending on whether we've successfully received the response from Google Directions API.
    func showRoute() {
        guard let _ = currentEvent else {
            syncRouteSuccess = false
            return
        }
        guard let originLocation = locationManager.location?.coordinate else {
            syncRouteSuccess = false
            return
        }
        let origin = "\(originLocation.latitude),\(originLocation.longitude)"
        let dest = addrLabel.text!
        print("getting directions")
        self.directionTasks.getDirections(origin, dest: dest, waypoints: nil) { (status, success) in
            print("got directions")
            if success {
                self.syncRouteSuccess = true
                print("success")
                self.configureMap()
                self.drawRoute()
            } else {
                self.syncRouteSuccess = false
                print(status)
            }
        }
    }
    
    /// Shows a pin at the destination on the map.
    private func configureMap() {
        destMarker.position = directionTasks.destCoordinate
        destMarker.map = mapView
        destMarker.icon = UIImage(named: "destination_icon")
        print("configure maps done")
    }
    
    
    /// Draws the route using polylines obtained from Google Directions.
    private func drawRoute() {
        let route = self.directionTasks.overviewPolyline["points"] as! String
        
        // Draw the path
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline.path = path
        routePolyline.map = mapView
        routePolyline.strokeColor = UIColor(red: 109/256, green: 180/256, blue: 245/256, alpha: 1.0)
        routePolyline.strokeWidth = 4.0
        routePolyline.zIndex = 10
        
        // Draw the border around the path
        routePolylineBorder.path = path
        routePolylineBorder.strokeColor = UIColor.blackColor()
        routePolylineBorder.strokeWidth = routePolyline.strokeWidth + 0.5
        routePolylineBorder.zIndex = routePolyline.zIndex - 1
        routePolylineBorder.map = mapView
        print("drawmaps done")
        
        let bounds = GMSCoordinateBounds(path: path)
        let cameraUpdate = GMSCameraUpdate.fitBounds(bounds, withEdgeInsets: UIEdgeInsets(top: 165.0, left: 20.0, bottom: 165.0, right: 20.0))
        mapView.moveCamera(cameraUpdate)
    }
    
    
    /// Starts a phone call with the first phone number in the given list of phone numbers.
    func callPhone(phoneNumbers: [String]?) {
        guard let numbers = phoneNumbers else { return }
        let number = numbers[0] as NSString
        let charactersToRemove = NSCharacterSet.alphanumericCharacterSet().invertedSet
        let numberToCall = number.componentsSeparatedByCharactersInSet(charactersToRemove).joinWithSeparator("")
        
        let stringURL = "tel://\(numberToCall)"
        print(stringURL)
        guard let url = NSURL(string: stringURL) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    
    /// Opens up a message view with a preformatted message that shows destination and ETA.
    func sendMessage(phoneNumbers: [String]?, duration: String) {
        guard let numbers = phoneNumbers else { return }
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            let firstName = contact?.componentsSeparatedByString(" ").first
            controller.body = "Hi \(firstName!), I will arrive at \(destLabel.text!) in \(duration)."
            controller.recipients = [numbers[0]] // Send only to the primary number
            print(controller.recipients)
            controller.messageComposeDelegate = self
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    
    /// Show location on the Google Maps view if the user has given the app access to user's location.
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.myLocationEnabled = true
        }
    }
    
    /// Close the message view screen once the message is sent.
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    
    /// Print all contacts in text format to the console.
    private func printContacts() {
        // Print all the contacts
        let contacts = contactDirectory.getAllPhoneNumbers()
        for (contact, numbers) in contacts {
            for number in numbers {
                print(contact + ": " + number)
            }
        }
    }
    
    /// Print all events in text format to the console.
    private func printEvents() {
        // Print all events in calendars.
        guard let events = eventDirectory.getAllCalendarEvents() else { return }
        for ev in events {
            print("EVENT: \(ev.title)" )
            print("\t-startDate: \(ev.startDate)" )
            print("\t-endDate: \(ev.endDate)" )
            if let location = ev.location {
                print("\t-location: \(location)")
            }
            print("\n")
        }
    }
    
    /// Print all reminders in text format to the console.
    private func printReminders() {
        // Print all reminders
        let reminders = eventDirectory.getAllReminders()
        print("REMINDERS:")
        print(reminders?.description)
    }
    
    
    // MARK: Core Bluetooth Manager Methods
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Peripheral: \(peripheral)")
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral")
        print(peripheral.description)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("Checking")
        switch(central.state)
        {
        case.Unsupported:
            print("BLE is not supported")
        case.Unauthorized:
            print("BLE is unauthorized")
        case.Unknown:
            print("BLE is Unknown")
        case.Resetting:
            print("BLE is Resetting")
        case.PoweredOff:
            print("BLE service is powered off")
        case.PoweredOn:
            print("BLE service is powered on")
            print("Start Scanning")
            manager.scanForPeripheralsWithServices(nil, options: nil)
        }
    }
    
    
    // MARK: IBAction Methods
    
    /// Refresh Button Clicked
    @IBAction func refreshButtonClicked(sender: UIButton) {
        syncData()
    }
    
    /// Navigate Button clicked.
    @IBAction func navigateButtonClicked(sender: UIButton) {
        if let _ = currentEvent {
            openMaps()
        } else {
            syncData()
            openMaps()
        }
    }
    
    
    /// Gas Button clicked
    @IBAction func gasButtonClicked(sender: UIButton) {
        let alert = UIAlertController(title: "Under Construction", message: "Oh no, Cargi is low on gas!", preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(alertAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    /// Send Message Button clicked.
    @IBAction func messageButtonClicked(sender: UIButton) {
        let locValue: CLLocationCoordinate2D = locationManager.location!.coordinate
        distanceTasks.getETA(locValue.latitude.description, origin2: locValue.longitude.description, dest1: destLatitude, dest2: destLongitude) { (status, success) in
            self.sendMessage(self.contactNumbers, duration: self.distanceTasks.durationInTrafficText)
        }
    }
    
    /// Search Button clicked
    @IBAction func searchButtonClicked(sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    
    /// Starts a phone call using the phone number associated with current event.
    @IBAction func phoneButtonClicked(sender: UIButton) {
        callPhone(contactNumbers)
    }
    
    /// Opens the Apple Calendar app, using deep-linking.
    @IBAction func eventButtonClicked(sender: UIButton) {
        let appName: String = "calshow"
        let appURL: String = "\(appName):"
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!) {
            print(appURL)
            UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
        }
    }
    
    /// Opens the music app of preference, using deep-linking.
    // Music app options: Spotify (default) and Apple Music
    @IBAction func musicButtonClicked(sender: UIButton) {
        let appName: String = "spotify"
        
        let appURL: String = "\(appName)://spotify:user:spotify:playlist:5FJXhjdILmRA2z5bvz4nzf"
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!)) {
            print(appURL)
            UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
        } else {
            print("Can't use spotify://")
            let appName: String = "music"
            let appURL: String = "\(appName)://"
            if (UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!)) {
                print(appURL)
                UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
            }
        }
    }
    
}

// Extension for using the Google Places API.
extension NavigationViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        print("Place coordinates: \(place.coordinate)")
        self.dismissViewControllerAnimated(true, completion: nil)
        mapView.camera = GMSCameraPosition.cameraWithTarget(place.coordinate, zoom: 12)
        let marker = GMSMarker(position: place.coordinate)
        marker.title = place.name
        marker.map = mapView
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
