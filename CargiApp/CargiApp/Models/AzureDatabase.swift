//
//  AzureDatabase.swift
//  Cargi
//
//  Created by Emily J Tang on 4/3/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation

/**
    Database backed by Microsoft Azure.
 */
class AzureDatabase {
    
    var delegate: AppDelegate
    var client: MSClient
    var userTable: MSTable
    var eventTable: MSTable
    var eventContactsTable: MSTable
    var contactsTable: MSTable
    var logTable: MSTable
    var locationHistoryTable: MSTable
    var communicationHistoryTable: MSTable
    var userID: String?

    init() {
        delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        client = delegate.client!
        userTable = client.tableWithName("users")
        eventTable = client.tableWithName("event_history")
        eventContactsTable = client.tableWithName("event_contacts")
        contactsTable = client.tableWithName("contacts")
        logTable = client.tableWithName("log")
        locationHistoryTable = client.tableWithName("location_history")
        communicationHistoryTable = client.tableWithName("communication_history")
    }
    
    /**
     * getUserID
     * 
     * Given the device identifier string of the user's phone, this method looks up the userID associated 
     * with this particular device, for easy retrieval of other information about the user stored in the database.
     * UIDevice.currentDevice().identifierForVendor!.UUIDString
     **/
    func initializeUserID(deviceID: String, completionHandler: (status: String, success: Bool) -> Void)  {
        let userCheckPredicate = NSPredicate(format: "device_id == [c] %@", deviceID)
        
        userTable.readWithPredicate(userCheckPredicate) { (result, error) in
            if error != nil {
                print("Error in retrieval", error.description)
                completionHandler(status: error.description, success: false)
                return
            } else if let items = result?.items {
                if let item = items.first {
                    if let userID = item["id"] as? String {
                        self.userID = userID
                        completionHandler(status: "success", success: true)
                        return
                    }
                }
            }
            self.insertUser(deviceID) { (status, success) in
                if success {
                    print(status)
                    print("Just inserted user to database, user id: " + self.userID!)
                } else {
                    // TODO: print some error code
                }
            }
            completionHandler(status: "No userID found, inserted user into database", success: false)
        }
    }
    
    /**
    * Given a phone number, this function updates the user's data in the Azure database to store the correct phone number.
    * Necessary right now because the login page is still a WIP.
    */
    func updatePhoneNumber(phoneNumber: String) {
        let item = ["id": self.userID!, "phone_number": phoneNumber]
        userTable.update(item) { (result, error) in
            if error != nil {
                print("error updating user phone number: " + error.description)
            } else {
                print("updating user phone number worked?")
                print(result);
            }
        }
    }
    
    /**
    * Given an array of contacts, this method inserts the contacts of the user (associated with the userID). 
    *
    * Note: azure does not check for uniqueness, so this method will insert duplicates as of right now.
    * example usage:
    *   let contacts = self.contactDirectory.getAllPhoneNumbers()
    *   db.insertContacts(contacts)
    */
    
    func insertContacts(contacts: [String : [String]]) {
        for (contact, numbers) in contacts {
            let names = contact.characters.split { $0 == " " }.map(String.init)
            var firstName = ""
            var lastName = ""
            var phoneNumber = ""
            if let first = names.first {
                firstName = first
            }
            if let last = names.last {
                lastName = last
            }
            if let phone = numbers.first {
                phoneNumber = phone
            }
            let contactObj = ["user_id": self.userID!, "first_name": firstName, "last_name": lastName, "phone_number": phoneNumber]
            
            print(contactObj)
            contactsTable.insert(contactObj) {
                (insertedItem, error) in
                if error != nil {
                    print("Error" + error.description);
                } else {
                    print("Item inserted, id: " + String(insertedItem["id"]))
                }
            }
        }
    }
    
    func insertEvent() {
        // TODO
        // user_id
        // event_name
        // longitude
        // latitude
        // datetime
        
    }
    func insertCommunication() {
        // TODO
        // user_id, event_id, contact_id, method
    }
    
    /**
     * This method inserts a new user into the Azure database table, storing his/her device identifier.
     *
     * Returns a status and a success boolean variable; success is true if the user was inserted successfully, false if not.
     **/
    func insertUser(deviceID: String, completionHandler: (status: String, success: Bool) -> Void) {
        let user = ["device_id": deviceID]
        userTable.insert(user) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error.description);
                completionHandler(status: error.description, success: false)
            } else {
                print("Item inserted, id: " + String(insertedItem["id"]))
                self.userID = String(insertedItem["id"])
                completionHandler(status: "User inserted into database", success: true)
            }
        }
    }
    
    /**
     * Function that populates the location_history table with some dummy data, to test out our machine learning backend code.
     */
    func insertDefaultLocationHistory() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-DD hh-mm-ss"
        
        let date1 = dateFormatter.dateFromString("2016-04-18 11:00:00")
        let date2 = dateFormatter.dateFromString("2016-04-23 10:55:00")
        let date3 = dateFormatter.dateFromString("2016-04-30 11:00:00")
        
        
        let obj1 = ["datetime": date1!, "latitude": 37.425421, "longitude": -122.164089, "user_id": "kartiks2"]
        let obj2 = ["datetime": date2!, "latitude": 37.425421, "longitude": -122.164089, "user_id": "kartiks2"]
        let obj3 = ["datetime": date3!, "latitude": 37.425575, "longitude": -122.165309, "user_id": "kartiks2"]
        
        locationHistoryTable.insert(obj1) {
            (insertedItem, error) in
            if error != nil {
                print("Problem inserting location: " + error.description);
            } else {
                print("Location 1 inserted, id: " + String(insertedItem["id"]))
            }
        }
        locationHistoryTable.insert(obj2) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error.description);
            } else {
                print("Location 2 inserted, id: " + String(insertedItem["id"]))
            }
        }
        locationHistoryTable.insert(obj3) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error.description);
            } else {
                print("Location 3 inserted, id: " + String(insertedItem["id"]))
            }
        }
    }
    
    /**
     * Example code for inserting an item into the Azure database
     *
     * Note that email is unique in the database, so need to change the defaultUser info.
     **/
    func insertDefaultUser() {
        let defaultUser = ["phone_number":"000"]
        userTable.insert(defaultUser) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error.description);
            } else {
                print("Item inserted, id: " + String(insertedItem["id"]))
            }
        }
    }
    
    /**
     * Example code for getting an item from Azure database
     **/
    func getDefaultUser() {
        let userPhone = "000"
        let userCheckPredicate = NSPredicate(format: "phone_number == [c] %@", userPhone)
        
        userTable.readWithPredicate(userCheckPredicate) { (result, error) in
            if error != nil {
                print("Error in retrieval", error.description)
            } else if let items = result?.items {
                for item in items {
                    print("User object: ", item["id"])
                }
            }
        }
    }
    
}