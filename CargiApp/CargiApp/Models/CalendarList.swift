//
//  CalendarList.swift
//  Cargi
//
//  Created by Maya Balakrishnan on 3/2/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import EventKit

/**
    Class used for accessing calendar events and reminders.
*/
class CalendarList {
    
    /**
        Asks for user's permission to access calendar events.
     */
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
    
    
    /**
         Looks through all calendar events and see which event is within the timeframe of interest.
     */
    private static func parseCalendar(calendar: EKCalendar, startDate: NSDate, endDate: NSDate) -> [EKEvent] {
        let predicate = EKEventStore().predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: nil)
        return parseCalendar(calendar, predicate: predicate)
    }
    

    /**
        Parse calendar events using a predicate (events that meet a specific condition).
        Use NSPredicate that are used for event stores.
     */
    private static func parseCalendar(calendar: EKCalendar, predicate: NSPredicate) -> [EKEvent] {
        let events = EKEventStore().eventsMatchingPredicate(predicate)
        return events
    }
    
    /**
        Default method for parsing calendar.
     
        Currently hard-coded to return all events that start 30 min before and 2 hrs after current time.
     */
    private static func parseCalendar(calendar: EKCalendar) -> [EKEvent] {
        // Look at all events 30 minutes prior to the current time
        let startDate = NSDate().dateByAddingTimeInterval(-30*60)
        // Look at all events within 2 hours after the current time.
        let endDate = NSDate().dateByAddingTimeInterval(2*60*60)
        return parseCalendar(calendar, startDate: startDate, endDate: endDate)
    }
    
    /**
        Print all reminders found in the Reminders app.
     */
    private static func printReminders() {
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForRemindersInCalendars([])
        eventStore.fetchRemindersMatchingPredicate(predicate, completion: { reminders in
            for reminder in reminders! {
                print("-\(reminder.title)")
            }
        })
    }
    
    /**
        Returns an array of all reminders found in the Reminders app.
     
        Note: currently returns nil.
     */
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
    
    /**
        Returns an array of all events found in the Apple Calendar app.
     */
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
            print("We need to help you give us permission")
        }
        return events
    }
    
    
}
