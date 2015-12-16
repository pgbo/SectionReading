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

    class ReadingQueryOption: NSObject {
        var guid: String?
        var syncStatus: ReadingSyncStatus?
        var status: String?
    }
    
    
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
                    newReading!.fModifyTimestamp = Int(NSDate().timeIntervalSince1970)
                }
            }
        })
    }
    
    /**
     修改某条读书记录
     
     - parameter guid:        想要修改读书记录的 guid
     - parameter updateBlock: 修改记录的 Block
     */
    static func update(ReadingWithGuid guid: String, withUpdateBlock updateBlock: ((readingtoUpdate: TReading) -> Void)) {
        
        let mainDao = SECAppDelegate.SELF()?.mainDao
        if mainDao == nil {
            return
        }
        
        let fetchReq = NSFetchRequest(entityName: TReadingEntityName)
        fetchReq.predicate = NSPredicate(format: "(%K == %@)", "fGuid", guid)
        fetchReq.fetchLimit = 1
        
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

    
    private static func createFetchRequestPredicate(fromReadingQueryOption queryOption: ReadingQueryOption?) -> NSPredicate? {
        
        if queryOption == nil {
            return nil
        }
        
        var predicates: [NSPredicate] = []
        
        if queryOption!.guid != nil {
            predicates.append(NSPredicate(format: "(%K == %@)", "fGuid", queryOption!.guid!))
        }
        
        if queryOption!.syncStatus != nil {
            predicates.append(NSPredicate(format: "(%K == %@)", "fSyncStatus", NSNumber(integer: queryOption!.syncStatus!.rawValue)))
        }
        
        if queryOption!.status != nil {
            predicates.append(NSPredicate(format: "(%K == %@)", "fStatus", queryOption!.status!))
        }
        
        return NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: predicates)
    }
}
