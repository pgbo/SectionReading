//
//  SECEvernoteManager.swift
//  SectionReading
//
//  Created by guangbo on 15/12/15.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import evernote_cloud_sdk_ios

/**
 印象笔记同步错误
 */
enum EvernoteSyncError: Error {
    case noError
    case evernoteNotAuthenticated
    case failToListNotebooks
    case failToCreateNotebook
}

enum EvernoteSyncType: UInt {
    case up
    case down
    case up_AND_DOWN
}

/// 同步上传状态变化的通知
let SECEvernoteManagerSycnUpStateDidChangeNotification = "SECEvernoteManagerSycnUpStateDidChangeNotification"
/// 同步上传的状态
let SECEvernoteManagerNotificationSycnUpStateItem = "SECEvernoteManagerNotificationSycnUpStateItem"
/// 同步上传成功的数量
let SECEvernoteManagerNotificationSuccessSycnUpNoteCountItem = "SECEvernoteManagerNotificationSuccessSycnUpNoteCountItem"

/// 同步下载状态变化的通知
let SECEvernoteManagerSycnDownStateDidChangeNotification = "SECEvernoteManagerSycnDownStateDidChangeNotification"
/// 同步下载的状态
let SECEvernoteManagerNotificationSycnDownStateItem = "SECEvernoteManagerNotificationSycnDownStateItem"
/// 同步下载成功的数量
let SECEvernoteManagerNotificationSuccessSycnDownNoteCountItem = "SECEvernoteManagerNotificationSuccessSycnDownNoteCountItem"

let ApplicationNotebookName = "SectionReading"
let kApplicationNotebookGuid = "kApplicationNotebookGuid"
let kEvernoteLastUpdateCount = "kEvernoteLastUpdateCount"

class SECEvernoteManager: NSObject {

    /// 是否连接 wifi
    var WiFiReachability: Bool = false
    
    /// 是否只在 wifi 下同步
    var onlySyncUnderWIFI: Bool = true 
    
    // 是否正在同步上传
    fileprivate (set) var upSynchronizing = false
    
    // 上次同步上传数量
    fileprivate (set) var lastTimeSyncupNoteNumber: Int = 0
    
    // 是否正在同步下载
    fileprivate (set) var downSynchronizing = false
    
    // 上次同步下载数量
    fileprivate (set) var lastTimeSyncdownNoteNumber: Int = 0
    
    fileprivate var noteSession = ENSession.shared
    fileprivate var needSyncDownNoteCount: NSNumber?
    
    fileprivate lazy var noteSycnOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    /**
     印象笔记是否授权
     
     - returns:
     */
    func isAuthenticated() -> Bool {

        return noteSession.isAuthenticated
    }
    
    /**
     印象笔记授权
     
     - parameter viewController:
     - parameter completion:
     */
    func authenticate(withViewController viewController: UIViewController, completion:((_ success: Bool) -> Void)?) {
        
        noteSession.authenticate(with: viewController, preferRegistration: false) { [weak self] (error) -> Void in
            if let strongSelf = self {
                if error == nil {
                    // 设置笔记本
                    strongSelf.setupApplicationNotebook(withCompletion: { (result) -> Void in
                        DispatchQueue.main.async {
                            completion?(result == EvernoteSyncError.noError)
                        }
                    })
                } else {
                    completion?(false)
                }
            }
        }
    }
    
    /**
     印象笔记解除授权
     */
    func unauthenticate() {
        
        noteSycnOperationQueue.cancelAllOperations()
        
        upSynchronizing = false
        lastTimeSyncupNoteNumber = 0
        downSynchronizing = false
        lastTimeSyncdownNoteNumber = 0
        needSyncDownNoteCount = nil
        
        noteSession.unauthenticate()
    }
    
    /**
     创建新的笔记
     
     - parameter content:    笔记内容
     - parameter completion: 回调 block
     */
    func createNote(withContent content: TReading, completion: ((EDAMNote?) -> Void)?) {
        
        if isAuthenticated() == false {
            completion?(nil)
            return
        }
        
        // 先设置笔记本
        self.setupApplicationNotebook { [weak self] (err) in
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            if err != .noError {
                completion?(nil)
                return
            }
            
            let appNotebookGuid = UserDefaults.standard.object(forKey: kApplicationNotebookGuid) as? String
            if appNotebookGuid == nil {
                completion?(nil)
                return
            }
            
            let note = EDAMNote()
            TReading.fillFieldsFor(note, withReading: content, onlyFillUnSettedFields: true)
            
            note.notebookGuid = appNotebookGuid!
            note.title = "读书记录"
            
            strongSelf!.noteSession.primaryNoteStore()?.create(note, completion: { (createdNote, error) in
                if error != nil {
                    print("Fail to createNote, error: \(error!.localizedDescription)")
                    completion?(nil)
                } else {
                    completion?(createdNote)
                }
            })
        }
    }
    
