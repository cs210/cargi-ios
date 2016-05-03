//
//  AppDelegate.swift
//  CargiApp
//
//  Created by Edwin Park on 2/25/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var client: MSClient?
    var window: UIWindow?
    lazy var db = AzureDatabase.sharedInstance

    var startTime: NSDate?
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyBtm9mqbycBZedKCLWgxWU-aPbZDwO0jII")
        UIApplication.sharedApplication().idleTimerDisabled = true
        self.client = MSClient(
              applicationURLString:"https://cargi.azurewebsites.net"
        )
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var initialViewController = storyboard.instantiateViewControllerWithIdentifier("LaunchScreenVC")
        let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey("notFirstLaunchV2.0")
        let loggedIn = NSUserDefaults.standardUserDefaults().boolForKey("loggedIn")

        if launchedBefore {
            print("Not first launch.")
            if loggedIn {
                let deviceID = UIDevice.currentDevice().identifierForVendor!.UUIDString
                db.initializeUserIDWithDeviceID(deviceID) { (status, success) in
                    if success {
                        print("userID initialized: ", self.db.userID)
                        //
                        self.window?.rootViewController = storyboard.instantiateViewControllerWithIdentifier("MainScreenVC")
                    }
                }
                print("you're logged in")
                // TODO: direct to home screen

            } else {
                // TODO: direct to login page
                print("you're not logged in")
                initialViewController = storyboard.instantiateViewControllerWithIdentifier("LoginScreenVC")
                self.window?.rootViewController = initialViewController
            }
        } else {
            print("First launch, setting NSUserDefault.")
            
            // direct to Tutorial Screen?
            initialViewController = storyboard.instantiateViewControllerWithIdentifier("TutorialScreenVC")
        }
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("entering background", NSDate())
        db.backgroundTaskIdentifier =
            UIApplication.sharedApplication().beginBackgroundTaskWithName(
                "log",
                expirationHandler: {
                    print("Background task is expired now")
            })
        db.logUsage(startTime)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if db.backgroundTaskIdentifier != UIBackgroundTaskInvalid{
            print("We need to invalidate our background task")
            UIApplication.sharedApplication().endBackgroundTask(
                db.backgroundTaskIdentifier)
            db.backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
     
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("entering foreground", NSDate())
        startTime = NSDate()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
 



}

