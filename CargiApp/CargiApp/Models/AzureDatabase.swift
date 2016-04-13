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
    
    init() {
        delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        client = delegate.client!
        userTable = client.tableWithName("user")
    }
    
    /**
     * Example code for inserting an item into the Azure database
     *
     * Note that email is unique in the database, so need to change the defaultUser info.
     **/
    func insertDefaultUser() {
        let defaultUser = ["email":"edpark@stanford.edu", "password":"123"]
        let userTable = client.tableWithName("user")
        userTable.insert(defaultUser) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error.description);
            } else {
                print("Item inserted, id: " + String(insertedItem["user_id"]))
            }
        }
    }
    
    /**
     * Example code for getting an item from Azure database
     **/
    func getDefaultUser() {
        let userEmail = "taragb@stanford.edu"
        let userCheckPredicate = NSPredicate(format: "email == [c] %@", userEmail)
        
        userTable.readWithPredicate(userCheckPredicate) { (result, error) in
            if error != nil {
                print("Error in retrieval", error.description)
            } else if let items = result?.items {
                for item in items {
                    print("User object: ", item["email"])
                }
            }
        }
    }
    
}