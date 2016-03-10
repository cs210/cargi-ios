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

class NavigationViewController: UIViewController, NSURLConnectionDataDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate,
                                MFMessageComposeViewControllerDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    
    let apiKey: String = "AIzaSyB6LumdXIastAI0rhSiSVTdLNStQb9UUP8"
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
    
    
    
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    let defaultLatitude: CLLocationDegrees = 37.426
    let defaultLongitude: CLLocationDegrees = -122.172
    var destLatitude = String()
    var destLongitude = String()
    
    @IBOutlet var dashboardView: UIView!
    var manager: CBCentralManager!
    var currentEvent: EKEvent?
    
    var contact: String?
    var contactNumbers: [String]?
    @IBOutlet var contactName: UILabel!
    
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
        
        // call button shadow
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
        
        
        
        
//        callButton.contentEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)
//        textButton.contentEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)
        
        let camera = GMSCameraPosition.cameraWithLatitude(defaultLatitude,
            longitude: defaultLongitude, zoom: 13)
//        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.camera = camera
        
//        marker = GMSMarker()
//        marker.position = CLLocationCoordinate2DMake(37.426, 151.20)
//        marker.title = "Stanford"
//        marker.map = mapView

//        getTimeToDestination("Sydney+AUS", dest: "Newcastle+AUS")
//        print("CONTACTS: ")
//        printContacts()
        
