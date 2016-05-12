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
    
    // Singleton instance code - creds to http://anthon.io/how-to-share-data-between-view-controllers-in-swift/
    // This way all view controllers can access one instance of this database object
    class var sharedInstance: AzureDatabase {
        struct Static {
            static var instance: AzureDatabase?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = AzureDatabase()
        }
        
        return Static.instance!
    }

    
    var delegate: AppDelegate
    var client: MSClient
    var userTable: MSTable
    var eventTable: MSTable
    var eventContactsTable: MSTable
    var contactsTable: MSTable
    var logTable: MSTable
    var locationHistoryTable: MSTable
    var communicationHistoryTable: MSTable
    var actionLogTable: MSTable
    var userID: String?
    var contactDirectory = ContactDirectory()
    var contactID: String?
    var eventContactID: String?
    var curEventID: String?
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier =
    UIBackgroundTaskInvalid

    
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
        actionLogTable = client.tableWithName("actions_taken")
    }
    
    /**
     * initializeAndCreateUserID
     *
     * Given the device identifier string of the user's phone, this method looks up the userID associated
     * with this particular device, for easy retrieval of other information about the user stored in the database.
     * If a user is not found, this method automatically creates a user with the device ID, and leaves the name and email
     * fields empty. To update this newly created user, see updateUserData.
     * 
     * Example usage of device ID:
     * let deviceID = UIDevice.currentDevice().identifierForVendor!.UUIDString
     **/
    func initializeAndCreateUserID(deviceID: String, completionHandler: (status: String, success: Bool) -> Void)  {
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
     * initializeUserIDWithDeviceID
     *
     * Given the device identifier string of the user's phone, this method looks up the userID associated
     * with this particular device and initializes the userID of this database object for the current user.
     *
     * Example usage of device ID:
     * let deviceID = UIDevice.currentDevice().identifierForVendor!.UUIDString
     **/
    func initializeUserIDWithDeviceID(deviceID: String, completionHandler: (status: String, success: Bool) -> Void)  {
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
            completionHandler(status: "No user found", success: false)
        }
    }
    /**
     * initializeUserIDWithEmail
     *
     * Given the email of a user, this method looks up the userID associated
     * with this particular email and initializes the userID of this database object for the current user.
     **/
    func initializeUserIDWithEmail(email: String, completionHandler: (status: String, success: Bool) -> Void)  {
        let userCheckPredicate = NSPredicate(format: "email == [c] %@", email)
        
        userTable.readWithPredicate(userCheckPredicate) { (result, error) in
            if (error != nil) {
                print("Error in retrieval - server error", error!.description)
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
            completionHandler(status: "No user found", success: false)
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

    // needs testing
    func insertEvent(eventName: String?, latitude: NSNumber, longitude: NSNumber, dateTime: NSDate) {
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
            }
        }
    }
    
    func logUsage(startTime: NSDate?) {
        print("logging usage" )
        var startDateTime: NSDate
        if (startTime == nil) {
            if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid{
                UIApplication.sharedApplication().endBackgroundTask(
                    self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            }
            return
        } else {
            startDateTime = startTime!
        }
        let endTime = NSDate()
        let elapsedTime = endTime.timeIntervalSinceDate(startDateTime)
        
        var userID: String
        if self.userID != nil {
            userID = self.userID!
        } else {
            userID = "unknown"
        }
        let logObj = ["user_id": userID, "start_datetime": startDateTime, "end_datetime": endTime, "duration": elapsedTime]
        
        logTable.insert(logObj) { (insertedItem, error) in
            if error != nil {
                print("Error inserting log: " + error!.description)
            } else {
                print("Usage logged, id: " + String(insertedItem!["id"]))
            }
            if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid{
                UIApplication.sharedApplication().endBackgroundTask(
                    self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            }
        }
    }
    
    func logStartTime(completionHandler: (id: String, success: Bool) -> Void) {
        print("logging start time")
        let startTime = NSDate()
        let logObj = ["start_datetime": startTime]
        logTable.insert(logObj) { (insertedItem, error) in
            if error != nil {
                print("Error inserting start time: " + error!.description)
                completionHandler(id:"", success: false)
                return
            } else {
                print("Start time logged, id: " + String(insertedItem!["id"]))
                completionHandler(id: String(insertedItem!["id"]), success: true)
                return
            }
        }
    }
    
    func logEndTime(logID: String) {
        print("logging end time for", logID)
        let endTime = NSDate()
        let item = ["id": logID, "end_datetime": endTime]
        logTable.update(item) { (result, error) in
            if error != nil {
                print("error updating log data: " + error!.description)
            } else {
                print("updated log data", result);
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
    
    func checkEmailLogin(email: String, completionHandler: (status: String, success: Bool) -> Void) {
        var emailCheckPredicate: NSCompoundPredicate
        if self.userID != nil {
            // TODO: need to ensure that the userID is always initialized beforehand... maybe need to do this on launch
            emailCheckPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [NSPredicate(format: "user_id == %@", self.userID!), NSPredicate(format: "email = %@", email)])
        } else {
            let deviceID = UIDevice.currentDevice().identifierForVendor!.UUIDString
            emailCheckPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [NSPredicate(format: "device_id == %@", deviceID), NSPredicate(format: "email = %@", email)])
        }
        
        let emailCheckOnlyPredicate = NSPredicate(format: "email == %@", email)
        userTable.readWithPredicate(emailCheckOnlyPredicate) { (result, error) in
            if (error != nil) {
                print("Error in retrieval", error!.description)
                completionHandler(status: error!.description, success: false)
                return
            } else if result != nil {
                completionHandler(status: "Email is correct, matches user ID", success: true)
                return
            } else {
                completionHandler(status: "Email is incorrect, does not match user ID", success: false)
            }
        }

    }
    

    /**
    * Checks using regex whether an email is validly formatted.
    * Valid: "abc@mywebsite.gov.uk", "xyz@STANFORD.edu"
    * Invalid: "@blah.blah", xyz@", "lwker34@23klazxc"
    */
    func validateEmail(candidate: String) -> Bool {
        let regExp = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format:"SELF MATCHES %@", regExp).evaluateWithObject(candidate)
    }
    
    func emailExists(email: String, completionHandler: (status: String, exists: Bool) -> Void) {
        let emailCheckPredicate = NSPredicate(format: "email = %@", email)
        userTable.readWithPredicate(emailCheckPredicate) { (result, error) in
            if (error != nil) {
                print("Error in retrieval", error!.description)
                completionHandler(status: error!.description, exists: false)
                return
            } else if result != nil {
                if let items = result?.items {
                    if let _ = items.first {
                        completionHandler(status: "Email exists", exists: true)
                        return
                    }
                }
                completionHandler(status: "Email does not exist", exists: false)
            } else {
                completionHandler(status: "Email does not exist", exists: false)
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
//        var contact_id = ""
        self.getContactID(fullName) { (contactID, success) in
            if (success) {
                print("found contact ID for", fullName)
//                contact_id = contactID
                self.contactID = contactID
                let eventID = self.curEventID!
                let eventContactObj = ["event_id": eventID, "contact_id": self.contactID!]
                self.eventContactsTable.insert(eventContactObj) {
                    (insertedItem, error) in
                    if error != nil {
                        print("Error in inserting an event" + error!.description)
                    } else {
                        let x = String(insertedItem!["id"])
                        
                        print("Inserted event contact: ", String(insertedItem!["id"]))
                        self.eventContactID = x
                    }
                }
            } else {
                // if no contact is found, then we need to insert the contact in first before we can
                // insert it as an event contact
                self.insertContact(fullName) { (newContactID, success) in
                    if (success) {
//                        contact_id = newContactID!
                        self.contactID = newContactID!
                        let eventID = self.curEventID!

                        let eventContactObj = ["event_id": eventID, "contact_id": self.contactID!]
                        self.eventContactsTable.insert(eventContactObj) {
                            (insertedItem, error) in
                            if error != nil {
                                print("Error in inserting an event" + error!.description)
                            } else {
                                print("Inserted event contact: ", String(insertedItem!["id"]))
                                self.eventContactID = String(insertedItem!["id"])
                            }
                        }
                    } else {
                        // TODO: problem with azure, should probably throw an error
                    }
                }
            }
        }
       
    }
    
    /**
    * Update event contact
    *
//    */
    func updateEventContact(fullName: String?) {
        if (fullName == nil) { return } // cannot update a nonexisting contact
        self.getContactID(fullName!) { (contactID, success) in
            if (success) {
                print("found contact ID for", fullName)
                self.contactID = contactID
                let eventContactObj = ["id": self.eventContactID!, "event_id": self.curEventID!, "contact_id": self.contactID!]
                self.eventContactsTable.update(eventContactObj) {
                    (result, error) in
                    if error != nil {
                        print("Error in updating an event contact" + error!.description)
                    } else {
                        print("Updated event contact successfully")
                    }
                }
            } else {
                // if no contact is found, then we need to insert the contact in first before we can
                // insert it as an event contact
                self.insertContact(fullName!) { (newContactID, success) in
                    if (success) {
                        self.contactID = newContactID!
                        let eventContactObj = ["id": self.eventContactID!, "event_id": self.curEventID!, "contact_id": self.contactID!]
                        self.eventContactsTable.update(eventContactObj) {
                            (result, error) in
                            if error != nil {
                                print("Error in updating an event contact" + error!.description)
                            } else {
                                print("Updated event contact successfully")
                            }
                        }
                    } else {
                        // TODO: problem with azure, should probably throw an error
                    }
                }
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

    /**
    * Given the event details, this function stores the event in Azure. If no event name (user inputted destination in the search
    * bar, then the eventName is set as "unknown".
    * If there is a contact associated with the event, then the event contact table is also updated.
    */
    func insertEvent(eventName: String?, latitude: NSNumber, longitude: NSNumber, dateTime: NSDate, contactName: String?) {
            var event = "unknown"
            if eventName != nil {
                event = eventName!
            }
        let eventObj = ["user_id": self.userID!, "longitude": longitude, "latitude": latitude, "datetime": dateTime, "event_name":event]
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            self.eventTable.insert(eventObj) {
                (insertedItem, error) in
                if error != nil {
                    print("Error in inserting an event" + error!.description)
                } else {
                    print("Event inserted, id: " + String(insertedItem!["id"]))
                    print("event contact is ... ", contactName)
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
    }
    
    /**
    * The communication history table has the following columns: user_id, event_id, contact_id, and method.
    * The current event ID is stored as a variable, and is updated each time the user has a new event (whether it is pulled from
    * the calendar or a destination set by the user).
    */
    func insertCommunication(method: String) {
        // TODO: should we check if self.userID / self.curEventID / self.contactID exist?
        // the way we use the code, we will have initialized all variables
        let userID: String = self.userID ?? String()
        let eventID: String = self.curEventID ?? String()
        let contactID: String = self.contactID ?? String()
        
        let commObj = ["user_id": userID, "event_id": eventID, "contact_id": contactID, "method": method]
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.communicationHistoryTable.insert(commObj) {
                (insertedItem, error) in
                if  error != nil {
                    print("Error in inserting a communication" + error!.description)
                } else {
                    print("Communication inserted, id: " + String(insertedItem!["id"]))
                }
            }
        }
    }
    
    // Log actions taken by user to analyze user behavior & engagement
    // possible actions: "text", "call", "gas", "music", "search", "navigate", "refresh", "
    func insertAction(actionTaken: String) {
        
        let actionObj = ["user_id": self.userID!, "action": actionTaken]
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.actionLogTable.insert(actionObj) {
                (insertedItem, error) in
                if  error != nil {
                    print("Error in inserting an action" + error!.description)
                } else {
                    print("Action inserted, id: " + String(insertedItem!["id"]))
                }
            }
        }
    }
    
    func logNavigated() {
        
        let actionObj = ["user_id": self.userID!, "navigated": "true"]
        
        logTable.insert(actionObj) {
            (insertedItem, error) in
            if  error != nil {
                print("Error in inserting an action" + error!.description)
            } else {
                print("Action inserted, id: " + String(insertedItem!["id"]))
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
    
    /*
    * Creates new user with email & name, and initializes user ID
    */
    func createUser(email: String, fullname: String, completionHandler: (status: String, success: Bool) -> Void) {
        let user = ["name": fullname, "email": email]
        userTable.insert(user) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error!.description);
                completionHandler(status: error!.description, success: false)
            } else {
                print("User inserted and initialized user id: " + String(insertedItem!["id"]))
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