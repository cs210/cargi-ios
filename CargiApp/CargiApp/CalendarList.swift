//
//  CalendarList.swift
//  Cargi
//
//  Created by Maya Balakrishnan on 3/2/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import EventKit

class CalendarList {
    
    private static func requestForAccessToCalendarEvents() {
        let eventStore = EKEventStore()
        eventStore.requestAccessToEntityType(.Event, completion: {
            (accessGranted: Bool, error: NSError?) in
            if accessGranted == true {
                dispatch_async(dispatch_get_main_queue(), {
                    print("Access granted")
//                        self.loadCalendars()
//                        self.refreshTableView()
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
//                        self.needPermissionView.fadeIn()
                })
            }
        })
    }
    
    
    private static func parseCalendar(calendar: EKCalendar, startDate: NSDate, endDate: NSDate) -> [EKEvent] {
        let predicate = EKEventStore().predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: nil)
        return parseCalendar(calendar, predicate: predicate)
    }
    

    private static func parseCalendar(calendar: EKCalendar, predicate: NSPredicate) -> [EKEvent] {
        let events = EKEventStore().eventsMatchingPredicate(predicate)
        
//        if i.title == "Test Title" {
//            print("YES" )
//            // Uncomment if you want to delete
//            //eventStore.removeEvent(i, span: EKSpanThisEvent, error: nil)
//        }
        return events
    }
    
    
    // Default version: get all events from 24 hours ago to now.
    private static func parseCalendar(calendar: EKCalendar) -> [EKEvent] {
        let startDate = NSDate().dateByAddingTimeInterval(-60*60*24)
        let endDate = NSDate()//.dateByAddingTimeInterval(60*60*24*3)
        return parseCalendar(calendar, startDate: startDate, endDate: endDate)
    }
    
    private static func printReminders() {
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForRemindersInCalendars([])
        eventStore.fetchRemindersMatchingPredicate(predicate, completion: { reminders in
            for reminder in reminders! {
                print("-\(reminder.title)")
            }
        })
    }
    
    // Currently returns nil
    static func getAllReminders() -> [EKReminder]? {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        print(String(status))
        switch (status) {
        case EKAuthorizationStatus.NotDetermined:
            requestForAccessToCalendarEvents()
        case EKAuthorizationStatus.Authorized:
            printReminders()
        case EKAuthorizationStatus.Restricted, EKAuthorizationStatus.Denied:
            print("We need to help you give us permission")
        }
        return nil
        // return reminders
    }
    
    static func getAllCalendarEvents() -> [EKEvent]? {
        var events: [EKEvent]?
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        print(String(status))
        switch (status) {
        case EKAuthorizationStatus.NotDetermined:
            requestForAccessToCalendarEvents()
            
        case EKAuthorizationStatus.Authorized:
            // Things are in line with being able to show the calendars in the table view
//            loadCalendar()
            let calendars = EKEventStore().calendarsForEntityType(EKEntityType.Event)
            events = parseCalendar(calendars[0])
        case EKAuthorizationStatus.Restricted, EKAuthorizationStatus.Denied:
            // We need to help them give us permission
            print("We need to help you give us permission")
        }
        return events
    }
    
    
}