    /**
     更新笔记
     
     - parameter guid:       笔记 guid
     - parameter newContent: 新的笔记内容
     - parameter completion: 回调 block
     */
    func updateNote(withGuid guid: String, newContent: TReading, completion: ((EDAMNote?) -> Void)?) {
        
        
        if isAuthenticated() == false {
            completion?(nil)
            return
        }
        
        let appNotebookGuid = UserDefaults.standard.object(forKey: kApplicationNotebookGuid) as? String
        if appNotebookGuid == nil {
            completion?(nil)
            return
        }
        
        let note = EDAMNote()
        TReading.fillFieldsFor(note, withReading: newContent, onlyFillUnSettedFields: true)
        
        note.guid = guid
        note.title = ""
        note.notebookGuid = appNotebookGuid!
        
        noteSession.primaryNoteStore()?.update(note, completion: { (updatedNote, error) in
            if error != nil {
                print("Fail to createNote, error: \(error!.localizedDescription)")
                completion?(nil)
            } else {
                completion?(updatedNote)
            }
        })
    }
    
    /**
     删除笔记
     
     - parameter guid:       笔记 guid
     - parameter completion: 回调 block
     */
    func deleteNote(withGuid guid: String, completion: ((_ success: Bool) -> Void)?) {
        
        if isAuthenticated() == false {
            completion?(false)
            return
        }
        
        noteSession.primaryNoteStore()?.deleteNote(withGuid: guid, completion: { (successNum, error) in
            if error != nil {
                print("Fail to createNote, error: \(error!.localizedDescription)")
                completion?(false)
            } else {
                completion?(true)
            }
        })
    }
    
    
    /**
     与印象笔记同步笔记
     
     - parameter withTypeMask:      同步类型
     - parameter completion:        同步成功数量
     */
    func sync(withType type: EvernoteSyncType, completion: ((_ successNumber: Int) -> Void)?) {
        
        if isAuthenticated() == false {
            completion?(0)
            return
        }
        
        switch type {
        case .up :
            syncUp(withCompletion: { (upNumber) -> Void in
                completion?(upNumber)
            })
        case .down :
            syncDown(withCompletion: { (downNumber) -> Void in
                completion?(downNumber)
            })
        case .up_AND_DOWN :
            syncDown(withCompletion: { [weak self] (downNumber) -> Void in
                let strongSelf = self
                if strongSelf == nil {
                    return
                }
                
                var syncNumber = downNumber
                strongSelf!.syncUp(withCompletion: { (upNumber) -> Void in
                    syncNumber += upNumber
                    completion?(syncNumber)
                })
            })
        }
    }
    
    /**
     获取需要下载的笔记数量
     
     - parameter success: 成功 block
     - parameter failure: 失败 block
     */
    func getNeedSyncDownNoteCount(withSuccess success: ((Int) -> Void)?, failure: (() -> Void)?) {
        
        
        if isAuthenticated() == false {
            failure?()
            return
        }
        
        if needSyncDownNoteCount != nil {
            success?(needSyncDownNoteCount!.intValue)
            return
        }
        
        
        let resultSpec = EDAMNotesMetadataResultSpec()
        resultSpec.includeUpdated = true
        
        getApplicationAllNotesMetadata(withNotesMetadataResultSpec: resultSpec, success: { [weak self] (notesMetadata) -> Void in
            
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            if notesMetadata == nil {
                strongSelf?.needSyncDownNoteCount = NSNumber(value: 0)
                success?(0)
                return
            }
            
            strongSelf!.noteSycnOperationQueue.addOperation({ () -> Void in
              
                var needSycnDownNumber = 0
                let dispatchGroup = DispatchGroup()
                
                for noteMeta in notesMetadata! {
                    
                    let queryOption = ReadingQueryOption()
                    queryOption.evernoteGuid = noteMeta.guid
                    
                    dispatchGroup.enter()
                    TReading.filterByOption(queryOption, completion: { (results) -> Void in
                        if results == nil || results!.count == 0 {
                            for result in results! {
                                if result.fModifyTimestamp != nil
                                    && result.fModifyTimestamp!.intValue != (noteMeta.updated.intValue/1000) {
                                    
                                    needSycnDownNumber += 1
                                    break
                                }
                            }
                        } else {
                            needSycnDownNumber += 1
                        }
                        dispatchGroup.leave()
                    })
                    dispatchGroup.wait(timeout: DispatchTime.distantFuture)
                }
                
                strongSelf?.needSyncDownNoteCount = NSNumber(value: needSycnDownNumber)
                success?(needSycnDownNumber)
            })
            
        }) { [weak self] in
            if let strongSelf = self {
                strongSelf.needSyncDownNoteCount = NSNumber(value: 0)
                failure?()
            }
        }
    }
    
