//
//  SECHelper.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECHelper: NSObject {

    private static var __once: () = {
            DefaultCalendar.defaultClendar = Calendar(identifier: Calendar.Identifier.gregorian)
        }()

    /**
     全局设置导航栏
     */
    static func globalCustomSetNavigationBar() {
        
        let navBarAppearance = UINavigationBar.appearance()
        
        navBarAppearance.setBackgroundImage(UIImage(named: "NavBar"), for: UIBarMetrics.default)
        navBarAppearance.titleTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 17), NSForegroundColorAttributeName: UIColor.black]
        
        navBarAppearance.tintColor = UIColor(red: 0x53/255.0, green: 0x9d/255.0, blue: 0x9f/255.0, alpha: 1)
    }
    
    /**
     全局设置 Bar button item
     */
    static func globalCustomSetBarButtonItem() {
        
        let barButtonItemAppearance = UIBarButtonItem.appearance()
        
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor(red: 0x53/255.0, green: 0x9d/255.0, blue: 0x9f/255.0, alpha: 1)], for: UIControlState())
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor(red: 0x4D/255.0, green: 0x83/255.0, blue: 0x84/255.0, alpha: 1)], for: UIControlState.highlighted)
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor(red: 0xA0/255.0, green: 0xB0/255.0, blue: 0xB1/255.0, alpha: 1)], for: UIControlState.disabled)
    }
    
    /**
     全局设置 TextView
     */
    static func globalCustomSetTextView() {
        UITextView.appearance().tintColor = UIColor(red: 0x53/255.0, green: 0x9d/255.0, blue: 0x9f/255.0, alpha: 1)
    }
    
    /**
     创建格式化的时长
     
     - parameter duration: 时长
     
     - returns: 
     */
    static func createFormatTextForRecordDuration(_ duration: TimeInterval) -> String {
        
        let totalSeconds = Int(duration)
        
        let remaindPart = Int((duration - TimeInterval(totalSeconds))*10)
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
        
        let recordStorageDirPath = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first)! + "/ReadingRecordAudio/"

        let fileMan = FileManager.default

        var isDirectory: ObjCBool = ObjCBool(true)
        let existPath = fileMan.fileExists(atPath: recordStorageDirPath, isDirectory: &isDirectory)
        if existPath && isDirectory.boolValue == false {
            do {
                try fileMan.removeItem(atPath: recordStorageDirPath)
            } catch let error as NSError {
                print("Fail to removeItemAtPath(\(recordStorageDirPath)), error: \(error.localizedDescription)")
                return nil
            }
        }
        
        // 创建目录
        do {
            try fileMan.createDirectory(atPath: recordStorageDirPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Fail to removeItemAtPath(\(recordStorageDirPath)), error: \(error.localizedDescription)")
            return nil
        }
        
        return recordStorageDirPath
    }
    
    fileprivate struct DefaultCalendar {
        static var once_token: Int = 0
        static var defaultClendar: Calendar?
    }
    
    static func defaultCalendar() -> Calendar {
        
        _ = SECHelper.__once
        
        return DefaultCalendar.defaultClendar!
    }
}
