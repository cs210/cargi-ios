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
    var curEventID: String?
    
    
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
                    completionHandler(status: "Created new user and inserted into database", success: true)
                    return
                } else {
                    // TODO: print some error code
                    completionHandler(status: "Failed to create new user", success: false)

                }
            }
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
     * Given an array of contacts, this method inserts all contacts of the user (associated with the userID).
     *
     * Note: azure does not check for uniqueness, so this method will insert duplicates as of right now.
     * example usage:
     *   let contacts = self.contactDirectory.getAllPhoneNumbers()
     *   db.insertContacts(contacts)
     */
    func insertContacts(contacts: [String : [String]]) {
        for (contact, _) in contacts {
            let fullName = contact
            self.insertContact(fullName) { (newContactID, success) in
                if (success) {
                    // do nothing, don't need new contact ID
                } else {
                    // problem with azure database
                }
                
            }
                
        }
        
    }
    
    /**
     * contactExists
     *
     * Given a contact name, this function checks if the given contact exists in the database already.
     * If the contact exists, the contactID is returned in the status, and exists is set to true.
     * If the contact does not exist, the status reflects that and exists is false.
     * Usage:
     *  self.contactExists(fullName) { (status, exists) in
            if (exists) {
                // do not insert duplicate contact
            } else {
                // getContact
            }
     *  }
     */
    func contactExists(contactName: String, completionHandler: (status: String, exists: Bool) -> Void) {
        let contactCheckPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [NSPredicate(format: "user_id == %@", self.userID!), NSPredicate(format: "name = %@", contactName)])

        contactsTable.readWithPredicate(contactCheckPredicate) { (result, error) in
            if (error != nil) {
                print("Error in retrieval", error!.description)
                completionHandler(status: error!.description, exists: false)
                return
            } else if result != nil {
                completionHandler(status: "Contact exists", exists: true)
                return
            } else {
                completionHandler(status: "Contact does not exist", exists: false)
            }
        }
    }
    
    /**
    * Inserts a contact into the database associated with the current user.
    * 
    * To avoid inserting duplicate contacts, use the contactExists function to check before inserting.
    */
    func insertContact(fullName: String, completionHandler: (newContactID: String?, success: Bool) -> Void) {
        let contactObj = ["user_id": self.userID!, "name": fullName]
    
        self.contactsTable.insert(contactObj) { (insertedItem, error) in
            if error != nil {
                print("Error inserting contact: " + error!.description);
                completionHandler(newContactID: nil, success: false)
                return
            } else {
                print("Contact inserted, id: " + String(insertedItem!["id"]))
                completionHandler(newContactID: String(insertedItem!["id"]), success: true)
                return
            }
        }
    }
    
    /*
    * Given the full name of a contact associated with an event, this function inserts an event contact into the database.
    */
    func insertEventContact(fullName: String) {
        var contact_id = ""
        self.getContactID(fullName) { (contactID, success) in
            if (success) {
                contact_id = contactID
            } else {
                self.insertContact(fullName) { (newContactID, success) in
                    if (success) {
                        contact_id = newContactID!
                    } else {
                        // TODO: problem with azure, should probably throw an error
                    }
                }
            }
        }
        let eventContactObj = ["event_id": self.curEventID!, "contact_id": contact_id]
        eventContactsTable.insert(eventContactObj) {
            (insertedItem, error) in
            if error != nil {
                print("Error in inserting an event" + error!.description)
            } else {
                print("Inserted event contact: ", String(insertedItem!["id"]))
            }
        }
    }
    
    /**
     * Given a contact name, this function retrieves the contact ID from the Azure database.
     * If successful, success is set to true and the contactID is populated with the data.
     * If the contact is not found, or there was a problem with Azure, success is set to false and the contactID is nil.
     */
    func getContactID(contactName: String, completionHandler:(contactID: String, success: Bool) -> Void) {
        let contactCheckPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [NSPredicate(format: "user_id == %@", self.userID!), NSPredicate(format: "name = %@", contactName)])
        
        contactsTable.readWithPredicate(contactCheckPredicate) { (result, error) in
            if (error != nil) {
                print("Could not retrieve contactID", error!.description)
                completionHandler(contactID: "", success: false)
                return
            } else if let items = result?.items {
                if let item = items.first {
                    if let contactID = item["id"] as? String {
                        completionHandler(contactID: contactID, success: true)
                        return
                    }
                }
            }
            completionHandler(contactID: "", success: false)
        }
    }
//    func 
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
    
    func insertEvent(eventName: String?, latitude: NSNumber, longitude: NSNumber, dateTime: NSDate, contactName: String?) {
            var event = ""
            if eventName != nil {
                event = eventName!
            }
    
            let eventObj = ["user_id": self.userID!, "longitude": longitude, "latitude": latitude, "datetime": dateTime, "event_name":event]
    
            eventTable.insert(eventObj) {
                (insertedItem, error) in
                if error != nil {
                    print("Error in inserting an event" + error!.description)
                } else {
                    print("Event inserted, id: " + String(insertedItem!["id"]))
                    self.curEventID = String(insertedItem!["id"])
                    if contactName != nil {
                        self.insertEventContact(contactName!)
                    } else {
                        // no contact associated with event
                        // do nothing for now
                    }
                }
            }
        }
    
    /**
    * The communication history table has the following columns: user_id, event_id, contact_id, and method.
    * The current event ID is stored as a variable, and is updated each time the user has a new event (whether it is pulled from
    * the calendar or a destination set by the user).
    */
    func insertCommunication(method: String) {
        // TODO: should we check if self.userID / self.curEventID / self.contactID exist?
        // the way we use the code, we will have initialized all variables
        let commObj = ["user_id": self.userID!, "event_id": self.curEventID!, "contact_id": self.contactID!, "method": method]

        communicationHistoryTable.insert(commObj) {
            (insertedItem, error) in
            if  error != nil {
                print("Error in inserting a communication" + error!.description)
            } else {
                print("Communication inserted, id: " + String(insertedItem!["id"]))
            }
        }
    }
    
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