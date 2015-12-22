//
//  SECAppDelegate.swift
//  SectionReading
//
//  Created by 彭光波 on 15/9/16.
//  Copyright (c) 2015年 pengguangbo. All rights reserved.
//

import UIKit
import evernote_cloud_sdk_ios

let ENDPOINT_HOST = ENSessionHostSandbox
let CONSUMER_KEY = "guangbool"
let CONSUMER_SECRET = "035fdd283de30a69"

@UIApplicationMain
class SECAppDelegate: UIResponder, UIApplicationDelegate, UINavigationBarDelegate {

    var window: UIWindow?
    
    private (set) var evernoteManager: SECEvernoteManager!
    
    private (set) var mainDao: LvMultiThreadCoreDataDao!

    static func SELF() -> SECAppDelegate? {
        return (UIApplication.sharedApplication().delegate as? SECAppDelegate)
    }
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        window = UIWindow(frame:UIScreen.mainScreen().bounds)
        
        let nav = UINavigationController(rootViewController: SECReadingHistoryViewController.instanceFromSB())
        
        window!.rootViewController = nav
        
        window!.makeKeyAndVisible()
        
        
        // Global settings
        
        SECHelper.globalCustomSetNavigationBar()
        SECHelper.globalCustomSetBarButtonItem()
        SECHelper.globalCustomSetTextView()
        
        // Initial evernote sdk
        
        ENSession.setSharedSessionConsumerKey(CONSUMER_KEY, consumerSecret: CONSUMER_SECRET, optionalHost: ENDPOINT_HOST)
        
        // setup evernoteManager
        
        evernoteManager = SECEvernoteManager()
        
        
        // setup mainDao
        
        mainDao = LvMultiThreadCoreDataDao()
        mainDao!.setupEnvModel("MainModel", dbFile: "MainDB.sqlite")
        
        SSASwiftReachability.sharedManager?.startMonitoring()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        mainDao.saveToStorageFile()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        
        mainDao.saveToStorageFile()
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        
        let didHandle = ENSession.sharedSession().handleOpenURL(url)
        return didHandle
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        let didHandle = ENSession.sharedSession().handleOpenURL(url)
        return didHandle
    }
}

