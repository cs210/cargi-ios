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
import SpeechKit

class NavigationViewController: UIViewController, SKTransactionDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate, MFMessageComposeViewControllerDelegate, GMSMapViewDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    
    // Types of Maps that can be used.
    private enum MapsType {
        case Apple // Apple Maps
        case Google // Google Maps
    }
    
    private var defaultMap: MapsType = MapsType.Google // hard-coded to Google Maps, but may change depending on user's preference.
    
    var data: NSMutableData = NSMutableData()
    
    var destLabel: UILabel?
    var addrLabel: UILabel?
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var destinationView: UIView!
    
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var gasButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet var dashboardView: UIView!
    @IBOutlet var contactView: UIView!
    @IBOutlet var contactLabel: UILabel!

    @IBOutlet weak var voiceButton: UIButton!
    
    var locationManager = CLLocationManager()
    var gasFinder = GasFinder()
    var didFindMyLocation = false // avoid unnecessary location updates
    let defaultLatitude: CLLocationDegrees = 37.426
    let defaultLongitude: CLLocationDegrees = -122.172
    
    var destLocation: String?
    var destinationName: String?
    var destCoordinates = CLLocationCoordinate2D()
    
    
    var manager: CBCentralManager! // Bluetooth Manager
    var currentEvent: EKEvent? {
        didSet {
            eventLabel.text = currentEvent?.title
        }
    }
    
    var eventDirectory = EventDirectory()
    
    var contactDirectory = ContactDirectory()
    var contact: String? {
        didSet {
            contactLabel.text = contact
            if contact == nil {
                callButton.enabled = false
                textButton.enabled = false
            } else {
                callButton.enabled = true
                textButton.enabled = true
            }
        }
    }
    var contactNumbers: [String]?
    
    var directionTasks = DirectionTasks() // Google Directions
    var syncRouteSuccess: Bool = false
    var destMarker = GMSMarker()
    var routePolyline = GMSPolyline() // lines that will show the route.
    var routePolylineBorder = GMSPolyline()
    var routePath = GMSPath()
    
    var distanceTasks = DistanceMatrixTasks()
    
    lazy var db = AzureDatabase()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        destMarker.icon = UIImage(named: "destination_icon")
        
        view.sendSubviewToBack(dashboardView)
        view.sendSubviewToBack(mapView)
        let layer: CALayer = self.dashboardView.layer
        layer.shadowOffset = CGSizeMake(1, 1)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 1.5
        layer.shadowOpacity = 0.7
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
        
        // Design of Buttons
        callButton.layer.shadowOffset = CGSizeMake(3, 3)
        callButton.layer.shadowColor = UIColor.blackColor().CGColor
        callButton.layer.shadowRadius = 2
        callButton.layer.shadowOpacity = 0.27
        
        textButton.layer.shadowOffset = CGSizeMake(-3, 3)
        textButton.layer.shadowColor = UIColor.blackColor().CGColor
        textButton.layer.shadowRadius = 2
        textButton.layer.shadowOpacity = 0.27
        
//        contactView.layer.shadowOffset = CGSizeMake(0, -1)
//        contactView.layer.shadowColor = UIColor.blackColor().CGColor
//        contactView.layer.shadowRadius = 1.5
//        contactView.layer.shadowOpacity = 0.7

        contactView.layer.shadowOffset = CGSizeMake(0, -1)
        contactView.layer.shadowColor = UIColor.blackColor().CGColor
        contactView.layer.shadowRadius = 1.5
        contactView.layer.shadowOpacity = 0.27
        
        destinationView.layer.shadowOffset = CGSizeMake(0, 3)
        destinationView.layer.shadowColor = UIColor.blackColor().CGColor
        destinationView.layer.shadowRadius = 1.5
        destinationView.layer.shadowOpacity = 0.27
        
        // Observer for changes in myLocation of google's map view
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        mapView.settings.compassButton = true

        let deviceID = UIDevice.currentDevice().identifierForVendor!.UUIDString

        db.initializeUserID(deviceID) { (status, success) in
            if (success) {
                print("initialized user id:", self.db.userID!)
            } else {
                print(status)
            }
        }
        
        
        
        resetData()
        syncData()
        
