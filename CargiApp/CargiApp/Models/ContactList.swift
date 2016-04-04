//
//  ContactList.swift
//  Cargi
//
//  Created by Edwin Park on 3/1/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import Contacts


/**
    Class for accessing and parsing contacts stored on the device.
 */
class ContactList {
    
    /**
        Retrieve all contacts stored on the device. Each key (name) maps to a list of phone numbers.
     */
    static func getAllContacts() -> [String:[String]] {
        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containersMatchingPredicate(nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainerWithIdentifier(container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContactsMatchingPredicate(fetchPredicate, keysToFetch: keysToFetch)
                results.appendContentsOf(containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        var contacts = [String:[String]]()
        for person in results {
            // Make full name as first and last name separated by space.
            let fullName = person.givenName + " " + person.familyName
            var numbers = [String]()
            for phoneNumber in person.phoneNumbers {
                let number = phoneNumber.value as! CNPhoneNumber
                numbers.append(number.stringValue)
            }
            contacts[fullName] = numbers
        }
        
        return contacts
    }
    
    // Retrieve phone numbers for a particular ocntact.
    static func getContactPhoneNumber(contactName: String?) -> [String]? {
        let contacts = getAllContacts()
        guard let name = contactName else { return nil }
        guard let contact = contacts[name] else { return nil }
        return contact
    }
}