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
        
        fEvernoteGuid = note.guid
        fCreateTimestamp = note.created
        fModifyTimestamp = note.updated
        fContent = note.content
    }
    
    /**
     使用 Reading 填充笔记
     
     - parameter note:    笔记
     - parameter reading: 阅读信息
     */
    static func fillFieldsFor(note: EDAMNote, withReading reading: TReading) {
    
        note.guid = reading.fEvernoteGuid
        
        var audioRes: EDAMResource?
        
        if reading.fUploadingAudioFilePath != nil {
            if let audioData = NSData(contentsOfFile: reading.fUploadingAudioFilePath!) {
                audioRes = EDAMResource()
                audioRes!.data = EDAMData()
                audioRes!.data.body = audioData
                audioRes!.data.bodyHash = audioData.enmd5()
                audioRes!.data.size = NSNumber(integer: audioData.length)
                
                var audioMime = ENMIMEUtils.determineMIMETypeForFile(reading.fUploadingAudioFilePath!)
                print("audioMime: \(audioMime)")
                if audioMime == nil {
                    audioMime = "audio/basic"
                }
                
                audioRes!.mime = audioMime
                
                note.resources = [audioRes!]
            }
        }
        
        note.content = TReading.generateEvernoteContent(withAudioResource: audioRes, plainText: reading.fContent)
    }
    
    private static func generateEvernoteContent(withAudioResource audioResource: EDAMResource?, plainText: String?) -> String? {
        
        if audioResource == nil && plainText == nil {
            return nil
        }
        
        var noteContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
        noteContent += "<en-note>"
        
        if audioResource != nil {
            noteContent += "<en-media type=\"\(audioResource!.mime)\" hash=\"\(audioResource!.data.bodyHash.enlowercaseHexDigits())\" /><br />"
        }
        
        if plainText != nil {
            noteContent += "\(plainText!)"
        }
        
        noteContent += "</en-note>"
        
        return noteContent
    }
}