//        db.insertEvent()
//        let latitudeNum = NSNumber(double: destCoordinates.latitude)
//        let longitudeNum = NSNumber(double: destCoordinates.longitude)
//        db.insertEvent(eventLabel.text, latitude: latitudeNum, longitude: longitudeNum, dateTime: NSDate())
    }
    
    /// When the app starts, update the maps view so that it shows the user's current location in the center.
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            if !syncRouteSuccess {
                mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 15.0)
            }
            didFindMyLocation = true
        }
    }
    
    /// Reset Data
    func resetData() {
        self.contact = nil
        self.eventLabel.text = nil
//        self.destLabel.text = nil
//        self.addrLabel.text = nil
        self.destLocation = nil
        self.destinationName = nil
        mapView.clear()
    }
    
    func createStopWords() -> Array<String> {
        return ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "can't", "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", "weren't", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've", "your", "yours", "yourself", "yourselves"]
    }
    
    /// Sync with Apple Calendar to get the current calendar event, and update the labels given this event's information.
    func syncData() {
        let contacts = contactDirectory.getAllPhoneNumbers()
        guard let events = eventDirectory.getAllCalendarEvents() else { return }
        let stopWords = createStopWords()

        for ev in events {
            guard let _ = ev.location else { continue } // ignore event if it has no location info.
            self.currentEvent = ev
            var possibleContactArr: [String] = []
            var possibleContact = false;
            for contact in contacts.keys {
                possibleContact = false;
                let lowerContact = contact.lowercaseString
                var contactsArr = lowerContact.componentsSeparatedByString(" ")
                let firstName = contactsArr[0]
                let lastName: String? = contactsArr.count > 1 ? contactsArr[1] : nil
                var eventTitle = ev.title.lowercaseString
                var eventTitleArr = eventTitle.componentsSeparatedByString(" ")
                
                if eventTitle.rangeOfString(lowerContact) != nil { //search for full name
                    if contact.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
                        possibleContact = true;
                        let contactNumber = contactDirectory.getPhoneNumber(contact)
                        if contactNumber?.count > 0 { //check that the contact actually has a number
                            possibleContactArr.append(contact)
                            self.contact = contact
                        }

                    }
                }
                if (contactsArr.count <= 3) { //contact name can't have more than 3 parts
                    var notStopWord = true
                    if stopWords.contains(firstName){
                        notStopWord = false
                    }
                    if eventTitleArr.contains(firstName) && notStopWord {
                        if contact.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
                            possibleContact = true;
                        }
                    }
                    if (lastName != nil) {
                        var notStopWordL = true
                        if stopWords.contains(lastName!){
                            notStopWordL = false
                        }
                        if eventTitleArr.contains(lastName!) && notStopWordL {
                            if contact.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
                                possibleContact = true;
                            }
                        }
                    }
                    if (possibleContact) {
                        let contactNumber = contactDirectory.getPhoneNumber(contact)
                        if contactNumber?.count > 0 { //check that the contact actually has a number
                            possibleContactArr.append(contact)
                            if self.contact != nil {
                                self.contact = contact
                            }
                        }
                    }
                }
            }
            print(possibleContactArr)
            
            if contact != nil { break }
        }
        
        if contact == nil {
            for ev in events {
                if !ev.allDay {
                    self.currentEvent = ev
                }
            }
        }
        
        if let _ = contact {
            contactView.hidden = false
        } else {
            contactView.hidden = true
        }
        
        contactNumbers = contactDirectory.getPhoneNumber(contact)

        guard let ev = currentEvent else { return }
        print(ev.eventIdentifier)
        
        destLocation = ev.location
        if let checkIfEmpty = ev.location {
            if checkIfEmpty.isEmpty {
                destLocation = nil
            }
        }
        
        if let coordinate = ev.structuredLocation?.geoLocation?.coordinate {
            destCoordinates = coordinate
        }

        if let loc = ev.location {
            let locArr = loc.characters.split { $0 == "\n" }.map(String.init)
            if locArr.count > 1 {
//                destLabel.text = locArr.first
                searchButton.setTitle(locArr.first, forState: .Normal)
//                addrLabel.text = locArr[1]
            } else {
//                destLabel.text = locArr.first
//                addrLabel.text = nil
                searchButton.setTitle(locArr.first, forState: .Normal)
            }
            destinationName = locArr.first
        }
        print("showroute")
        showRoute(showDestMarker: true)
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
//        guard let ev = currentEvent else { return }
//        let queries = ev.location!.componentsSeparatedByString("\n")
//        print(queries)
        guard let dest = destLocation else {
            showAlertViewController(title: "Error", message: "No destination specified.")
            return
        }
        let query = dest.componentsSeparatedByString("\n").joinWithSeparator(" ")
        print(query)
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
    

    
    func showRouteWithWaypoints(waypoints waypoints: [String]!, showDestMarker: Bool) {
        mapView.clear()
        routePolyline.path = nil
        routePolylineBorder.path = nil
        
        guard let originLocation = locationManager.location?.coordinate else {
            syncRouteSuccess = false
            return
        }
        let origin = "\(originLocation.latitude),\(originLocation.longitude)"

        self.directionTasks.getDirections(origin, dest: destLocation, waypoints: waypoints) { (status, success) in
            print("got directions")
            self.destMarker.map = nil
            self.syncRouteSuccess = success
            if success {
                print("success")
                if showDestMarker {
                    self.configureMap()
                }
                self.drawRoute()
            } else {
                self.showAlertViewController(title: "Error", message: "Can't find a way there.")
                print(status)
            }
        }
    }
    
    /// Update the Google Maps view with the synced route, depending on whether we've successfully received the response from Google Directions API.
    func showRoute(showDestMarker showDestMarker: Bool) {
        showRouteWithWaypoints(waypoints: nil, showDestMarker: showDestMarker)
    }
    
    /// Shows a pin at the destination on the map.
    private func configureMap() {
        destMarker.position = directionTasks.destCoordinate
        destMarker.map = mapView
        print(destMarker.position)
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
        updateCamera(bounds)
    }
    
    private func updateCamera(bounds: GMSCoordinateBounds) {
        // Depending on whether the contact view is hidden or not, we have different bounds.
        var cameraUpdate: GMSCameraUpdate
        if contactView.hidden {
            cameraUpdate = GMSCameraUpdate.fitBounds(bounds, withEdgeInsets: UIEdgeInsets(top: 165.0, left: 20.0, bottom: 110.0, right: 20.0))
        } else {
            cameraUpdate = GMSCameraUpdate.fitBounds(bounds, withEdgeInsets: UIEdgeInsets(top: 165.0, left: 20.0, bottom: 230.0, right: 20.0))
        }
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
    func sendETAMessage(phoneNumbers: [String]?) {
        guard let numbers = phoneNumbers else { return }
        guard let _ = destLocation else { return }
        let locValue: CLLocationCoordinate2D = locationManager.location!.coordinate
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            let firstName = self.contact?.componentsSeparatedByString(" ").first
            print(contact)
            print(firstName)
            distanceTasks.getETA(locValue.latitude, origin2: locValue.longitude, dest1: destCoordinates.latitude, dest2: destCoordinates.longitude) { (status, success) in
                print(status)
                if success {
                    let duration = self.distanceTasks.durationInTrafficText
                    if let dest = self.destinationName {
                        controller.body = "Hi \(firstName!), I will arrive at \(dest) in \(duration)."
                    } else {
                        controller.body = "Hi \(firstName!), I will arrive in \(duration)."
                    }
                    print(controller.body)
                } else {
                    self.showAlertViewController(title: "Error", message: "No ETA found.")
                }
            }
            print(phoneNumbers)
            controller.recipients = [numbers[0]] // Send only to the primary number
            print(controller.recipients)
            controller.messageComposeDelegate = self
            print("presenting view controller")
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    //Temporary Azure REST API Test
    func azureRESTAPITest() {
        let stringURL = "https://cargiios.azure-mobile.net/api/calculator/add?a=1&b=5"
        print(stringURL)
        guard let url = NSURL(string: stringURL) else { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            let data = NSData(contentsOfURL: url)
            
            // Convert JSON response into an NSDictionary.
            var json: [NSObject:AnyObject]?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? [NSObject:AnyObject]
            } catch {
                //completionHandler(status: "", success: false)
            }
            //            print(json!.description)
            
            guard let dict = json else { return }
            let result = dict["result"]
            print(result)
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
    
    func showAlertViewController(title title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(alertAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: IBAction Methods
    
    /// Refresh Button Clicked
    @IBAction func refreshButtonClicked(sender: UIButton) {
        resetData()
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

    //Start session for voice capture/recognition
    @IBAction func voiceButtonClicked(sender: AnyObject) {
        print("listening for voice command");
        voiceButton.setTitle("Listening...", forState: .Normal)
        let url = "nmsps://NMDPTRIAL_team_cargi_co20160418020749@sslsandbox.nmdp.nuancemobility.net:443"
        let token = "6ff1671b87d0259dc04a734edbf2ab4894184242e68c4cf3fac45545c7c10e37b376523a4677d706c14a549c3cffe5d0182713feb35ff2ad2447f2eb090122bc"
        let session = SKSession(URL: NSURL(string: url), appToken: token)
        session.recognizeWithType(SKTransactionSpeechTypeDictation,
                                  detection: .Short,
                                  language: "eng-USA",
                                  delegate: self)
    }
    
    //find the best result and start gas action if it matches
    func transaction(transaction: SKTransaction!, didReceiveRecognition recognition: SKRecognition!) {
        print("Result of Speech Recognition: " + recognition.text)
        if (recognition.text.lowercaseString.rangeOfString("gas") != nil) {
            gasButtonClicked(nil)
        }
        if (recognition.text.lowercaseString.rangeOfString("music") != nil) {
            musicButtonClicked(nil)
        }
        if (recognition.text.lowercaseString.rangeOfString("call") != nil) {
            phoneButtonClicked(nil)
        }
        if (recognition.text.lowercaseString.rangeOfString("text") != nil) {
            messageButtonClicked(nil)
        }
        voiceButton.setTitle("Listen", forState: .Normal)
    }
    
    /// Gas Button clicked
    @IBAction func gasButtonClicked(sender: UIButton?) {
        let numCheapGasStations = 2
        let numNearbyGasStations = 2
        
        let visibleRegion = self.mapView.projection.visibleRegion()
        var bounds = GMSCoordinateBounds(coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        
        guard let originLocation = locationManager.location else {
            return
        }
        
        let geocoder = LocationGeocoder()
        geocoder.getPostalCode(originLocation) { (status, success) in
            print("Postal Code: \(status)")
            if success {
                guard let postalCode = geocoder.postalCode else { return }
                print(postalCode)
                
                guard let originLocationCoordinates = self.locationManager.location?.coordinate else {
                    return
                }
                let origin = "\(originLocationCoordinates.latitude),\(originLocationCoordinates.longitude)"
                
                self.gasFinder.getNearbyGasStations(origin, count: numNearbyGasStations) { (status: String, success: Bool) in
                    print("Gas Finder: \(status)")
                    if success {
                        let cheapGasFinder = CheapGasFinder()
                        cheapGasFinder.getCheapGasByPostalCode(postalCode) { (status, success) in
                            print("Cheap Gas Finder: \(status)")
                            if success {
                                for station in self.gasFinder.stations {
                                    print(station)
                                    let number = station.address?.componentsSeparatedByString(" ").first
                                    var priceFound = false
                                    for cheapStation in cheapGasFinder.stations {
                                        if number! == cheapStation.number! {
                                            self.addMapMarker(station.coordinates!, title: station.name, snippet: cheapStation.price)
                                            bounds = bounds.includingCoordinate(station.coordinates!)
                                            self.updateCamera(bounds)
                                            priceFound = true
                                            break
                                        }
                                        
//                                        let locationGeocoder = LocationGeocoder()
//                                        locationGeocoder.getCoordinates(station.address!) { (status, success) in
//                                            if success {
//                                                let marker = GMSMarker(position: locationGeocoder.coordinate!)
//                                                marker.appearAnimation = kGMSMarkerAnimationPop
//                                                marker.title = station.name
//                                                marker.icon = UIImage(named: "gasmarker")
//                                                marker.snippet = station.price
//                                                marker.map = self.mapView
//                                            }
//                                        }
                                    }
                                    if !priceFound {
                                        self.addMapMarker(station.coordinates!, title: station.name, snippet: station.address)
                                        bounds = bounds.includingCoordinate(station.coordinates!)
                                        self.updateCamera(bounds)
                                    }
                                }
                                
                                for i in 0..<numCheapGasStations {
                                    if let cheapStation = cheapGasFinder.stations[safe: i] {
                                        let locationGeocoder = LocationGeocoder()
                                        locationGeocoder.getCoordinates(cheapStation.address!) { (status, success) in
                                            if success {
                                                self.addMapMarker(locationGeocoder.coordinate!, title: cheapStation.name, snippet: cheapStation.price)
                                                bounds = bounds.includingCoordinate(locationGeocoder.coordinate!)
                                                self.updateCamera(bounds)
                                            }
                                        }
                                    }
                                }
                                
                                
                            }
                        }
                    } else {
                        print("Error: \(status)")
                    }
                }
                
                
                
                
                
                
            } else {
                print("FAIL")
                return
            }
        }
        
//        guard let originLocationCoordinates = locationManager.location?.coordinate else {
//            return
//        }
//
//        let origin = "\(originLocationCoordinates.latitude),\(originLocationCoordinates.longitude)"
//        print("origin: \(origin)")
//        gasFinder.getNearbyGasStations(origin, count: 0) { (status: String, success: Bool) in
//            if success {
//                for station in self.gasFinder.stations {
//                    let marker = GMSMarker(position: station.coordinates!)
//                    marker.appearAnimation = kGMSMarkerAnimationPop
//                    marker.title = station.name
//                    marker.icon = UIImage(named: "gasmarker")
//                    marker.snippet = station.address
//                    marker.map = self.mapView
//                }
////                if self.destLocation != nil {
//////                    self.showRouteWithWaypoints(waypoints: ["place_id:\(self.gasFinder.placeID)"], showDestMarker: true)
////                } else {
////                    self.destLocation = self.gasFinder.address
//////                    self.showRoute(showDestMarker: false)
////                }
//            } else {
//                print("Error: \(status)")
//            }
//        }
    }
    
    private func addMapMarker(position: CLLocationCoordinate2D, title: String?, snippet: String?) {
        let marker = GMSMarker(position: position)
        marker.appearAnimation = kGMSMarkerAnimationPop
        marker.title = title
        marker.icon = UIImage(named: "gasmarker")
        marker.snippet = snippet
        marker.map = self.mapView
    }
    
    
    /// Send Message Button clicked.
    @IBAction func messageButtonClicked(sender: UIButton?) {
        print("message button activated")
        self.sendETAMessage(self.contactNumbers)
    }
    
    /// Starts a phone call using the phone number associated with current event.
    @IBAction func phoneButtonClicked(sender: UIButton?) {
        print("phone button activated")
        self.callPhone(contactNumbers)
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
    @IBAction func musicButtonClicked(sender: UIButton?) {
        print("music button activated")
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
    
    
    
    /// Search Button clicked
    @IBAction func searchButtonClicked(sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        let visibleRegion = self.mapView.projection.visibleRegion()
        autocompleteController.autocompleteBounds = GMSCoordinateBounds(
            coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        self.presentViewController(autocompleteController, animated: true, completion: nil)
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
        self.destLocation = place.formattedAddress
        self.destinationName = place.name
        self.destCoordinates = place.coordinate
//        self.destLabel.text = place.name
        self.searchButton.setTitle(place.name, forState: .Normal)
//        self.addrLabel.text = place.formattedAddress
        self.eventLabel.text = nil
        self.showRoute(showDestMarker: true)
//        mapView.camera = GMSCameraPosition.cameraWithTarget(place.coordinate, zoom: 12)
//        let marker = GMSMarker(position: place.coordinate)
//        marker.title = place.name
//        marker.map = mapView
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

extension CollectionType {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
