//
//  TReading+Mapping.swift
//  SectionReading
//
//  Created by guangbo on 15/12/15.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import Foundation
import evernote_cloud_sdk_ios

extension TReading {
    
    /**
     使用笔记信息填充 Reading
     
     - parameter note: 笔记
     */
    func fillFields(fromEverNote note: EDAMNote) {
        
        fGuid = note.guid
        fCreateTimestamp = note.created.integerValue
        fModifyTimestamp = note.updated.integerValue
        fContent = note.content
    }
    
    /**
     使用 Reading 填充笔记
     
     - parameter note:    笔记
     - parameter reading: 阅读信息
     */
    static func fillFieldsFor(note: EDAMNote, withReading reading: TReading) {
    
        note.guid = reading.fGuid
        note.created = reading.fCreateTimestamp
        note.updated = reading.fModifyTimestamp
        note.content = reading.fContent
    }
}
