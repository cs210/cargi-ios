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
import AVFoundation

class NavigationViewController: UIViewController, SKTransactionDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate, MFMessageComposeViewControllerDelegate, GMSMapViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, OEEventsObserverDelegate, AVSpeechSynthesizerDelegate, SKAudioPlayerDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    
    // Types of Maps that can be used.
    private enum MapsType {
        case Apple // Apple Maps
        case Google // Google Maps
    }
    
    @IBOutlet weak var spinnerBackground: UIImageView!
    private var defaultMap: MapsType = MapsType.Google // hard-coded to Google Maps, but may change depending on user's preference.
    
    
    var destLabel: UILabel?
    var addrLabel: UILabel?
    @IBOutlet weak var speechLabel: UILabel!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var destinationView: UIView!
    
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var gasButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var currentEventButton: UIButton!
    @IBOutlet weak var changeContactButton: UIButton!
    
    @IBOutlet var dashboardView: UIView!
    @IBOutlet var contactView: UIView!
    @IBOutlet var contactLabel: UILabel!
    
    @IBOutlet weak var picker: UIPickerView!
    var pickerData: [String] = [String]()
    
    @IBOutlet weak var voiceButton: UIButton!
    
    var lmPath:String!
    var dicPath:String!
    var words:[String:Int] = [
        "HEY": -1,
        "CARGHI": -2,
        "HELLO": -3,
        "KARTIK": -4,
        "TARA": -5,
        "MAYA": -6,
        "EDWIN": -7,
        "EMILY": -8,
        "ISHITA": -9,
        "MUSIC": -10,
        "GAS": -11,
        "CALL": -12,
        "TEXT": -13,
        "CONTACT": -14,
        "EVENT": -15
    ]
    var openEarsEventsObserver: OEEventsObserver!
    var voice: String!
    var skSession1:SKSession?
    var skTransaction1:SKTransaction?
    
    struct Location {
        var name: String?
        var address: String?
        var coordinates: CLLocationCoordinate2D?
    }
    
    // MARK: Variables
    
    var locationManager = CLLocationManager()
    var gasFinder = GasFinder()
    var didFindMyLocation = false // avoid unnecessary location updates
    let defaultLatitude: CLLocationDegrees = 37.426
    let defaultLongitude: CLLocationDegrees = -122.172
    
    var gasMarker: GMSMarker?
    var dest = Location()
    var waypoint: Location?
    
    var manager: CBCentralManager! // Bluetooth Manager
    var currentEvent: EKEvent? {
        didSet {
            currentEventButton.setTitle(currentEvent?.title, forState: .Normal)
        }
    }
    
    var eventDirectory = EventDirectory()
    
    var contactDirectory = ContactDirectory()
    var contact: String? {
        didSet {
            contactLabel.text = contact
            if contact == nil {
                contactView.hidden = true
            } else {
                contactView.hidden = false
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
    
    lazy var db = AzureDatabase.sharedInstance
    
    var dbEvent: DBEvent?
    
    struct DBEvent {
        var name: String?
        var latitude: NSNumber
        var longitude: NSNumber
        var dateTime: NSDate
        
        init(name: String?, latitude: NSNumber, longitude: NSNumber, dateTime: NSDate) {
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.dateTime = dateTime
        }
    }
    
    // MARK: Constants
    
    let stopWords: [String] = ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "can't", "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", "weren't", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've", "your", "yours", "yourself", "yourselves"]
    let synth = AVSpeechSynthesizer()
    
    
    
    // MARK: Methods
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        contactView.hidden = true
        self.mapView.delegate = self
        
        self.picker.delegate = self
        self.picker.dataSource = self
        self.picker.hidden = true
        
        self.view.bringSubviewToFront(self.activityIndicatorView)
        self.view.bringSubviewToFront(self.picker)
        self.spinnerBackground.hidden = true
        
        destMarker.icon = UIImage(named: "destination_icon")
        
        view.sendSubviewToBack(dashboardView)
        view.sendSubviewToBack(mapView)
        let layer: CALayer = self.dashboardView.layer
        layer.shadowOffset = CGSizeMake(1, 1)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 1.5
        layer.shadowOpacity = 0.7
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
        
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
        
        // Configure speech synthesiser
        synth.delegate = self
        
        // Configure OpenEars
        loadOpenEars()
        startListening()
        
        mapView.settings.compassButton = true
        
        self.resetView()
        self.syncCalendar()
        
        voice = "Ava" //replace VOICE with one of Ava, Allison, Samantha, Susan and Zoe
        let url = "nmsps://NMDPTRIAL_team_cargi_co20160418020749@sslsandbox.nmdp.nuancemobility.net:443"
        let token = "6ff1671b87d0259dc04a734edbf2ab4894184242e68c4cf3fac45545c7c10e37b376523a4677d706c14a549c3cffe5d0182713feb35ff2ad2447f2eb090122bc"
        skSession1 = SKSession(URL: NSURL(string: url), appToken: token)
        if (skSession1 == nil) {
            print("Failed to initialize SpeechKit session.")
        }
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
    func resetView() {
        gasMarker = nil
        currentEventButton.setTitle(nil, forState: .Normal)
        searchButton.setTitle(nil, forState: .Normal)
        contact = nil
        dest = Location()
        waypoint = nil
        stopSpinner()
        mapView.clear()
    }
    
    private func suggestContact(event: EKEvent?) -> String? {
        guard let ev = event else { return nil }
        let contacts = contactDirectory.getAllPhoneNumbers()
        let separators = NSCharacterSet(charactersInString: "@\\|,;/<> ")
        
        var possibleContactArr: [String] = []
        let eventTitle = ev.title.lowercaseString
        //        let eventTitleArr = eventTitle.componentsSeparatedByString(" ")
        let eventTitleArr = eventTitle.componentsSeparatedByCharactersInSet(separators);
        print("event title arr: ", eventTitleArr);
        
        
        for contact in contacts.keys {
            let lowerContact = contact.lowercaseString
            var contactsArr = lowerContact.componentsSeparatedByString(" ")
            let firstName = contactsArr[0]
            let lastName: String? = contactsArr.count > 1 ? contactsArr[1] : nil
            
            
            if eventTitle.rangeOfString(lowerContact) != nil { // search for full name - if it exists, don't add any more contacts
                if contact.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
                    let contactNumber = contactDirectory.getPhoneNumber(contact)
                    if contactNumber?.count > 0 { //check that the contact actually has a number -- and add it directly
                        possibleContactArr.append(contact)
                        self.contact = contact
                        break
                    }
                }
            }
            if (contactsArr.count <= 3) { //contact name can't have more than 3 parts
                var notStopWord = true
                if stopWords.contains(firstName){
                    notStopWord = false
                }
                var notStopWordL = true
                if (lastName != nil) {
                    if stopWords.contains(lastName!){
                        notStopWordL = false
                    }
                }
                else { notStopWordL = false }
                
                if (eventTitleArr.contains(firstName) && notStopWord) || (eventTitleArr.contains(lastName!) && notStopWordL) {
                    if contact.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
                        let contactNumber = contactDirectory.getPhoneNumber(contact)
                        if contactNumber?.count > 0 { //check that the contact actually has a number
                            possibleContactArr.append(contact)
                            if self.contact == nil { //only add to "best guess" contact if you don't have a "best guess" already
                                //should insert some check here with the database for frequently contacted people - so you have a better guess
                                //maybe first name is better than matching last name
                                self.contact = contact
                            }
                        }
                    }
                }
            }
        }
        print(possibleContactArr)
        self.pickerData = possibleContactArr
        return contact
    }
    
    private func updateContact(contact: String?) {
        self.contact = contact
        self.contactNumbers = contactDirectory.getPhoneNumber(contact)
    }
    
    func syncEvent(newEvent: EKEvent?) {
        self.contact = nil
        dest = Location()
        currentEvent = newEvent
        print(newEvent)
        
        currentEventButton.setTitle(currentEvent?.title, forState: .Normal)
        
        if let eventLocation = currentEvent?.location {
            if eventLocation.isEmpty {
                dest.address = nil
            }
        }
        
        dest.coordinates = currentEvent?.structuredLocation?.geoLocation?.coordinate
        
        if let loc = currentEvent?.location {
            let locationTokens = loc.componentsSeparatedByString("\n")
            //            let locationTokens = loc.characters.split { $0 == "\n" }.map(String.init)
            if locationTokens.count > 1 {
                searchButton.setTitle(locationTokens.first, forState: .Normal)
            } else {
                searchButton.setTitle(locationTokens.first, forState: .Normal)
            }
            dest.name = locationTokens.first
            dest.address = locationTokens.joinWithSeparator(" ")
            
        }
        print("showroute")
        showRoute(showDestMarker: true)
        
        dbEvent = createDBEventForCurrentEvent()
        let suggestedContact = suggestContact(currentEvent)
        updateContact(suggestedContact)
        insertDBEvent()
    }
    
    func syncCalendar() {
        syncCalendar(refreshCalendar: true)
    }
    
    /// Sync with Apple Calendar to get the current calendar event, and update the labels given this event's information.
    func syncCalendar(refreshCalendar refreshCalendar: Bool) {
        if refreshCalendar {
            self.currentEvent = nil
            guard let events = eventDirectory.getAllCalendarEvents() else { return }
            for ev in events {
                if !ev.allDay {
                    if ev.location != nil {
                        self.currentEvent = ev
                        break
                    }
                    if currentEvent == nil {
                        currentEvent = ev
                    }
                }
            }
        }
        syncEvent(currentEvent)
    }
    
    
    private func createDBEventForCurrentEvent() -> DBEvent {
        var eventDateTime: NSDate
        if let ev = currentEvent {
            eventDateTime = ev.startDate
        } else {
            eventDateTime = NSDate()
        }
        
        var latitudeNum: NSNumber = 0
        var longitudeNum: NSNumber = 0
        if let coordinate = dest.coordinates {
            latitudeNum = NSNumber(double: coordinate.latitude)
            longitudeNum = NSNumber(double: coordinate.longitude)
        }
        
        return DBEvent(name: currentEvent?.title, latitude: latitudeNum, longitude: longitudeNum, dateTime: eventDateTime)
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
     Open Google Maps showing the route to the given coordinates with a waypoint.
     */
    func openGoogleMapsLocationWaypoints(address: String, waypoint: CLLocationCoordinate2D) {
        print("comgooglemaps://?saddr=&daddr=\(address)&waypoints=\(waypoint.latitude),\(waypoint.longitude)&directionsmode=driving")
        UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?saddr=&daddr=\(address)&waypoints=\(waypoint.latitude),\(waypoint.longitude)&directionsmode=driving")!)
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
     Open Apple Maps showing the route to the given coordinates.
     */
    func openAppleMapsLocationNoEvent(coordinate: CLLocationCoordinate2D) {
        let path = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)"
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
    //    func openMaps(waypoint waypoint: CLLocationCoordinate2D?) {
    func openMaps(destination destination: Location?) {
        
        //        guard let ev = currentEvent else { return }
        //        let queries = ev.location!.componentsSeparatedByString("\n")
        //        print(queries)
        
        //        if waypointCoordinates != nil {
        //            openGoogleMapsLocationWaypoints(waypointCoordinates!)
        //            return
        //        }
        guard let dest = destination else {
            showAlertViewController(title: "Error", message: "No destination specified.")
            return
        }
        
        if (dest.address == nil && dest.coordinates == nil) {
            showAlertViewController(title: "Error", message: "No destination specified.")
            return
        }
        
        
        if (dest.coordinates != nil) {
            if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
                self.openGoogleMapsLocation(dest.coordinates!)
            } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
                self.openAppleMapsLocationNoEvent(dest.coordinates!)
            }
            return
        }
        
        if (dest.address != nil) {
            let destAddress = dest.address
            let query = destAddress!.componentsSeparatedByString("\n").joinWithSeparator(" ")
            print(query)
            let address = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
            
            if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
                self.openGoogleMapsLocationAddress(address)
                self.openGoogleMapsLocationWaypoints(address, waypoint: CLLocationCoordinate2D(latitude: defaultLatitude, longitude: defaultLongitude))
            } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
                self.openAppleMapsLocationAddress(address)
            }
            return
        }
        return
        
        
        //        guard let destAddress = dest.address else {
        ////            showAlertViewController(title: "Error", message: "No destination specified.")
        //            if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
        //                self.openGoogleMapsLocation(dest.coordinates!)
        //            } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
        //                self.openAppleMapsLocationNoEvent(dest.coordinates!)
        //            }
        //            return
        //        }
        //
        //        let query = destAddress.componentsSeparatedByString("\n").joinWithSeparator(" ")
        //        print(query)
        //        let address = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        //
        //        if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
        //            self.openGoogleMapsLocationAddress(address)
        //            self.openGoogleMapsLocationWaypoints(address, waypoint: CLLocationCoordinate2D(latitude: defaultLatitude, longitude: defaultLongitude))
        //        } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
        //            self.openAppleMapsLocationAddress(address)
        //        }
        //
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
        //        waypointCoordinates = nil
        routePolyline.path = nil
        routePolylineBorder.path = nil
        
        guard let originLocation = locationManager.location?.coordinate else {
            syncRouteSuccess = false
            return
        }
        let origin = "\(originLocation.latitude),\(originLocation.longitude)"
        
        var destination: String?
        if dest.address != nil {
            destination = dest.address
        } else {
            destination = waypoints.first
        }
        
        self.directionTasks.getDirections(origin, dest: destination, waypoints: waypoints) { (status, success) in
            print("got directions")
            self.destMarker.map = nil
            self.syncRouteSuccess = success
            if success {
                print("success")
                if !waypoints.isEmpty {
                    if let gm = self.gasMarker {
                        gm.map = self.mapView
                    }
                }
                
                if showDestMarker {
                    self.configureMap()
                }
                
                self.drawRoute()
            } else {
                print(status)
                if let backupDest = waypoints.first {
                    self.directionTasks.getDirections(origin, dest: backupDest, waypoints: waypoints) { (status, success) in
                        if success {
                            if let gm = self.gasMarker {
                                gm.map = self.mapView
                            }
                            self.drawRoute()
                        } else {
                            self.showAlertViewController(title: "Error", message: "Can't find a way there.")
                        }
                    }
                } else {
                    if status != "Origin is nil" && status != "Destination is nil" {
                        self.showAlertViewController(title: "Error", message: "Can't find a way there.")
                    }
                }
            }
        }
    }
    
    /// Update the Google Maps view with the synced route, depending on whether we've successfully received the response from Google Directions API.
    func showRoute(showDestMarker showDestMarker: Bool) {
        showRouteWithWaypoints(waypoints: [], showDestMarker: showDestMarker)
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
        updateCamera(bounds, shouldAddEdgeInsets: true)
    }
    
    private func updateCamera(bounds: GMSCoordinateBounds, shouldAddEdgeInsets: Bool) {
        // Depending on whether the contact view is hidden or not, we have different bounds.
        var cameraUpdate: GMSCameraUpdate
        if shouldAddEdgeInsets {
            if contactView.hidden {
                cameraUpdate = GMSCameraUpdate.fitBounds(bounds, withEdgeInsets: UIEdgeInsets(top: 165.0, left: 20.0, bottom: 110.0, right: 20.0))
            } else {
                cameraUpdate = GMSCameraUpdate.fitBounds(bounds, withEdgeInsets: UIEdgeInsets(top: 165.0, left: 20.0, bottom: 230.0, right: 20.0))
            }
        } else {
            cameraUpdate = GMSCameraUpdate.fitBounds(bounds)
        }
        
        mapView.moveCamera(cameraUpdate)
    }
    
    
    /// Starts a phone call with the first phone number in the given list of phone numbers.
    func callPhone(phoneNumbers: [String]?) {
        say("Calling")
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
    func sendETAMessage(phoneNumbers: [String]?, destination: Location?, isGasStation: Bool) {
        say("Sending the text")
        
        guard let numbers = phoneNumbers else { return }
        
        let locValue: CLLocationCoordinate2D = locationManager.location!.coordinate
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            var contactName = String()
            if let firstName = self.contact?.componentsSeparatedByString(" ").first {
                contactName = firstName
            }
            
            print(contact)
            print(contactName)
            
            guard let dest = destination else {
                controller.body = ""
                self.presentViewController(controller, animated: true, completion: nil)
                return
            }
            print(phoneNumbers)
            controller.recipients = [numbers.first!] // Send only to the primary number
            print(controller.recipients)
            controller.messageComposeDelegate = self
            
            if dest.address == nil && dest.coordinates == nil && dest.name == nil {
                controller.body = ""
                self.presentViewController(controller, animated: true, completion: nil)
            } else if isGasStation {
                controller.body = "I'm getting gas right now. I'll be there soon."
                self.presentViewController(controller, animated: true, completion: nil)
            } else {
                var destString = String()
                if let coords = dest.coordinates {
                    destString = "\(coords.latitude),\(coords.longitude)"
                } else if let address = dest.address {
                    destString = address
                } else if let destName = dest.name {
                    destString = destName
                } else {
                    controller.body = ""
                    return
                }
                
                distanceTasks.getETA(locValue.latitude, origin2: locValue.longitude, dest: destString) { (status, success) in
                    print(status)
                    if success {
                        let duration = self.distanceTasks.durationInTrafficText
                        if let destination = dest.name {
                            controller.body = "Hi \(contactName), I will arrive at \(destination) in \(duration)."
                        } else {
                            controller.body = "Hi \(contactName), I will arrive in \(duration)."
                        }
                        print("BODY: \(controller.body)")
                        print("presenting view controller")
                        self.presentViewController(controller, animated: true, completion: nil)
                    } else {
                        self.showAlertViewController(title: "Error", message: "No ETA found.")
                    }
                }
            }
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
    
    
    // AVSpeechSynthesizer delegate
    
    /*
     func say(str:String!) {
     stopListening()
     let myUtterance = AVSpeechUtterance(string: str)
     myUtterance.rate = 0.55
     synth.speakUtterance(myUtterance)
     }
     */
    
    func say(str:String!) {
        skTransaction1 = skSession1!.speakString(str, withVoice: voice, delegate: self)
    }
    
    func transaction(transaction: SKTransaction!, didReceiveAudio audio: SKAudio!) {
        print("didReceiveAudio")
    }
    
    func transaction(transaction: SKTransaction!, didFinishWithSuggestion suggestion: String) {
        print("didFinishWithSuggestion")
    }
    
    func transaction(transaction: SKTransaction!, didFailWithError error: NSError!, suggestion: String) {
        print(String(format: "didFailWithError: %@. %@", arguments: [error.description, suggestion]))
    }
    
    // MARK - SKAudioPlayerDelegate
    
    func audioPlayer(player: SKAudioPlayer!, willBeginPlaying audio: SKAudio!) {
        print("willBeginPlaying")
        // The TTS Audio will begin playing.
    }
    
    func audioPlayer(player: SKAudioPlayer!, didFinishPlaying audio: SKAudio!) {
        print("didFinishPlaying")
    }
    
    func speechSynthesizer(synthesizer:AVSpeechSynthesizer!, didFinishSpeechUtterance utterance:AVSpeechUtterance!) {
        print("finished speaking")
        startListening()
    }
    
    //OpenEars methods
    
    func loadOpenEars() {
        self.openEarsEventsObserver = OEEventsObserver()
        self.openEarsEventsObserver.delegate = self
        
        let lmGenerator: OELanguageModelGenerator = OELanguageModelGenerator()
        let name = "LanguageModelFileStarSaver"
        let list = Array(words.keys)
        lmGenerator.generateLanguageModelFromArray(list, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"))
        
        
        
        lmPath = lmGenerator.pathToSuccessfullyGeneratedLanguageModelWithRequestedName(name)
        dicPath = lmGenerator.pathToSuccessfullyGeneratedDictionaryWithRequestedName(name)
        print("OpenEars loaded")
    }
    
    func pocketsphinxDidReceiveHypothesis(hypothesis: String?, recognitionScore: String?, utteranceID: String?) {
        //        speechLabel.text = "\(hypothesis!) (\(recognitionScore!), \(utteranceID!))"
        print("hypothesis: ", hypothesis)
        print("recogscore: ", recognitionScore)
        print("utteranceID:", utteranceID)
        
        if hypothesis!.rangeOfString("HEY CARGHI") != nil {
            print("Hey carghi detected")
            say("How can carghi help?")
            let triggerTime = (Int64(NSEC_PER_SEC) * 1)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, triggerTime), dispatch_get_main_queue(), { () -> Void in
                self.voiceButtonClicked([])
            })
            //            voiceButtonClicked([])
            return
        } else {
            print("I'm having trouble understanding you")
            //            say("I'm having trouble understanding you")
            return
        }
    }
    
    func pocketsphinxDidStartListening() {
        print("Pocketsphinx is now listening.")
    }
    
    func pocketsphinxDidDetectSpeech() {
        //		print("Pocketsphinx has detected speech.")
    }
    
    func pocketsphinxDidDetectFinishedSpeech() {
        //		print("Pocketsphinx has detected a period of silence, concluding an utterance.")
    }
    
    func pocketsphinxDidStopListening() {
        print("Pocketsphinx has stopped listening.")
    }
    
    func pocketsphinxDidSuspendRecognition() {
        print("Pocketsphinx has suspended recognition.")
    }
    
    func pocketsphinxDidResumeRecognition() {
        print("Pocketsphinx has resumed recognition.")
    }
    
    func pocketsphinxDidChangeLanguageModelToFile(newLanguageModelPathAsString: String, newDictionaryPathAsString: String) {
        print("Pocketsphinx is now using the following language model: \(newLanguageModelPathAsString) and the following dictionary: \(newDictionaryPathAsString)")
    }
    
    func pocketSphinxContinuousSetupDidFailWithReason(reasonForFailure: String) {
        print("Listening setup wasn't successful and returned the failure reason: \(reasonForFailure)")
    }
    
    func pocketSphinxContinuousTeardownDidFailWithReason(reasonForFailure: String) {
        print("Listening teardown wasn't successful and returned the failure reason: \(reasonForFailure)")
    }
    
    func testRecognitionCompleted() {
        print("A test file that was submitted for recognition is now complete.")
    }
    
    func startListening() {
        do {
            try OEPocketsphinxController.sharedInstance().setActive(true)
        } catch {
            //completionHandler(status: "", success: false)
        }
        OEPocketsphinxController.sharedInstance().startListeningWithLanguageModelAtPath(lmPath, dictionaryAtPath: dicPath, acousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"), languageModelIsJSGF: false)
        //OEPocketsphinxController.sharedInstance().secondsOfSilenceToDetect = 0.4
        OEPocketsphinxController.sharedInstance().vadThreshold = 3.5
    }
    
    func stopListening() {
        OEPocketsphinxController.sharedInstance().stopListening()
    }
    
    //OpenEars methods end
    
    func insertDBEvent() {
        db.insertEvent( currentEvent?.title,
                        latitude: dest.coordinates?.latitude ?? CLLocationDegrees(),
                        longitude: dest.coordinates?.longitude ?? CLLocationDegrees(),
                        dateTime: currentEvent?.startDate ?? NSDate(),
                        contactName: contact)
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
    
    // MARK: GMSMapViewDelegate Methods
    
    func mapView(mapView: GMSMapView, didTapInfoWindowOfMarker marker: GMSMarker) {
        waypoint = Location()
        gasMarker = marker
        let showDestMarker = (dest.address != nil) || (dest.name != nil)
        
        print(gasMarker!.position)
        waypoint?.name = gasMarker!.title
        self.searchButton.setTitle(waypoint?.name, forState: .Normal)
        waypoint?.coordinates = gasMarker!.position
        
        if let userData = marker.userData as? [String:String] {
            waypoint?.address = userData["address"]
            
            if let placeID = userData["place_id"] {
                self.showRouteWithWaypoints(waypoints: ["place_id:\(placeID)"], showDestMarker: showDestMarker)
                return
            }
        }
        
        print(marker.position)
        let lat = String(marker.position.latitude)
        let long = String(marker.position.longitude)
        let coord = lat + "," + long
        
        self.showRouteWithWaypoints(waypoints: [coord], showDestMarker: showDestMarker)
    }
    
    
    func startSpinner() {
        self.spinnerBackground.hidden = false
        activityIndicatorView.startAnimating()
    }
    
    func stopSpinner() {
        self.spinnerBackground.hidden = true
        self.activityIndicatorView.stopAnimating()
    }
    
    // MARK: UIPickerVoew Delegate Methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var label: UILabel
        if view == nil {
            label = UILabel()
            label.textColor = UIColor.blackColor()
            label.textAlignment = .Center
        } else {
            label = view as! UILabel
        }
        label.font = UIFont(name: "Lato", size: 20.0)
        label.text = pickerData[row]
        return label
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedContact = pickerData[row]
        print(selectedContact)
        picker.hidden = true
        contactLabel.hidden = false
        changeContactButton.hidden = false
        
        updateContact(selectedContact)
        insertDBEvent()
    }
    
    
    // MARK: IBAction Methods
    
    /// Refresh Button Clicked
    @IBAction func refreshButtonClicked(sender: UIButton) {
        db.insertAction("refresh")
        resetView()
        syncCalendar(refreshCalendar: false)
    }
    
    /// Navigate Button clicked.
    @IBAction func navigateButtonClicked(sender: UIButton) {
        db.insertAction("navigate")
        if let _ = currentEvent {
            if let _ = waypoint {
                openMaps(destination: waypoint)
            } else {
                openMaps(destination: dest)
            }
        } else {
            if dest.name == nil && dest.address == nil {
                syncCalendar()
            }
            
            if let _ = waypoint {
                openMaps(destination: waypoint)
            } else {
                openMaps(destination: dest)
            }
        }
    }
    
    //Start session for voice capture/recognition
    //    @IBAction func voiceButtonClicked(sender: AnyObject) {
    func voiceButtonClicked(sender: AnyObject) {
        //        stopListening()
        print("listening for voice command");
        
        //        voiceButton.setTitle("Listening...", forState: .Normal)
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
            say("gas clicked")
        }
        if (recognition.text.lowercaseString.rangeOfString("music") != nil) {
            musicButtonClicked(nil)
            say("music clicked")
        }
        if (recognition.text.lowercaseString.rangeOfString("call") != nil) {
            phoneButtonClicked(nil)
            say("phone clicked")
        }
        if (recognition.text.lowercaseString.rangeOfString("text") != nil) {
            messageButtonClicked(nil)
            say("text clicked")
        }
        //        voiceButton.setTitle("Listen", forState: .Normal)
        //        startListening()
    }
    
    /// Gas Button clicked
    @IBAction func gasButtonClicked(sender: UIButton?) {
        db.insertAction("gas")
        let numCheapGasStations = 5
        let numNearbyGasStations = 3
        
        let visibleRegion = self.mapView.projection.visibleRegion()
        var bounds = GMSCoordinateBounds(coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        
        guard let originLocation = locationManager.location else {
            return
        }
        
        startSpinner()
        
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
                                    let userData: [String:String] = ["place_id" : station.placeID!,
                                                                     "address"  : station.address!]
                                    
                                    for cheapStation in cheapGasFinder.stations {
                                        if number! == cheapStation.number! {
                                            // Getting location info from Google, so should include place_id.
                                            dispatch_async(dispatch_get_main_queue()) {
                                                self.addMapMarker(station.coordinates!, title: station.name, snippet: cheapStation.price, userData: userData, cheap: false)
                                            }
                                            bounds = bounds.includingCoordinate(station.coordinates!)
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
                                        dispatch_async(dispatch_get_main_queue()) {
                                            self.addMapMarker(station.coordinates!, title: station.name, snippet: station.address, userData: userData, cheap: false)
                                        }
                                        bounds = bounds.includingCoordinate(station.coordinates!)
                                    }
                                }
                                
                                for i in 0..<numCheapGasStations {
                                    if let cheapStation = cheapGasFinder.stations[safe: i] {
                                        let userData: [String:String] = ["address"  : cheapStation.address!]
                                        let locationGeocoder = LocationGeocoder()
                                        locationGeocoder.getCoordinates(cheapStation.address!) { (status, success) in
                                            if success {
                                                dispatch_async(dispatch_get_main_queue()) {
                                                    self.addMapMarker(locationGeocoder.coordinate!, title: cheapStation.name, snippet: cheapStation.price, userData: userData, cheap: true)
                                                }
                                                bounds = bounds.includingCoordinate(locationGeocoder.coordinate!)
                                            }
                                            // if the last cheap gas was found, stop animating activity indicator.
                                            if i == numCheapGasStations - 1 {
                                                dispatch_async(dispatch_get_main_queue()) {
                                                    self.stopSpinner()
                                                    self.updateCamera(bounds, shouldAddEdgeInsets: false)
                                                }
                                                
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
    
    private func addMapMarker(position: CLLocationCoordinate2D, title: String?, snippet: String?, userData: AnyObject?, cheap: Bool) {
        let marker = GMSMarker(position: position)
        marker.appearAnimation = kGMSMarkerAnimationPop
        marker.title = title
        if cheap {
            // green
            marker.icon = UIImage(named: "gascheap")
        } else {
            // blue
            marker.icon = UIImage(named: "gasnearby")
            //            marker.icon = GMSMarker.markerImageWithColor(UIColor.init(red: 109/256, green: 180/256, blue: 245/256, alpha: 1.0))
            
        }
        // marker.icon = UIImage(named: "gasmarker")
        marker.snippet = snippet
        marker.userData = userData
        marker.map = self.mapView
    }
    
    
    /// Send Message Button clicked.
    @IBAction func messageButtonClicked(sender: UIButton?) {
        db.insertAction("message")
        print("message button activated")
        db.insertCommunication("message")
        if let _ = waypoint {
            self.sendETAMessage(contactNumbers, destination: waypoint, isGasStation: true)
        } else {
            self.sendETAMessage(contactNumbers, destination: dest, isGasStation: false)
        }
    }
    
    /// Starts a phone call using the phone number associated with current event.
    @IBAction func phoneButtonClicked(sender: UIButton?) {
        print("phone button activated")
        db.insertAction("phone")
        db.insertCommunication("phone")
        self.callPhone(contactNumbers)
    }
    
    /// Opens the Apple Calendar app, using deep-linking.
    @IBAction func eventButtonClicked(sender: UIButton) {
        db.insertAction("calendar")
        let appName: String = "calshow"
        let appURL: String = "\(appName):"
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!) {
            print(appURL)
            UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
        }
    }
    
    @IBAction func changeButtonClicked(sender: UIButton) {
        picker.reloadAllComponents()
        db.insertAction("pick_contact")
        if let contactName = contact {
            if let row = pickerData.indexOf(contactName) {
                picker.selectRow(row, inComponent: 0, animated: false)
            }
        }
        picker.hidden = false
        contactLabel.hidden = true
        changeContactButton.hidden = true
    }
    
    
    /// Opens the music app of preference, using deep-linking.
    // Music app options: Spotify (default) and Apple Music
    @IBAction func musicButtonClicked(sender: UIButton?) {
        db.insertAction("music")
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
        db.insertAction("search")
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        let visibleRegion = self.mapView.projection.visibleRegion()
        autocompleteController.autocompleteBounds = GMSCoordinateBounds(
            coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    /// Settings Button clicked
    @IBAction func settingsButtonClicked(sender: UIButton) {
        let alert = UIAlertController(title: "Logout", message: "Would you like to log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) { (action) in
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setBool(false, forKey: "loggedIn") // set as logged in
            prefs.setValue("", forKey: "userEmail")
            prefs.setValue("", forKey: "userID")
            
            self.mapView.removeObserver(self, forKeyPath: "myLocation")
            
            //            if self.canPerformUnwindSegueAction(Selector("logoutToLogin"), fromViewController: self, withSender: sender) {
            //                self.performSegueWithIdentifier("logoutToLogin", sender: nil)
            //            } else {
            self.performSegueWithIdentifier("logout", sender: nil)
            //            }
        }
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: Storyboard
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "pickEvent":
                if let eventsTableViewController = segue.destinationViewController as? EventPickerViewController {
                    print("printing from nvc")
                    print("event: \(currentEvent?.eventIdentifier)")
                    print("event: \(currentEvent?.calendarItemIdentifier)")
                    eventsTableViewController.currentEventID = currentEvent?.title
                }
            default: break
            }
            
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "pickEvent" {
            
            if EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) == EKAuthorizationStatus.Authorized {
                return true
            } else {
                showAlertViewControllerWithHandler(title: "Error", message: "Cargi needs access to your calendar in order to make your driving experience even better.", handler: { (action) in
                    EKEventStore().requestAccessToEntityType(.Event) { (success, error) in
                        
                    }
                })
                return false
            }
        }
        return false
    }
    
    @IBAction func eventSelectedChanged(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func cancelChooseEvent(segue: UIStoryboardSegue) {
        
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
        dest.address = place.formattedAddress
        dest.name = place.name
        dest.coordinates = place.coordinate
        //        self.destLabel.text = place.name
        self.searchButton.setTitle(place.name, forState: .Normal)
        //        self.addrLabel.text = place.formattedAddress
        gasMarker = nil
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

extension UIViewController {
    func showAlertViewController(title title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(alertAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showAlertViewControllerWithHandler(title title: String?, message: String?, handler: ((action: UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: handler)
        alert.addAction(alertAction)
        presentViewController(alert, animated: true, completion: nil)
    }
}
