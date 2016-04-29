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
class ContactDirectory {
    
    private var contacts = [String:[String]]()
    
    /**
        Retrieve all contacts stored on the device. Each key (name) maps to a list of phone numbers.
     */
    init() {
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
        
        self.contacts = [String:[String]]()
        for person in results {
            // Make full name as first and last name separated by space.
            let fullName = person.givenName + " " + person.familyName
            var numbers = [String]()
            for phoneNumber in person.phoneNumbers {
                let number = phoneNumber.value as! CNPhoneNumber
                numbers.append(number.stringValue)
            }
            self.contacts[fullName] = numbers
        }
        
    }
    
    func getAllPhoneNumbers() -> [String : [String]] {
        return contacts
    }
    
    // Retrieve phone numbers for a particular contact.
    func getPhoneNumber(contactName: String?) -> [String]? {
        guard let name = contactName else { return nil }
        return contacts[name]
    }
    
    func getContactName(numberToFind: String) -> String? {
        for (contact, numbers) in contacts {
//            let names = contact.characters.split { $0 == " " }.map(String.init)
//            var firstName = ""
//            var lastName = ""
            var phoneNumber = ""
//            if let first = names.first {
//                firstName = first
//            }
//            if let last = names.last {
//                lastName = last
//            }
            if let phone = numbers.first {
                phoneNumber = phone
            }
            
            if (phoneNumber == numberToFind) {
                return contact.characters
            }
        }
        return nil;
    }
}