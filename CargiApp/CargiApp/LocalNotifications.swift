//
//  LocalNotifications.swift
//  Cargi
//
//  Created by Maya Balakrishnan on 3/6/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import CoreBluetooth

class LocalNotifications {
    
    static func sendNotification() {
        let incrementAction = UIMutableUserNotificationAction()
        incrementAction.identifier = "INCREMENT_ACTION"
        incrementAction.title = "Add +1"
        incrementAction.activationMode = UIUserNotificationActivationMode.Background
        incrementAction.authenticationRequired = true
        incrementAction.destructive = false
        
        // decrement Action
        let decrementAction = UIMutableUserNotificationAction()
        decrementAction.identifier = "DECREMENT_ACTION"
        decrementAction.title = "Sub -1"
        decrementAction.activationMode = UIUserNotificationActivationMode.Background
        decrementAction.authenticationRequired = true
        decrementAction.destructive = false
        
        // reset Action
        let resetAction = UIMutableUserNotificationAction()
        resetAction.identifier = "RESET_ACTION"
        resetAction.title = "Reset"
        resetAction.activationMode = UIUserNotificationActivationMode.Foreground
        // NOT USED resetAction.authenticationRequired = true
        resetAction.destructive = true
        
        
        let counterCategory = UIMutableUserNotificationCategory()
        counterCategory.identifier = "COUNTER_CATEGORY"
        
        // A. Set actions for the default context
        counterCategory.setActions([incrementAction, decrementAction, resetAction],
            forContext: UIUserNotificationActionContext.Default)
        
        // B. Set actions for the minimal context
        counterCategory.setActions([incrementAction, decrementAction],
            forContext: UIUserNotificationActionContext.Minimal)
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge , .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        var localNotification:UILocalNotification = UILocalNotification()
        localNotification.fireDate = NSDate().dateByAddingTimeInterval(30.0)
        localNotification.alertBody = "hello";
        //        localNotification.alertAction = nil;
        localNotification.category = "COUNTER_CATEGORY"
        localNotification.repeatInterval = NSCalendarUnit.Day
        
        //Add one to the icon badge number
        
        //        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1;
        //
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        //            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        print("sent notification")
    }
}