    /**
     获取资源
     
     - parameter resourceGuid: 资源 id
     - parameter completion:   结果 block
     */
    func getResource(withResourceGuid resourceGuid: String, completion: ((Data?) -> Void)?) {
    
        
        if isAuthenticated() == false {
            completion?(nil)
            return
        }
        
        self.noteSession.primaryNoteStore()?.fetchResourceData(withGuid: resourceGuid, completion: { (data, error) in
            if error != nil {
                print("error: \(error!.localizedDescription)")
                completion?(nil)
            } else {
                completion?(data)
            }
        })
    }
    
    fileprivate func getApplicationAllNotesMetadata(withNotesMetadataResultSpec notesMetadataResultSpec: EDAMNotesMetadataResultSpec, success: (([EDAMNoteMetadata]?) -> Void)?, failure: (() -> Void)?) {
        
        
        if isAuthenticated() == false {
            failure?()
            return
        }
        
        let appNotebookGuid = UserDefaults.standard.object(forKey: kApplicationNotebookGuid) as? String
        if appNotebookGuid == nil {
            failure?()
            return
        }
        
        self.noteSycnOperationQueue.addOperation { [weak self] () -> Void in
            
            var strongSelf = self
            if strongSelf == nil {
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            // 获取笔记数量
            
            var noteCount: NSNumber?
            var findNoteCountsSuccess = false
            let filter = EDAMNoteFilter()
            filter.notebookGuid = appNotebookGuid
            
            dispatchGroup.enter()
            strongSelf!.noteSession.primaryNoteStore()?.findNoteCounts(with: filter, includingTrash: false, completion: { (noteCollectionCounts, error) in
                if error != nil {
                    print("Fail to findNoteCounts, error: \(error!.localizedDescription)")
                    dispatchGroup.leave()
                } else {
                    noteCount = noteCollectionCounts!.notebookCounts.values.first
                    findNoteCountsSuccess = true
                    dispatchGroup.leave()
                }
            })
            var waitResult = dispatchGroup.wait(timeout: DispatchTime.distantFuture)
            if waitResult == DispatchTimeoutResult.timedOut {
                failure?()
                return
            }
            
            if findNoteCountsSuccess == false {
                failure?()
                return
            }
            
            if noteCount == nil || noteCount!.intValue == 0 {
                success?(nil)
                return
            }
            
            strongSelf = self
            if strongSelf == nil {
                return
            }
            
            // 开始查询应用笔记本下的所有笔记 metadata
            
            var noteMetas: [EDAMNoteMetadata]?
            var findNotesMetadataSuccess = false
            
            dispatchGroup.enter()
            strongSelf!.noteSession.primaryNoteStore()?.findNotesMetadata(with: filter, maxResults: noteCount!.uintValue, resultSpec: notesMetadataResultSpec, success: { (results) -> Void in
                
                noteMetas = results
                findNotesMetadataSuccess = true
                
                dispatchGroup.leave()
                
                }, failure: { (error) -> Void in
                    print("Fail to findNotesMetadata, error: \(error?.localizedDescription)")
                    dispatchGroup.leave()
            })
            waitResult = dispatchGroup.wait(timeout: DispatchTime.distantFuture)
            if waitResult == DispatchTimeoutResult.timedOut {
                failure?()
                return
            }
            
            if findNotesMetadataSuccess == false {
                failure?()
                return
            }
            
            success?(noteMetas)
        }
    }
    
    /**
     设置好本应用的笔记本
     */
    fileprivate func setupApplicationNotebook(withCompletion completion: ((_ result: EvernoteSyncError) -> Void)?) {
        
        
        if isAuthenticated() == false {
            completion?(EvernoteSyncError.evernoteNotAuthenticated)
            return
        }
        
        let notebookGuid = UserDefaults.standard.object(forKey: kApplicationNotebookGuid) as? String
        if notebookGuid != nil {
            noteSession.primaryNoteStore()?.fetchNotebook(withGuid: notebookGuid!, completion: { [weak self] (notebook, error) in
                if error != nil {
                    print("Fail to getNotebook, error: \(error!.localizedDescription)")
                    if let strongSelf = self {
                        strongSelf.createApplicationNotebook(withCompletion: completion)
                    }
                } else {
                    if let strongSelf = self {
                        if notebook!.name != ApplicationNotebookName {
                            strongSelf.createApplicationNotebook(withCompletion: completion)
                            return
                        }
                        completion?(EvernoteSyncError.noError)
                    }
                }
            })
        } else {
            noteSession.primaryNoteStore()?.listNotebooks(completion: { [weak self] (books, error) in
                if error != nil {
                    print("Fail to listNotebooks, error: \(error!.localizedDescription)")
                    completion?(EvernoteSyncError.failToListNotebooks)
                } else {
                    if let strongSelf = self {
                        var targetNotebook: EDAMNotebook?
                        for notebook in books! {
                            if notebook.name == ApplicationNotebookName {
                                targetNotebook = notebook
                                break
                            }
                        }
                        if targetNotebook != nil {
                            UserDefaults.standard.set(targetNotebook!.guid, forKey: kApplicationNotebookGuid)
                            completion?(EvernoteSyncError.noError)
                            return
                        }
                        
                        strongSelf.createApplicationNotebook(withCompletion: completion)
                    }
                }
            })
        }
    }
    
    fileprivate func createApplicationNotebook(withCompletion completion: ((_ result: EvernoteSyncError) -> Void)?) {
    
        if isAuthenticated() == false {
            completion?(EvernoteSyncError.evernoteNotAuthenticated)
            return
        }
        
        let notebook = EDAMNotebook()
        notebook.name = ApplicationNotebookName
        notebook.defaultNotebook = NSNumber(value: false)
        noteSession.primaryNoteStore()?.create(notebook, completion: { (notebook, error) in
            if error != nil {
                print("Fail to createNotebook, error: \(error!.localizedDescription)")
                completion?(EvernoteSyncError.failToCreateNotebook)
            } else {
                print("Success to createNotebook, guid: \(notebook!.guid), name: \(notebook!.name)")
                
                UserDefaults.standard.set(notebook!.guid, forKey: kApplicationNotebookGuid)
                completion?(EvernoteSyncError.noError)
            }
        })
    }
    
    
    fileprivate func canSyncronize() -> Bool {
        
        if onlySyncUnderWIFI {
            return WiFiReachability
        }
        return true
    }
    
    fileprivate func notifyNoteSyncupStateDidChange() {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: SECEvernoteManagerSycnUpStateDidChangeNotification), object: self, userInfo: [SECEvernoteManagerNotificationSycnUpStateItem: upSynchronizing, SECEvernoteManagerNotificationSuccessSycnUpNoteCountItem: lastTimeSyncupNoteNumber])
    }
    
    fileprivate func notifyNoteSyncdownStateDidChange() {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: SECEvernoteManagerSycnDownStateDidChangeNotification), object: self, userInfo: [SECEvernoteManagerNotificationSycnDownStateItem: downSynchronizing, SECEvernoteManagerNotificationSuccessSycnDownNoteCountItem: lastTimeSyncdownNoteNumber])
    }
    
    fileprivate func syncUp(withCompletion completion: ((Int) -> Void)?) {
        
        if isAuthenticated() == false {
            completion?(0)
            return
        }
        
        self.noteSycnOperationQueue.addOperation { [weak self] () -> Void in
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            if strongSelf!.upSynchronizing {
                print("Up synchrosizing.")
                completion?(0)
                return
            }
            
            if strongSelf!.canSyncronize() == false {
                print("Can't synchronize.")
                completion?(0)
                return
            }
            
            strongSelf!.upSynchronizing = true
            strongSelf!.notifyNoteSyncupStateDidChange()
            
            let queryOption = ReadingQueryOption()
            queryOption.syncStatus = [.needSyncUpload, .needSyncDelete]
            TReading.filterByOption(queryOption) { [weak self] (results) -> Void in
                
                let strongSelf = self
                if strongSelf == nil {
                    return
                }
                if results == nil {
                    strongSelf?.upSynchronizing = false
                    strongSelf?.lastTimeSyncupNoteNumber = 0
                    strongSelf?.notifyNoteSyncupStateDidChange()
                    completion?(0)
                    return
                }
                
                var successNumber = 0
                var dispatchGroup = DispatchGroup()
                
                for reading in results! {
                    
                    let syncStatus = reading.fSyncStatus
                    if syncStatus == nil {
                        continue
                    }
                    
                    if syncStatus!.intValue == ReadingSyncStatus.needSyncUpload.rawValue {
                        
                        if reading.fEvernoteGuid == nil {
                            // create
                            dispatchGroup.enter()
                            strongSelf?.createNote(withContent: reading, completion: { (createdNote) -> Void in
                                if createdNote != nil {
                                    // 更新本地数据
                                    let filterOption = ReadingQueryOption()
                                    filterOption.localId = reading.fLocalId!
                                    
                                    TReading.update(withFilterOption: filterOption, updateBlock: { (readingtoUpdate) -> Void in
                                        
                                        readingtoUpdate.fillFields(fromEverNote: createdNote!, onlyFillUnSettedFields: true)
                                        readingtoUpdate.fSyncStatus = NSNumber(value: ReadingSyncStatus.normal.rawValue)
                                    })
                                    
                                    successNumber += 1
                                }
                                dispatchGroup.leave()
                            })
                            dispatchGroup.wait(timeout: DispatchTime.distantFuture)
                        } else {
                            // update
                            dispatchGroup.enter()
                            strongSelf?.updateNote(withGuid: reading.fEvernoteGuid!, newContent: reading, completion: { (updatedNote) -> Void in
                                if updatedNote != nil {
                                    // 更新本地数据
                                    let filterOption = ReadingQueryOption()
                                    filterOption.evernoteGuid = reading.fEvernoteGuid!
                                    
                                    TReading.update(withFilterOption: filterOption, updateBlock: { (readingtoUpdate) -> Void in
                                        
                                        readingtoUpdate.fillFields(fromEverNote: updatedNote!, onlyFillUnSettedFields: false)
                                        readingtoUpdate.fSyncStatus = NSNumber(value: ReadingSyncStatus.normal.rawValue)
                                    })
                                    
                                    successNumber += 1
                                }
                                dispatchGroup.leave()
                            })
                            dispatchGroup.wait(timeout: DispatchTime.distantFuture)
                        }
                        
                    } else if syncStatus!.intValue == ReadingSyncStatus.needSyncDelete.rawValue {
                        
                        if reading.fEvernoteGuid == nil {
                            continue
                        }
                        
                        // delete
                        dispatchGroup.enter()
                        strongSelf?.deleteNote(withGuid: reading.fEvernoteGuid!, completion: { (success) -> Void in
                            if success {
                                // 删除本地数据
                                let filterOption = ReadingQueryOption()
                                filterOption.evernoteGuid = reading.fEvernoteGuid!
                                
                                TReading.deleteByOption(filterOption)
                                
                                successNumber += 1
                            }
                            dispatchGroup.leave()
                        })
                        dispatchGroup.wait(timeout: DispatchTime.distantFuture)
                    }
                }
                
                strongSelf?.upSynchronizing = false
                strongSelf?.lastTimeSyncupNoteNumber = successNumber
                strongSelf?.notifyNoteSyncupStateDidChange()
                
                completion?(successNumber)
            }
        }
    }
    
    fileprivate func syncDown(withCompletion completion: ((Int) -> Void)?) {
        
        if isAuthenticated() == false {
            completion?(0)
            return
        }
        
        if downSynchronizing {
            print("Down synchronizing.")
            completion?(0)
            return
        }
        
        if canSyncronize() == false {
            print("Can't synchronize.")
            completion?(0)
            return
        }
        
        downSynchronizing = true
        notifyNoteSyncdownStateDidChange()
        
        let resultSpec = EDAMNotesMetadataResultSpec()
        resultSpec.includeUpdated = true
        
        getApplicationAllNotesMetadata(withNotesMetadataResultSpec: resultSpec, success: { [weak self] (notesMetadata) -> Void in
        
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            if notesMetadata == nil {
                strongSelf?.downSynchronizing = false
                strongSelf?.lastTimeSyncdownNoteNumber = 0
                strongSelf?.notifyNoteSyncdownStateDidChange()
                strongSelf?.needSyncDownNoteCount = NSNumber(value: 0)
                completion?(0)
                return
            }
            
            strongSelf!.noteSycnOperationQueue.addOperation { [weak self] () -> Void in
                
                var strongSelf = self
                if strongSelf == nil {
                    return
                }
                
                let dispatchGroup = DispatchGroup()
                
                // 考虑是否需要向下同步
                
                let latestUpdateCount = UserDefaults.standard.integer(forKey: kEvernoteLastUpdateCount)
                var currentUpdateCount = 0
                
                dispatchGroup.enter()
                strongSelf!.noteSession.primaryNoteStore()?.fetchSyncState(completion: { (syncState, error) in
                    if error != nil {
                        print("Fail to getSyncState, error: \(error!.localizedDescription)")
                        dispatchGroup.leave()
                    } else {
                        currentUpdateCount = syncState!.updateCount.intValue
                        dispatchGroup.leave()
                    }
                })
                dispatchGroup.wait(timeout: DispatchTime.distantFuture)
                
                if currentUpdateCount <= latestUpdateCount {
                    strongSelf?.downSynchronizing = false
                    strongSelf?.lastTimeSyncdownNoteNumber = 0
                    strongSelf?.notifyNoteSyncdownStateDidChange()
                    strongSelf?.needSyncDownNoteCount = NSNumber(value: 0)
                    completion?(0)
                    return
                }
                
                strongSelf = self
                if strongSelf == nil {
                    return
                }
                
                var syncDownNumber = 0
                
                for noteMeta in notesMetadata! {
                    
                    var needCreate = false
                    var needUpdate = false
                    
                    let queryOption = ReadingQueryOption()
                    queryOption.evernoteGuid = noteMeta.guid
                    
                    dispatchGroup.enter()
                    TReading.filterByOption(queryOption, completion: { (results) -> Void in
                        if results != nil && results!.count != 0 {
                            for result in results! {
                                if result.fModifyTimestamp != nil
                                    && result.fModifyTimestamp!.intValue != (noteMeta.updated.intValue/1000) {
                                    needUpdate = true
                                    break
                                }
                            }
                        } else {
                            needCreate = true
                        }
                        dispatchGroup.leave()
                    })
                    dispatchGroup.wait(timeout: DispatchTime.distantFuture)
                
                    if needCreate || needUpdate {
                        
                        // 获取当前笔记的全部信息
                        
                        var note: EDAMNote?
                        
                        dispatchGroup.enter()
                        strongSelf!.noteSession.primaryNoteStore()?.fetchNote(withGuid: noteMeta.guid, includingContent: true, resourceOptions: ENResourceFetchOption.includeData, completion: { (result, error) in
                            if error != nil {
                                print("Fail to getNote, error: \(error!.localizedDescription)")
                                dispatchGroup.leave()
                            } else {
                                note = result
                                dispatchGroup.leave()
                            }
                        })
                        dispatchGroup.wait(timeout: DispatchTime.distantFuture)
                        
                        strongSelf = self
                        if strongSelf == nil {
                            return
                        }
                        
                        if note == nil {
                            continue
                        }
                        
                        if needCreate {
                            TReading.create(withConstructBlock: { (newReading) -> Void in
                                newReading.fillFields(fromEverNote: note!, onlyFillUnSettedFields: true)
                                newReading.fLocalId = NSUUID().uuidString
                                newReading.fSyncStatus = NSNumber(value: ReadingSyncStatus.normal.rawValue)
                            })
                        } else if needUpdate {
                            TReading.update(withFilterOption: queryOption, updateBlock: { (readingtoUpdate) -> Void in
                                if readingtoUpdate.fSyncStatus == NSNumber(value: ReadingSyncStatus.normal.rawValue) {
                                    readingtoUpdate.fillFields(fromEverNote: note!, onlyFillUnSettedFields: false)
                                }
                            })
                        }
                        
                        syncDownNumber += 1
                    }
                }
                
                strongSelf?.downSynchronizing = false
                strongSelf?.lastTimeSyncdownNoteNumber = syncDownNumber
                strongSelf?.notifyNoteSyncdownStateDidChange()
                strongSelf?.needSyncDownNoteCount = NSNumber(value: 0)
                
                // 保存本次同步计数
                UserDefaults.standard.set(currentUpdateCount, forKey: kEvernoteLastUpdateCount)
                
                completion?(syncDownNumber)
            }
            }, failure: { [weak self] in
                if let strongSelf = self {
                    strongSelf.downSynchronizing = false
                    strongSelf.lastTimeSyncdownNoteNumber = 0
                    strongSelf.notifyNoteSyncdownStateDidChange()
                    completion?(0)
                }
        })
    }
}
