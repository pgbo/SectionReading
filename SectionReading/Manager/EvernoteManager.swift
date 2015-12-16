//
//  EvernoteSyncStub.swift
//  SectionReading
//
//  Created by guangbo on 15/12/15.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import evernote_cloud_sdk_ios

enum EvernoteSyncType {
    case UP
    case DOWN
}

class EvernoteSyncStub: NSObject {

    private var noteSession = ENSession.sharedSession()
    
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
            if let _ = self {
                completion?(success: error != nil)
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
     设置好本应用的笔记本
     */
    func setupApplicationNotebook() {
        // TODO:
    }
    
    /**
     印象笔记同步笔记
     
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
    
    private func syncUp(withCompletion completion: ((successNumber: Int) -> Void)?) {
        // TODO:
//        noteSession.primaryNoteStore().createNote(EDAMNote!, success: <#T##((EDAMNote!) -> Void)!##((EDAMNote!) -> Void)!##(EDAMNote!) -> Void#>, failure: <#T##((NSError!) -> Void)!##((NSError!) -> Void)!##(NSError!) -> Void#>)
    }
    
    private func syncDown(withCompletion completion: ((successNumber: Int) -> Void)?) {
        // TODO:
        
    }
}
