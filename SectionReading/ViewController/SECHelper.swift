//
//  SECHelper.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECHelper: NSObject {

    static func globalCustomSetNavigationBar() {
        
        let navBarAppearance = UINavigationBar.appearance()
        
        navBarAppearance.setBackgroundImage(UIImage(named: "NavBar"), forBarMetrics: UIBarMetrics.Default)
        navBarAppearance.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(17), NSForegroundColorAttributeName: UIColor.blackColor()]
        
        navBarAppearance.tintColor = UIColor(red: 0x53/255.0, green: 0x9d/255.0, blue: 0x9f/255.0, alpha: 1)
    }
    
    static func globalCustomSetBarButtonItem() {
        
        let barButtonItemAppearance = UIBarButtonItem.appearance()
        
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14),NSForegroundColorAttributeName: UIColor(red: 0x53/255.0, green: 0x9d/255.0, blue: 0x9f/255.0, alpha: 1)], forState: UIControlState.Normal)
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14),NSForegroundColorAttributeName: UIColor(red: 0x4D/255.0, green: 0x83/255.0, blue: 0x84/255.0, alpha: 1)], forState: UIControlState.Highlighted)
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14),NSForegroundColorAttributeName: UIColor(red: 0xA0/255.0, green: 0xB0/255.0, blue: 0xB1/255.0, alpha: 1)], forState: UIControlState.Disabled)
    }
    
    static func createFormatTextForRecordDuration(duration: NSTimeInterval) -> String {
        let totalSeconds = Int(duration)
        
        let remaindPart = Int((duration - NSTimeInterval(totalSeconds))*10)
        let minutePart = totalSeconds/60
        let secondPart = totalSeconds - minutePart*60
        
        var formatTxt: String = ""
        
        // 拼接分钟
        if minutePart < 10 {
            formatTxt += "0\(minutePart)"
        } else {
            formatTxt += "\(minutePart)"
        }
        
        formatTxt += ":"
        
        // 拼接秒
        if secondPart < 10 {
            formatTxt += "0\(secondPart)"
        } else {
            formatTxt += "\(secondPart)"
        }
        
        formatTxt += "."
        
        // 拼接0.秒
        formatTxt += "\(remaindPart)"
        
        return formatTxt
    }
    
    /**
     读书录音存放目录
     
     - returns: 
     */
    static func readingRecordStoreDirectory() -> String? {
        
        let recordStorageDirPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first?.stringByAppendingString("/ReadingRecordAudio/")

        let fileMan = NSFileManager.defaultManager()

        var isDirectory: ObjCBool = ObjCBool(true)
        let existPath = fileMan.fileExistsAtPath(recordStorageDirPath!, isDirectory: &isDirectory)
        if existPath && isDirectory.boolValue == false {
            do {
                try fileMan.removeItemAtPath(recordStorageDirPath!)
            } catch let error as NSError {
                print("Fail to removeItemAtPath(\(recordStorageDirPath)), error: \(error.localizedDescription)")
                return nil
            }
        }
        
        // 创建目录
        do {
            try fileMan.createDirectoryAtPath(recordStorageDirPath!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Fail to removeItemAtPath(\(recordStorageDirPath)), error: \(error.localizedDescription)")
            return nil
        }
        
        return recordStorageDirPath
    }
}
