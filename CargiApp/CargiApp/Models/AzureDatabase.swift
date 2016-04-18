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
    func getUserID(deviceID: String, completionHandler: (status: String, success: Bool) -> Void)  {
        let userCheckPredicate = NSPredicate(format: "device_id == [c] %@", deviceID)
        userID = nil
        
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
                } else {
                    // TODO: print some error code
                }
            }
            completionHandler(status: "No userID found, inserted user into database", success: false)
        }
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
                completionHandler(status: "User inserted into database", success: true)
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