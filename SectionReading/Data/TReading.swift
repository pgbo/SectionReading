//
//  TReading.swift
//  SectionReading
//
//  Created by guangbo on 15/12/15.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import Foundation
import CoreData

/**
 同步状态
 */
enum ReadingSyncStatus: Int {
    case Normal
    case NeedSyncUpload
    case NeedSyncDelete
    case SyncingUpload
}

let TReadingEntityName = "TReading"

@objc(TReading)
class TReading: NSManagedObject {
    
    /**
    新建读书记录
    
    - parameter constructBlock: 构建记录 Block
    */
    static func create(withConstructBlock constructBlock: ((newReading: TReading) -> Void)) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return
        }
        
        mainDao!.createNewOfManagedObjectClassName(TReadingEntityName, operate: { (managedObj) -> Void in
            
            let newReading = managedObj as? TReading
            if newReading != nil {
                
                constructBlock(newReading: newReading!)
                
                if newReading!.fModifyTimestamp == nil {
                    newReading!.fModifyTimestamp = NSNumber(int: Int32(NSDate().timeIntervalSince1970))
                }
            }
        })
    }
    
    /**
     修改读书记录
     
     - parameter filterOption: 过滤条件
     - parameter updateBlock:  修改 Block
     */
    static func update(withFilterOption filterOption: ReadingQueryOption, updateBlock: ((readingtoUpdate: TReading) -> Void)) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return
        }
        
        let fetchReq = NSFetchRequest(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: filterOption)
        
        mainDao!.filterObjectWithFetchRequest(fetchReq) { (results, error) -> Void in
            for reading in results {
                updateBlock(readingtoUpdate: (reading as! TReading))
            }
        }
    }
    
    /**
     删除记录
     
     - parameter option: 删除记录的查询条件
     */
    static func deleteByOption(option: ReadingQueryOption?) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return
        }
        
        let fetchReq = NSFetchRequest(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: option)
        
        mainDao!.delObjectWithFetchRequest(fetchReq)
    }
    
    /**
     查询记录
     
     - parameter option:     查询条件
     - parameter completion: 查询结果处理 Block
     */
    static func filterByOption(option: ReadingQueryOption?, completion: ((results: [TReading]?) -> Void)?) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            completion?(results: nil)
            return
        }
        
        let fetchReq = NSFetchRequest(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: option)
        
        mainDao!.filterObjectWithFetchRequest(fetchReq, handler: { (results, error) -> Void in
            
            completion?(results: (results as? [TReading]))
        })
    }
    
    /**
     查询数量
     
     - parameter option: 查询条件
     */
    static func count(withOption option: ReadingQueryOption?) -> Int? {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return nil
        }
        
        let fetchReq = NSFetchRequest(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: option)
        
        return mainDao!.countWithFetchRequest(fetchReq)
    }

    
    private static func createFetchRequestPredicate(fromReadingQueryOption queryOption: ReadingQueryOption?) -> NSPredicate? {
        
        if queryOption == nil {
            return nil
        }
        
        var predicates: [NSPredicate] = []
        
        if queryOption!.localId != nil {
            predicates.append(NSPredicate(format: "(%K == %@)", "fLocalId", queryOption!.localId!))
        }
        
        if queryOption!.evernoteGuid != nil {
            predicates.append(NSPredicate(format: "(%K == %@)", "fEvernoteGuid", queryOption!.evernoteGuid!))
        }
        
        if queryOption!.syncStatus != nil {
            var syncStatusPredicates: [NSPredicate] = []
            for syncStatus in queryOption!.syncStatus! {
                syncStatusPredicates.append(NSPredicate(format: "(%K == %@)", "fSyncStatus", NSNumber(integer: syncStatus.rawValue)))
            }
            if syncStatusPredicates.count > 0 {
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: syncStatusPredicates))
            }
        }
        
        if queryOption!.status != nil {
            predicates.append(NSPredicate(format: "(%K == %@)", "fStatus", queryOption!.status!))
        }
        
        if queryOption!.localAudioFilePath != nil {
            predicates.append(NSPredicate(format: "(%K == %@)", "fLocalAudioFilePath", queryOption!.localAudioFilePath!))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

class ReadingQueryOption: NSObject {
    var localId: String?
    var evernoteGuid: String?
    var syncStatus: [ReadingSyncStatus]?
    var status: String?
    var localAudioFilePath: String?
}
