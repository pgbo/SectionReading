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
    case normal
    case needSyncUpload
    case needSyncDelete
    case syncingUpload
}

let TReadingEntityName = "TReading"

@objc(TReading)
class TReading: NSManagedObject {
    
    /**
    新建读书记录
    
    - parameter constructBlock: 构建记录 Block
    */
    static func create(withConstructBlock constructBlock: ((_ newReading: TReading) -> Void)?) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return
        }
        
        mainDao!.createNew(ofManagedObjectClassName: TReadingEntityName, operate: { (managedObj) -> Void in
            
            let newReading = managedObj as? TReading
            if newReading != nil {
                
                constructBlock?(newReading!)
                
                if newReading!.fModifyTimestamp == nil {
                    newReading!.fModifyTimestamp = NSNumber(value: Int32(Date().timeIntervalSince1970) as Int32)
                }
            }
        })
    }
    
    /**
     修改读书记录
     
     - parameter filterOption: 过滤条件
     - parameter updateBlock:  修改 Block
     */
    static func update(withFilterOption filterOption: ReadingQueryOption, updateBlock: ((_ readingtoUpdate: TReading) -> Void)?) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return
        }
        
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: filterOption)
        
        mainDao!.filterObject(with: fetchReq) { (results, error) -> Void in
            if results?.count == 0 {
                return
            }
            for reading in results! {
                updateBlock?((reading as! TReading))
            }
        }
    }
    
    /**
     删除记录
     
     - parameter option: 删除记录的查询条件
     */
    static func deleteByOption(_ option: ReadingQueryOption?) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return
        }
        
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: option)
        
        mainDao!.delObject(with: fetchReq)
    }
    
    /**
     查询记录
     
     - parameter option:     查询条件
     - parameter completion: 查询结果处理 Block
     */
    static func filterByOption(_ option: ReadingQueryOption?, completion: ((_ results: [TReading]?) -> Void)?) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            completion?(nil)
            return
        }
        
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: option)
        
        mainDao!.filterObject(with: fetchReq, handler: { (results, error) -> Void in
            
            completion?((results as? [TReading]))
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
        
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: TReadingEntityName)
        fetchReq.predicate = createFetchRequestPredicate(fromReadingQueryOption: option)
        
        return mainDao!.count(with: fetchReq)
    }

    
    fileprivate static func createFetchRequestPredicate(fromReadingQueryOption queryOption: ReadingQueryOption?) -> NSPredicate? {
        
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
                syncStatusPredicates.append(NSPredicate(format: "(%K == %@)", "fSyncStatus", NSNumber(value: syncStatus.rawValue as Int)))
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
