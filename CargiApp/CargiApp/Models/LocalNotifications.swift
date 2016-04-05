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
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: NSSet(object: counterCategory) as? Set<UIUserNotificationCategory>)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        let notification = UILocalNotification()
        notification.alertBody = "Hey! Update your counter"
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.fireDate = NSDate()
        notification.category = "COUNTER_CATEGORY"
        notification.repeatInterval = NSCalendarUnit.Minute
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
         //Add one to the icon badge number
        
        //        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1;
        //            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        print("sent notification")
    }
    
    
}