//        print("EVENTS: ")
//        printEvents()
//        print("REMINDERS: ")
//        printReminders()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
//        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        syncData(shouldOpenMaps: false)
//          manager = CBCentralManager(delegate: self, queue: nil)
//        LocalNotifications.sendNotification()
    }
    
    func syncData(shouldOpenMaps shouldOpenMaps: Bool) {
        let contacts = ContactList.getAllContacts()
        guard let events = CalendarList.getAllCalendarEvents() else { return }
        
        for ev in events {
            guard let _ = ev.location else { continue } // ignore event if it has no location info.
            for contact in contacts.keys {
                if ev.title.rangeOfString(contact) != nil {
                    currentEvent = ev
                    self.contact = contact
                }
            }
        }
        
        contactNumbers = ContactList.getContactPhoneNumber(self.contact)

        guard let ev = currentEvent else { return }
        contactName.text = self.contact
        eventLabel.text = ev.title
//        destLabel.text = ev.structuredLocation?.title
        
        guard let coordinate = ev.structuredLocation?.geoLocation?.coordinate else { return }
        destLatitude = String(coordinate.latitude)
        destLongitude = String(coordinate.longitude)
        if let loc = ev.location {
            let locArr = loc.characters.split { $0 == "\n" }.map(String.init)
            destLabel.text = locArr[0]
            if locArr.count > 1 {
                addrLabel.text = locArr[1]
            } else {
                addrLabel.text = ""
            }
        }
        
        if shouldOpenMaps {
            openMaps()
        }
    }
    
    func openMaps() {
        guard let ev = currentEvent else { return }
        switch (CLLocationManager.authorizationStatus()) {
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                LocationServices.searchLocation(ev.location!)
            default: break
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("updating location")
    }
    
    @IBAction func update(sender: UIButton) {
        if let _ = currentEvent {
            openMaps()
        } else {
            syncData(shouldOpenMaps: true)
        }
    }
    
    func callPhone(phoneNumbers: [String]?) {
        // UIApplication.sharedApplication().openURL(NSURL(string: "tel://6073791277")!)
        guard let numbers = phoneNumbers else { return }
        let number = numbers[0] as NSString
        let charactersToRemove = NSCharacterSet.alphanumericCharacterSet().invertedSet
        let numberToCall = number.componentsSeparatedByCharactersInSet(charactersToRemove).joinWithSeparator("")
        
        let stringURL = "tel://\(numberToCall)"
        print(stringURL)
        guard let url = NSURL(string: stringURL) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    func sendMessage(phoneNumbers: [String]?, duration: String) {
        guard let numbers = phoneNumbers else { return }
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = "Hi, I will arrive in \(duration)."
            controller.recipients = [numbers[0]] // Send only to the primary number
            print(controller.recipients)
            controller.messageComposeDelegate = self
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
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
    
    private func printContacts() {
        // Print all the contacts
        let contacts = ContactList.getAllContacts()
        for (contact, numbers) in contacts {
            for number in numbers {
                print(contact + ": " + number)
            }
        }
    }
    
    private func printEvents() {
        // Print all events in calendars.
        guard let events = CalendarList.getAllCalendarEvents() else { return }
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
    
    private func printReminders() {
        // Print all reminders
        CalendarList.getAllReminders()
    }
    
    func getTimeToDestination(origin: String, dest: String) {
        let url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(origin)&destinations=\(dest)&key=\(apiKey)"
        print(url)
        let request: NSURLRequest? = NSURLRequest(URL: NSURL(string: url)!)
        guard let URLrequest = request else {
            print("-___-")
            return
        }
//        let config = NSURLSessionConfiguration()
//        guard let session = NSURLSession(configuration: NSURLSessionConfiguration())
        guard let connection = NSURLConnection(request: URLrequest, delegate: self) else {
            print(":(")
            return
        }
        connection.start()
    }
    
    func getTimeToDestination(origin1: String, origin2: String, dest1: String, dest2: String) {
        let url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(origin1),\(origin2)&destinations=\(dest1),\(dest2)&key=\(apiKey)"
        print(url)
        let request: NSURLRequest? = NSURLRequest(URL: NSURL(string: url)!)
        guard let URLrequest = request else {
            print("-___-")
            return
        }
        //        let config = NSURLSessionConfiguration()
        //        guard let session = NSURLSession(configuration: NSURLSessionConfiguration())
        guard let connection = NSURLConnection(request: URLrequest, delegate: self) else {
            print(":(")
            return
        }
        connection.start()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        print("\nconnectionDidFinishLoading\n")
//        let stringData: NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
//        print(stringData)
        var jsonResult: NSDictionary?
        do {
            jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
        } catch {
            print("ERROR")
        }
        
        guard let json = jsonResult else { return }
        if let rows = json["rows"] as? NSArray {
            if let row = rows[0] as? NSDictionary {
                if let elements = row["elements"] as? NSArray {
                    if let elem = elements[0] as? NSDictionary {
                        if let duration = elem["duration"] as? NSDictionary {
                            if let time = duration["text"] as? String {
                                sendMessage(contactNumbers, duration: time)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        // Received a new request, clear out the data object
        self.data = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        print("\nYAY!\n")
        self.data.appendData(data)
    }
    
    @IBAction func refreshButtonClicked(sender: UIButton) {
        syncData(shouldOpenMaps: false)
    }
    
    
    
    @IBAction func gasButtonClicked(sender: UIButton) {
        let alert = UIAlertController(title: "Under Construction", message: "Oh no, Cargi is low on gas!", preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(alertAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func searchButtonClicked(sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func sendTextMessage(sender: UIButton) {
        syncData(shouldOpenMaps: false)
        let locValue: CLLocationCoordinate2D = locationManager.location!.coordinate
        getTimeToDestination(locValue.latitude.description, origin2: locValue.longitude.description,
                             dest1: destLatitude, dest2: destLongitude)
    }
    
    
    @IBAction func callPhoneNumber(sender: UIButton) {
        callPhone(contactNumbers)
    }
    
    @IBAction func openMusicApp(sender: UIButton) {
        let appName: String = "spotify"
        
        let appURL: String = "\(appName)://spotify:user:spotify:playlist:5FJXhjdILmRA2z5bvz4nzf"
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!)) {
            print(appURL)
            UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
        } else {
            print("Can't use spotify://");
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.myLocationEnabled = true
        }
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    
}

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
