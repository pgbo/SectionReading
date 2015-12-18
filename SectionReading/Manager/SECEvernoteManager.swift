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
enum EvernoteSyncError: ErrorType {
    case NoError
    case EvernoteNotAuthenticated
    case FailToListNotebooks
    case FailToCreateNotebook
}

enum EvernoteSyncType {
    case UP
    case DOWN
}

let ApplicationNotebookName = "SectionReading"
let kApplicationNotebookGuid = "kApplicationNotebookGuid"
let kEvernoteLastUpdateCount = "kEvernoteLastUpdateCount"

class SECEvernoteManager: NSObject {

    // 是否正在同步
    private (set) var synchronizing = false
    
    private var noteSession = ENSession.sharedSession()
    private var needSyncDownNoteCount: NSNumber?
    
    private lazy var noteSycnOperationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
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
    func authenticate(withViewController viewController: UIViewController, completion:((success: Bool) -> Void)?) {
        
        noteSession.authenticateWithViewController(viewController, preferRegistration: false) { [weak self] (error) -> Void in
            if let strongSelf = self {
                if error == nil {
                    // 设置笔记本
                    strongSelf.setupApplicationNotebook(withCompletion: { (result) -> Void in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion?(success: result == .NoError)
                        })
                    })
                } else {
                    completion?(success: false)
                }
            }
        }
    }
    
    /**
     印象笔记解除授权
     */
    func unauthenticate() {
        
        noteSession.unauthenticate()
    }
    
    /**
     创建新的笔记
     
     - parameter content:    笔记内容
     - parameter completion: 回调 block
     */
    func createNote(withContent content: TReading, completion: ((EDAMNote?) -> Void)?) {
        
        let appNotebookGuid = NSUserDefaults.standardUserDefaults().objectForKey(kApplicationNotebookGuid) as? String
        if appNotebookGuid == nil {
            completion?(nil)
            return
        }
        
        let note = EDAMNote()
        TReading.fillFieldsFor(note, withReading: content)
        
        note.notebookGuid = appNotebookGuid!
        note.title = ""
        
        noteSession.primaryNoteStore().createNote(note, success: { (createdNote) -> Void in
            
            completion?(createdNote)
            
            }, failure: { (error) -> Void in
                print("Fail to createNote, error: \(error.localizedDescription)")
                completion?(nil)
        })
    }
    
    /**
     更新笔记
     
     - parameter guid:       笔记 guid
     - parameter newContent: 新的笔记内容
     - parameter completion: 回调 block
     */
    func updateNote(withGuid guid: String, newContent: TReading, completion: ((EDAMNote?) -> Void)?) {
        
        let appNotebookGuid = NSUserDefaults.standardUserDefaults().objectForKey(kApplicationNotebookGuid) as? String
        if appNotebookGuid == nil {
            completion?(nil)
            return
        }
        
        let note = EDAMNote()
        TReading.fillFieldsFor(note, withReading: newContent)
        
        note.guid = guid
        note.title = ""
        note.notebookGuid = appNotebookGuid!
        
        noteSession.primaryNoteStore().updateNote(note, success: { (updatedNote) -> Void in
            
            completion?(updatedNote)
            
            }) { (error) -> Void in
                print("Fail to createNote, error: \(error.localizedDescription)")
                completion?(nil)
        }
    }
    
    /**
     删除笔记
     
     - parameter guid:       笔记 guid
     - parameter completion: 回调 block
     */
    func deleteNote(withGuid guid: String, completion: ((success: Bool) -> Void)?) {
        
        noteSession.primaryNoteStore().deleteNoteWithGuid(guid, success: { (successNum) -> Void in
            
            completion?(success: true)
            
            }) { (error) -> Void in
                print("Fail to deleteNote, error: \(error.localizedDescription)")
                completion?(success: false)
        }
    }
    
    
    /**
     与印象笔记同步笔记
     
     - parameter type:       同步类型
     - parameter completion: 同步成功数量
     */
    func sync(type: EvernoteSyncType, completion: ((successNumber: Int) -> Void)?) {
        
        if isAuthenticated() == false {
            completion?(successNumber: 0)
            return
        }
        
        switch type {
        case .UP:
            syncUp(withCompletion: completion)
        case .DOWN:
            syncDown(withCompletion: completion)
        }
    }
    
    /**
     获取需要下载的笔记数量
     
     - parameter success: 成功 block
     - parameter failure: 失败 block
     */
    func getNeedSyncDownNoteCount(withSuccess success: ((Int) -> Void)?, failure: (() -> Void)?) {
        
        if needSyncDownNoteCount != nil {
            success?(needSyncDownNoteCount!.integerValue)
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
                success?(0)
                return
            }
            
            strongSelf!.noteSycnOperationQueue.addOperationWithBlock({ () -> Void in
              
                var needSycnDownNumber = 0
                let dispatchGroup = dispatch_group_create()
                
                for noteMeta in notesMetadata! {
                    
                    let queryOption = ReadingQueryOption()
                    queryOption.evernoteGuid = noteMeta.guid
                    
                    dispatch_group_enter(dispatchGroup)
                    TReading.filterByOption(queryOption, completion: { (results) -> Void in
                        if results == nil || results!.count == 0 {
                            for result in results! {
                                if result.fModifyTimestamp != nil
                                    && result.fModifyTimestamp!.integerValue != noteMeta.updated.integerValue {
                                    
                                    ++needSycnDownNumber
                                    break
                                }
                            }
                        } else {
                            ++needSycnDownNumber
                        }
                        dispatch_group_leave(dispatchGroup)
                    })
                    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
                }
                
                success?(needSycnDownNumber)
            })
            
        }) {
            failure?()
        }
    }
    
    private func getApplicationAllNotesMetadata(withNotesMetadataResultSpec notesMetadataResultSpec: EDAMNotesMetadataResultSpec, success: (([EDAMNoteMetadata]?) -> Void)?, failure: (() -> Void)?) {
        
        let appNotebookGuid = NSUserDefaults.standardUserDefaults().objectForKey(kApplicationNotebookGuid) as? String
        if appNotebookGuid == nil {
            failure?()
            return
        }
        
        self.noteSycnOperationQueue.addOperationWithBlock { [weak self] () -> Void in
            
            var strongSelf = self
            if strongSelf == nil {
                return
            }
            
            let dispatchGroup = dispatch_group_create()
            
            // 获取笔记数量
            
            var noteCount: NSNumber?
            var findNoteCountsSuccess = false
            let filter = EDAMNoteFilter()
            filter.notebookGuid = appNotebookGuid
            
            dispatch_group_enter(dispatchGroup)
            strongSelf!.noteSession.primaryNoteStore().findNoteCountsWithFilter(filter, withTrash: false, success: { (noteCollectionCounts) -> Void in
                noteCount = noteCollectionCounts.notebookCounts.values.first as? NSNumber
                findNoteCountsSuccess = true
                dispatch_group_leave(dispatchGroup)
                
                }, failure: { (error) -> Void in
                    print("Fail to findNoteCounts, error: \(error.localizedDescription)")
                    dispatch_group_leave(dispatchGroup)
            })
            dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
            
            if findNoteCountsSuccess == false {
                failure?()
                return
            }
            
            if noteCount == nil || noteCount!.integerValue == 0 {
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
            
            dispatch_group_enter(dispatchGroup)
            strongSelf!.noteSession.primaryNoteStore().findNotesMetadataWithFilter(filter, maxResults: noteCount!.unsignedIntegerValue, resultSpec: notesMetadataResultSpec, success: { (results) -> Void in
                
                noteMetas = results as? [EDAMNoteMetadata]
                findNotesMetadataSuccess = true
                
                dispatch_group_leave(dispatchGroup)
                
                }, failure: { (error) -> Void in
                    print("Fail to findNotesMetadata, error: \(error.localizedDescription)")
                    dispatch_group_leave(dispatchGroup)
            })
            dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
            
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
    private func setupApplicationNotebook(withCompletion completion: ((result: EvernoteSyncError) -> Void)?) {
        
        let notebookGuid = NSUserDefaults.standardUserDefaults().objectForKey(kApplicationNotebookGuid) as? String
        if notebookGuid != nil {
            noteSession.primaryNoteStore().getNotebookWithGuid(notebookGuid!, success: { [weak self] (notebook) -> Void in
                
                if let strongSelf = self {
                    if notebook.name != ApplicationNotebookName {
                        strongSelf.createApplicationNotebook(withCompletion: completion)
                        return
                    }
                    completion?(result: EvernoteSyncError.NoError)
                }
            }, failure: { [weak self] (error) -> Void in
                print("Fail to getNotebook, error: \(error.localizedDescription)")
                if let strongSelf = self {
                    strongSelf.createApplicationNotebook(withCompletion: completion)
                }
            })
        } else {
            noteSession.primaryNoteStore().listNotebooksWithSuccess({ [weak self] (books) -> Void in
                
                if let strongSelf = self {
                    var targetNotebook: EDAMNotebook?
                    for notebook in books {
                        if notebook.name == ApplicationNotebookName {
                            targetNotebook = notebook as? EDAMNotebook
                            break
                        }
                    }
                    if targetNotebook != nil {
                        NSUserDefaults.standardUserDefaults().setObject(targetNotebook!.guid, forKey: kApplicationNotebookGuid)
                        completion?(result: EvernoteSyncError.NoError)
                        return
                    }
                    
                    strongSelf.createApplicationNotebook(withCompletion: completion)
                }
            }, failure: { (error) -> Void in
                print("Fail to listNotebooks, error: \(error.localizedDescription)")
                completion?(result: EvernoteSyncError.FailToListNotebooks)
            })
        }
    }
    
    private func createApplicationNotebook(withCompletion completion: ((result: EvernoteSyncError) -> Void)?) {
    
        let notebook = EDAMNotebook()
        notebook.name = ApplicationNotebookName
        notebook.defaultNotebook = NSNumber(bool: false)
        noteSession.primaryNoteStore().createNotebook(notebook, success: { (notebook) -> Void in
            
            print("Success to createNotebook, guid: \(notebook.guid), name: \(notebook.name)")
            
            NSUserDefaults.standardUserDefaults().setObject(notebook.guid, forKey: kApplicationNotebookGuid)
            completion?(result: EvernoteSyncError.NoError)
            
            }) { (error) -> Void in
                print("Fail to createNotebook, error: \(error.localizedDescription)")
                completion?(result: EvernoteSyncError.FailToCreateNotebook)
        }
    }
    
    
    private func syncUp(withCompletion completion: ((successNumber: Int) -> Void)?) {
        
        self.noteSycnOperationQueue.addOperationWithBlock { () -> Void in
            
            let queryOption = ReadingQueryOption()
            queryOption.syncStatus = [.NeedSyncUpload, .NeedSyncDelete]
            TReading.filterByOption(queryOption) { [weak self] (results) -> Void in
                
                let strongSelf = self
                if strongSelf == nil {
                    return
                }
                if results == nil {
                    return
                }
                
                var successNumber = 0
                var dispatchGroup = dispatch_group_create()
                
                for reading in results! {
                    
                    let syncStatus = reading.fSyncStatus
                    if syncStatus == nil {
                        continue
                    }
                    
                    if syncStatus!.integerValue == ReadingSyncStatus.NeedSyncUpload.rawValue {
                        
                        if reading.fEvernoteGuid == nil {
                            // create
                            dispatch_group_enter(dispatchGroup)
                            strongSelf?.createNote(withContent: reading, completion: { (createdNote) -> Void in
                                if createdNote != nil {
                                    // 更新本地数据
                                    let filterOption = ReadingQueryOption()
                                    filterOption.localId = reading.fLocalId!
                                    
                                    TReading.update(withFilterOption: filterOption, updateBlock: { (readingtoUpdate) -> Void in
                                        
                                        readingtoUpdate.fillFields(fromEverNote: createdNote!)
                                        readingtoUpdate.fSyncStatus = NSNumber(integer: ReadingSyncStatus.Normal.rawValue)
                                    })
                                    
                                    ++successNumber
                                }
                                dispatch_group_leave(dispatchGroup)
                            })
                            dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
                        } else {
                            // update
                            dispatch_group_enter(dispatchGroup)
                            strongSelf?.updateNote(withGuid: reading.fEvernoteGuid!, newContent: reading, completion: { (updatedNote) -> Void in
                                if updatedNote != nil {
                                    // 更新本地数据
                                    let filterOption = ReadingQueryOption()
                                    filterOption.evernoteGuid = reading.fEvernoteGuid!
                                    
                                    TReading.update(withFilterOption: filterOption, updateBlock: { (readingtoUpdate) -> Void in
                                        
                                        readingtoUpdate.fillFields(fromEverNote: updatedNote!)
                                        readingtoUpdate.fSyncStatus = NSNumber(integer: ReadingSyncStatus.Normal.rawValue)
                                    })
                                    
                                    ++successNumber
                                }
                                dispatch_group_leave(dispatchGroup)
                            })
                            dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
                        }
                        
                    } else if syncStatus!.integerValue == ReadingSyncStatus.NeedSyncDelete.rawValue {
                        
                        if reading.fEvernoteGuid == nil {
                            continue
                        }
                        
                        // delete
                        dispatch_group_enter(dispatchGroup)
                        strongSelf?.deleteNote(withGuid: reading.fEvernoteGuid!, completion: { (success) -> Void in
                            if success {
                                // 删除本地数据
                                let filterOption = ReadingQueryOption()
                                filterOption.evernoteGuid = reading.fEvernoteGuid!
                                
                                TReading.deleteByOption(filterOption)
                                
                                ++successNumber
                            }
                            dispatch_group_leave(dispatchGroup)
                        })
                        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
                    }
                }
                
                dispatchGroup = nil
                completion?(successNumber: successNumber)
            }
        }
    }
    
    private func syncDown(withCompletion completion: ((Int) -> Void)?) {
        
        let resultSpec = EDAMNotesMetadataResultSpec()
        resultSpec.includeUpdated = true
        
        getApplicationAllNotesMetadata(withNotesMetadataResultSpec: resultSpec, success: { [weak self] (notesMetadata) -> Void in
        
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            if notesMetadata == nil {
                completion?(0)
                return
            }
            
            strongSelf!.noteSycnOperationQueue.addOperationWithBlock { [weak self] () -> Void in
                
                var strongSelf = self
                if strongSelf == nil {
                    return
                }
                
                let dispatchGroup = dispatch_group_create()
                
                // 考虑是否需要向下同步
                
                let latestUpdateCount = NSUserDefaults.standardUserDefaults().integerForKey(kEvernoteLastUpdateCount)
                var currentUpdateCount = 0
                
                dispatch_group_enter(dispatchGroup)
                strongSelf!.noteSession.primaryNoteStore().getSyncStateWithSuccess({ (syncState) -> Void in
                    currentUpdateCount = syncState.updateCount.integerValue
                    dispatch_group_leave(dispatchGroup)
                    
                    }, failure: { (error) -> Void in
                        print("Fail to getSyncState, error: \(error.localizedDescription)")
                        dispatch_group_leave(dispatchGroup)
                })
                dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
                
                if currentUpdateCount <= latestUpdateCount {
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
                    
                    dispatch_group_enter(dispatchGroup)
                    TReading.filterByOption(queryOption, completion: { (results) -> Void in
                        if results == nil || results!.count == 0 {
                            for result in results! {
                                if result.fModifyTimestamp != nil
                                    && result.fModifyTimestamp!.integerValue != noteMeta.updated.integerValue {
                                    needUpdate = true
                                    break
                                }
                            }
                        } else {
                            needCreate = true
                        }
                        dispatch_group_leave(dispatchGroup)
                    })
                    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
                
                    if needCreate || needUpdate {
                        
                        // 获取当前笔记的全部信息
                        
                        var note: EDAMNote?
                        
                        dispatch_group_enter(dispatchGroup)
                        strongSelf!.noteSession.primaryNoteStore().getNoteWithGuid(noteMeta.guid, withContent: true, withResourcesData: false, withResourcesRecognition: false, withResourcesAlternateData: false, success: { (result) -> Void in
                            note = result
                            dispatch_group_leave(dispatchGroup)
                            
                            }, failure: { (error) -> Void in
                                print("Fail to findNotesMetadata, error: \(error.localizedDescription)")
                                dispatch_group_leave(dispatchGroup)
                        })
                        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
                        
                        strongSelf = self
                        if strongSelf == nil {
                            return
                        }
                        
                        if note == nil {
                            continue
                        }
                        
                        if needCreate {
                            TReading.create(withConstructBlock: { (newReading) -> Void in
                                newReading.fillFields(fromEverNote: note!)
                                newReading.fLocalId = NSUUID().UUIDString
                            })
                        } else if needUpdate {
                            TReading.update(withFilterOption: queryOption, updateBlock: { (readingtoUpdate) -> Void in
                                readingtoUpdate.fillFields(fromEverNote: note!)
                            })
                        }
                        
                        ++syncDownNumber
                    }
                }
                
                // 保存本次同步计数
                NSUserDefaults.standardUserDefaults().setInteger(currentUpdateCount, forKey: kEvernoteLastUpdateCount)
                
                completion?(syncDownNumber)
            }
            }, failure: {
                completion?(0)
        })
    }
}
