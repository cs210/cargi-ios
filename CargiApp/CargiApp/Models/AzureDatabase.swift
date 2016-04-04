//
//  AzureDatabase.swift
//  Cargi
//
//  Created by Emily J Tang on 4/3/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation

class AzureDatabase {
    
    init() {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let client = delegate.client!
        let item = ["text":"Excellent item"]
        let itemTable = client.tableWithName("Item")
        itemTable.insert(item) {
            (insertedItem, error) in
            if error != nil {
                print("Error" + error.description);
            } else {
                print("Item inserted, id: " + String(insertedItem["id"]))
            }
        }
    }
}