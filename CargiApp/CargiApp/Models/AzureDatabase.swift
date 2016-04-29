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
    var contactDirectory = ContactDirectory()
    var contactID: String?
    
    //    var curEventID: String
    
    
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
     * initializeUserID
     *
     * Given the device identifier string of the user's phone, this method looks up the userID associated
     * with this particular device, for easy retrieval of other information about the user stored in the database.
     * UIDevice.currentDevice().identifierForVendor!.UUIDString
     **/
    func initializeUserID(deviceID: String, completionHandler: (status: String, success: Bool) -> Void)  {
        let userCheckPredicate = NSPredicate(format: "device_id == [c] %@", deviceID)
        
        userTable.readWithPredicate(userCheckPredicate) { (result, error) in
            if (error != nil) {
                print("Error in retrieval", error!.description)
                completionHandler(status: error!.description, success: false)
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
            self.createUser(deviceID) { (status, success) in
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
     * Given the user's name and email, this function updates the user's email address in the Azure database.
     * This function will be used when the user signs up for Cargi, as the user ID is initialized automatically every time the user
     * opens up Cargi, for easy communication with Azure.
     */
    func updateUserData(name: String, email: String) {
        let item = ["id": self.userID!, "name": name, "email": email]
        userTable.update(item) { (result, error) in
            if error != nil {
                print("error updating user data: " + error!.description)
            } else {
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
            
            self.insertContact(firstName, lastName: lastName, phoneNumber: phoneNumber)
            //            let contactObj = ["user_id": self.userID!, "first_name": firstName, "last_name": lastName, "phone_number": phoneNumber]
            //
            //            print(contactObj)
            //            contactsTable.insert(contactObj) {
            //                (insertedItem, error) in
            //                if error != nil {
            //                    print("Error" + error!.description);
            //                } else {
            //                    print("Item inserted, id: " + String(insertedItem!["id"]))
            //                }
            //            }
        }
    }
    
    func insertContact(firstName: String, lastName: String, phoneNumber: String) {
        let contactObj = ["user_id": self.userID!, "first_name": firstName, "last_name": lastName, "phone_number": phoneNumber]
        
        contactsTable.insert(contactObj) {
            (insertedItem, error) in
            if error != nil {
                print("Error inserting contact: " + error!.description);
            } else {
                print("Contact inserted, id: " + String(insertedItem!["id"]))
            }
        }
    }
    
    /**
     *
     */
//    func getContactID(phoneNumber: String) {
//        let contactCheckPredicate = NSPredicate(format: "phone_number == [c] %@", phoneNumber)
//        contactsTable.readWithPredicate(contactCheckPredicate) { (result, error) in
//            if (error != nil) {
//                print("Error in retrieval", error!.description)
//                return
//            } else if let items = result?.items {
//                if let item = items.first {
//                    if let contact = item["id"] as? String {
//                        self.contactID = contact
//                    }
//                }
//            }
//            
//            var contactName = self.contactDirectory.getContactName(phoneNumber);
//            if let contact = contactName {
//                var names = contact.characters.split { $0 == " " }.map(String.init)
//                var firstName = ""
//                var lastName = ""
//                if let first = names.first {
//                    firstName = first
//                }
//                if let last = names.last {
//                    lastName = last
//                }
//                self.insertContact(firstName, lastName: lastName, phoneNumber: phoneNumber) { (status, success) in
//                    if success {
//                        print(status)
//                        print("Just inserted user to database, user id: " + self.userID!)
//                    } else {
//                        // TODO: print some error code
//                    }
//                }
//            } else {
//                
//            }
//            
//            
//                       //            completionHandler(status: "No userID found, inserted user into database", success: false)
//        }
//        
//    }
    // needs testing
    //    func insertEvent(eventName: String?, latitude: NSNumber, longitude: NSNumber, dateTime: NSDate) {
    //        var event = ""
    //        if eventName != nil {
    //            event = eventName!
    //        }
    //
    //        let eventObj = ["user_id": self.userID!, "longitude": longitude, "latitude": latitude, "datetime": dateTime, "event_name":event]
    //
    //        eventTable.insert(eventObj) {
    //            (insertedItem, error) in
    //            if error != nil {
    //                print("Error in inserting an event" + error!.description)
    //            } else {
    //                print("Event inserted, id: " + String(insertedItem!["id"]))
    //                self.curEventID = insertedItem!["id"]
    //            }
    //
    //
    //            let eventContactObj = ["event_id": self.curEventID, "contact_id": ]
    //
    //        }
    //    }
    
    /**
    * The communication history table has the following columns: user_id, event_id, contact_id, and method.
    * The current event ID is stored as a variable, and is updated each time the user has a new event (whether it is pulled from
    * the calendar or a destination set by the user).
    */
    //    func insertCommunication(contactID: String, method: String) {
    //        let commObj = ["user_id": self.userID!, "event_id": self.curEventID, "contact_id": contactID, "method": method]
    //
    //        communicationHistoryTable.insert(commObj) {
    //            (insertedItem, error) in
    //            if  error != nil {
    //                print("Error in inserting a communication" + error!.description)
    //            } else {
    //                print("Communication inserted, id: " + String(insertedItem!["id"]))
    //            }
    //        }
    //    }
    
    /**
    * This method inserts a new user into the Azure database table, storing his/her device identifier.
    *
    * Returns a status and a success boolean variable; success is true if the user was inserted successfully, false if not.
    **/
    func createUser(deviceID: String, completionHandler: (status: String, success: Bool) -> Void) {
        let user = ["device_id": deviceID]
        userTable.insert(user) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error!.description);
                completionHandler(status: error!.description, success: false)
            } else {
                print("Item inserted, id: " + String(insertedItem!["id"]))
                self.userID = String(insertedItem!["id"])
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
        
        
        let obj1 = ["datetime": date1!, "latitude": 37.425421, "longitude": -122.164089, "user_id": "emjtang"]
        let obj2 = ["datetime": date2!, "latitude": 37.425421, "longitude": -122.164089, "user_id": "kartiks2"]
        let obj3 = ["datetime": date3!, "latitude": 37.425575, "longitude": -122.165309, "user_id": "kartiks2"]
        
        locationHistoryTable.insert(obj1) {
            (insertedItem, error) in
            if error != nil {
                print("Problem inserting location: " + error!.description);
            } else {
                print("Location 1 inserted, id: " + String(insertedItem!["id"]))
            }
        }
        locationHistoryTable.insert(obj2) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error!.description);
            } else {
                print("Location 2 inserted, id: " + String(insertedItem!["id"]))
            }
        }
        locationHistoryTable.insert(obj3) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error!.description);
            } else {
                print("Location 3 inserted, id: " + String(insertedItem!["id"]))
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
                print("Error" + error!.description);
            } else {
                print("Item inserted, id: " + String(insertedItem!["id"]))
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
                print("Error in retrieval", error!.description)
            } else if let items = result?.items {
                for item in items {
                    print("User object: ", item["id"])
                }
            }
        }
    }
    
}