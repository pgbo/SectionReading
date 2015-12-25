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
     - parameter onlyFillUnSettedFields: 是否只填充未设置值的字段
     */
    func fillFields(fromEverNote note: EDAMNote, onlyFillUnSettedFields: Bool) {
        
        if onlyFillUnSettedFields {
            if fEvernoteGuid == nil {
                fEvernoteGuid = note.guid
            }
            if fUploadedAudioGuid == nil {
                fUploadedAudioGuid = TReading.getAudioResourceGuid(ofNote: note)
            }
            if fCreateTimestamp == nil {
                fCreateTimestamp = NSNumber(integer: note.created.integerValue/1000)
            }
            if fModifyTimestamp == nil {
                fModifyTimestamp = NSNumber(integer: note.updated.integerValue/1000)
            }
            if fContent == nil {
                fContent = TReading.getNotePlainText(ofNote: note)
            }
        } else {
            fEvernoteGuid = note.guid
            fUploadedAudioGuid = TReading.getAudioResourceGuid(ofNote: note)
            fCreateTimestamp = NSNumber(integer: note.created.integerValue/1000)
            fModifyTimestamp = NSNumber(integer: note.updated.integerValue/1000)
            fContent = TReading.getNotePlainText(ofNote: note)
        }
    }
    
    /**
     使用 Reading 填充笔记
     
     - parameter note:    笔记
     - parameter reading: 阅读信息
     - parameter onlyFillUnSettedFields: 是否只填充未设置值的字段
     */
    static func fillFieldsFor(note: EDAMNote, withReading reading: TReading, onlyFillUnSettedFields: Bool) {
    
        if onlyFillUnSettedFields {
        
            if note.guid == nil {
                note.guid = reading.fEvernoteGuid
            }
            
            var noteAudioRes: EDAMResource?
            if reading.fLocalAudioFilePath != nil {
                print("reading.fLocalAudioFilePath: \(reading.fLocalAudioFilePath!)")
                noteAudioRes = TReading.generateNoteResources(withAudioFilePath: reading.fLocalAudioFilePath!)
            }
            
            if note.resources == nil {
                if noteAudioRes != nil {
                    note.resources = [noteAudioRes!]
                }
            }
            
            if note.content == nil {
                note.content = TReading.generateEvernoteContent(withAudioResource: noteAudioRes, plainText: reading.fContent)
            }
            
        } else {
         
            note.guid = reading.fEvernoteGuid
            
            var noteAudioRes: EDAMResource?
            if reading.fLocalAudioFilePath != nil {
                noteAudioRes = TReading.generateNoteResources(withAudioFilePath: reading.fLocalAudioFilePath!)
            }
            if noteAudioRes != nil {
                note.resources = [noteAudioRes!]
            }
            
            note.content = TReading.generateEvernoteContent(withAudioResource: noteAudioRes, plainText: reading.fContent)
        }
    }
    
    private static func getNotePlainText(ofNote note: EDAMNote) -> String? {
        
        let content = note.content
        if content == nil {
            return nil
        }
        
        do {
            var rgex = try NSRegularExpression(pattern: "<en-note>.*?</en-note>", options: NSRegularExpressionOptions.DotMatchesLineSeparators)
            let result = rgex.firstMatchInString(content, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, content.characters.count))
            if result != nil {
                let range = result!.range
                let contentNodeTextRange = Range<String.Index>(start: content.startIndex.advancedBy(range.location), end: content.startIndex.advancedBy(range.location + range.length))
                var contentNodeText = content.substringWithRange(contentNodeTextRange)
                if let startTagRange = contentNodeText.rangeOfString("<en-note>") {
                    contentNodeText.removeRange(startTagRange)
                }
                if let endTagRange = contentNodeText.rangeOfString("</en-note>") {
                    contentNodeText.removeRange(endTagRange)
                }
                
                rgex = try NSRegularExpression(pattern: "<en-media.*?/>", options: NSRegularExpressionOptions(rawValue: 0))
                
                let targetContent = rgex.stringByReplacingMatchesInString(contentNodeText, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, contentNodeText.characters.count), withTemplate: "")
                
                print("targetContent: \(targetContent)")

                return targetContent
            }
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
        
        print("content:\(content)")
        return content
    }
    
    private static func getAudioResourceGuid(ofNote note: EDAMNote) -> String? {
        
        var audioResourceGuid: String?
        if let noteResources = note.resources as? [EDAMResource] {
            for res in noteResources {
                if res.mime.hasPrefix("audio/") {
                    audioResourceGuid = res.guid
                    break
                }
            }
        }
        return audioResourceGuid
    }
    
    private static func generateNoteResources(withAudioFilePath audioFilePath: String) -> EDAMResource? {
    
        if let audioData = NSData(contentsOfFile: audioFilePath) {
            let audioRes = EDAMResource()
            audioRes.data = EDAMData()
            audioRes.data.body = audioData
            audioRes.data.bodyHash = audioData.enmd5()
            audioRes.data.size = NSNumber(integer: audioData.length)
            
            
            var audioMime = ENMIMEUtils.determineMIMETypeForFile(audioFilePath)
            print("audioMime: \(audioMime)")
            if audioMime == nil {
                audioMime = "audio/basic"
            }
            audioRes.mime = audioMime
            return audioRes
        } else {
            return nil
        }
    }
    
    private static func generateEvernoteContent(withAudioResource audioResource: EDAMResource?, plainText: String?) -> String? {
        
        if audioResource == nil && plainText == nil {
            return nil
        }
        
        var noteContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
        noteContent += "<en-note>"
        
        if audioResource != nil {
            noteContent += "<en-media type=\"\(audioResource!.mime)\" hash=\"\(audioResource!.data.bodyHash.enlowercaseHexDigits())\" />\n"
        }
        
        if plainText != nil {
            noteContent += "\(plainText!)"
        }
        
        noteContent += "</en-note>"
        
        return noteContent
    }
}
