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
    
    var calendars: [EKCalendar]?
    
    static func getAllEvents() -> String {
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        switch (status) {
        case EKAuthorizationStatus.NotDetermined:
            print("not determined")
            eventStore.requestAccessToEntityType(.Event, completion: {
                (accessGranted: Bool, error: NSError?) in
                if accessGranted == true {
                    dispatch_async(dispatch_get_main_queue(), {
                        print("access granted!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                        var calendars: [EKCalendar]?
                        calendars = eventStore.calendarsForEntityType(EKEntityType.Event)
                        
                        //                        self.loadCalendars()
                        //                        self.refreshTableView()
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        //                        self.needPermissionView.fadeIn()
                    })
                }
            })
            
        case EKAuthorizationStatus.Authorized:
            // Things are in line with being able to show the calendars in the table view
            //            loadCalendar()
            var calendars: [EKCalendar]?
            calendars = eventStore.calendarsForEntityType(EKEntityType.Event)
            
            print("authorized")
            var predicate = eventStore.predicateForRemindersInCalendars([])
            eventStore.fetchRemindersMatchingPredicate(predicate) { reminders in
                for reminder in reminders! {
                    print(reminder.title)
                }}
            
            var startDate=NSDate().dateByAddingTimeInterval(-60*60*24)
            var endDate=NSDate()//.dateByAddingTimeInterval(60*60*24*3)
            var predicate2 = eventStore.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: nil)
            
            print("startDate:\(startDate) endDate:\(endDate)")
            var eV = eventStore.eventsMatchingPredicate(predicate2) as [EKEvent]!
            
            if eV != nil {
                for i in eV {
                    print("Title  \(i.title)" )
                    print("startDate: \(i.startDate)" )
                    print("endDate: \(i.endDate)" )
                    
                    if i.title == "Test Title" {
                        print("YES" )
                        // Uncomment if you want to delete
                        //eventStore.removeEvent(i, span: EKSpanThisEvent, error: nil)
                    }
                }
            }
            
            
        case EKAuthorizationStatus.Restricted, EKAuthorizationStatus.Denied:
            // We need to help them give us permission
            print("deined")
        }
        return String(status)
    }
    
    
}
