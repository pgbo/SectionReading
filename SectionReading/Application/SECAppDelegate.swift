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
    
    var onlySyncNoteUnderWIFI: Bool = true {
        didSet {
            UserDefaults.standard.set(NSNumber(value: onlySyncNoteUnderWIFI as Bool), forKey: kUserDefault_OnlySyncNoteUnderWIFI)
            evernoteManager?.onlySyncUnderWIFI = onlySyncNoteUnderWIFI
        }
    }
    
    fileprivate (set) var evernoteManager: SECEvernoteManager!
    
    fileprivate (set) var mainDao: LvMultiThreadCoreDataDao!

    static func SELF() -> SECAppDelegate? {
        return (UIApplication.shared.delegate as? SECAppDelegate)
    }
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame:UIScreen.main.bounds)
        
        let nav = UINavigationController(rootViewController: SECReadingHistoryViewController.instanceFromSB())
        
        window!.rootViewController = nav
        
        window!.makeKeyAndVisible()
        
        
        // Global settings
        
        SECHelper.globalCustomSetNavigationBar()
        SECHelper.globalCustomSetBarButtonItem()
        SECHelper.globalCustomSetTextView()
        
        // Initial evernote sdk
        
        ENSession.setSharedSessionConsumerKey(CONSUMER_KEY, consumerSecret: CONSUMER_SECRET, optionalHost: ENDPOINT_HOST)
        
        // set up onlySyncNoteUnderWIFI
        
        let onlySyncNoteUnderWIFI = UserDefaults.standard.object(forKey: kUserDefault_OnlySyncNoteUnderWIFI) as? NSNumber
        if onlySyncNoteUnderWIFI == nil {
            self.onlySyncNoteUnderWIFI = OnlySyncNoteUnderWiFiDefaultValue
        } else {
            self.onlySyncNoteUnderWIFI = onlySyncNoteUnderWIFI!.boolValue
        }
        
        // setup evernoteManager
        
        evernoteManager = SECEvernoteManager()
        evernoteManager.onlySyncUnderWIFI = self.onlySyncNoteUnderWIFI

        
        // setup mainDao
        
        mainDao = LvMultiThreadCoreDataDao()
        mainDao!.setupEnvModel("MainModel", dbFile: "MainDB.sqlite")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: SSAReachabilityDidChangeNotification), object: nil, queue: nil) { [weak self] (note) -> Void in
            if let strongSelf = self {
                let isReachableViaWiFi = SSASwiftReachability.sharedManager != nil && SSASwiftReachability.sharedManager!.isReachableViaWiFi()
                let isReachable = SSASwiftReachability.sharedManager != nil && SSASwiftReachability.sharedManager!.isReachable()
                strongSelf.evernoteManager?.WiFiReachability = isReachableViaWiFi
                if isReachable {
                    strongSelf.evernoteManager?.sync(withType: EvernoteSyncType.up_AND_DOWN, completion: { (successNumber) -> Void in
                        print("Evermanager sync number: \(successNumber)")
                    })
                }
            }
        }
        
        SSASwiftReachability.sharedManager?.reachabilityInformationMode = .advanced
        SSASwiftReachability.sharedManager?.startMonitoring()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        mainDao.saveToStorageFile()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        mainDao.saveToStorageFile()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        let didHandle = ENSession.shared.handleOpenURL(url)
        return didHandle
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        let didHandle = ENSession.shared.handleOpenURL(url)
        return didHandle
    }
}

