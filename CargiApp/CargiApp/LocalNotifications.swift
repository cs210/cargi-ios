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
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge , .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        var localNotification:UILocalNotification = UILocalNotification()
        localNotification.fireDate = NSDate().dateByAddingTimeInterval(30.0)
        localNotification.alertBody = "hello";
        localNotification.alertAction = nil;
        localNotification.repeatInterval = NSCalendarUnit.Day
        
        //Add one to the icon badge number
        
        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1;
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    //        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
    }
}