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

class NavigationViewController: UIViewController, NSURLConnectionDataDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate,
                                MFMessageComposeViewControllerDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    
    let apiKey: String = "AIzaSyB6LumdXIastAI0rhSiSVTdLNStQb9UUP8"
    var marker: GMSMarker = GMSMarker()
    var data: NSData?
    
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    let defaultLatitude = 37.426
    let defaultLongitude = -122.172
    
    var manager: CBCentralManager!
    
    var contact: String?
    var contactNumbers: [String]?
    @IBOutlet var contactName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        syncData()
//          manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func syncData() {
        let contacts = ContactList.getAllContacts()
        guard let events = CalendarList.getAllCalendarEvents() else { return }
        print(events)
        
        var event: EKEvent?
        for ev in events {
            for contact in contacts.keys {
                if ev.title.rangeOfString(contact) != nil {
                    event = ev
                    self.contact = contact
                }
            }
        }
        print(event)
        
        contactNumbers = ContactList.getContactPhoneNumber(self.contact)

        guard let ev = event else { return }
        contactName.text = self.contact
        LocationServices.searchLocation(ev.location!)
    }
    
    @IBAction func update(sender: UIButton) {
        syncData()
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
    
    func sendMessage(phoneNumbers: [String]?) {
        guard let numbers = phoneNumbers else { return }
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = "Hello, welcome to Cargi!"
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
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func sendTextMessage(sender: UIButton) {
        sendMessage(contactNumbers)
    }
    
    
    @IBAction func callPhoneNumber(sender: UIButton) {
        callPhone(contactNumbers)
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
