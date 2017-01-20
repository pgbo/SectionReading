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
                fCreateTimestamp = NSNumber(value: note.created.intValue/1000)
            }
            if fModifyTimestamp == nil {
                fModifyTimestamp = NSNumber(value: note.updated.intValue/1000)
            }
            if fContent == nil {
                fContent = TReading.getNotePlainText(ofNote: note)
            }
        } else {
            fEvernoteGuid = note.guid
            fUploadedAudioGuid = TReading.getAudioResourceGuid(ofNote: note)
            fCreateTimestamp = NSNumber(value: note.created.intValue/1000)
            fModifyTimestamp = NSNumber(value: note.updated.intValue/1000)
            fContent = TReading.getNotePlainText(ofNote: note)
        }
    }
    
    /**
     使用 Reading 填充笔记
     
     - parameter note:    笔记
     - parameter reading: 阅读信息
     - parameter onlyFillUnSettedFields: 是否只填充未设置值的字段
     */
    static func fillFieldsFor(_ note: EDAMNote, withReading reading: TReading, onlyFillUnSettedFields: Bool) {
    
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
    
    fileprivate static func getNotePlainText(ofNote note: EDAMNote) -> String? {
        
        let content = note.content
        if content == nil {
            return nil
        }
        
        do {
            var rgex = try NSRegularExpression(pattern: "<en-note>.*?</en-note>", options: NSRegularExpression.Options.dotMatchesLineSeparators)
            let result = rgex.firstMatch(in: content!, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (content?.characters.count)!))
            if result != nil {
                let range = result!.range
                let contentStartIndex = content!.startIndex
                let contentNodeTextRange = Range<String.Index>(uncheckedBounds:(lower: content!.index(contentStartIndex, offsetBy:range.location), upper: content!.index(contentStartIndex, offsetBy:range.location + range.length)))
                var contentNodeText = content!.substring(with: contentNodeTextRange)
                if let startTagRange = contentNodeText.range(of: "<en-note>") {
                    contentNodeText.removeSubrange(startTagRange)
                }
                if let endTagRange = contentNodeText.range(of: "</en-note>") {
                    contentNodeText.removeSubrange(endTagRange)
                }
                
                rgex = try NSRegularExpression(pattern: "<en-media.*?/>", options: NSRegularExpression.Options(rawValue: 0))
                
                let targetContent = rgex.stringByReplacingMatches(in: contentNodeText, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, contentNodeText.characters.count), withTemplate: "")
                
                print("targetContent: \(targetContent)")

                return targetContent
            }
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
        
        print("content:\(content)")
        return content
    }
    
    fileprivate static func getAudioResourceGuid(ofNote note: EDAMNote) -> String? {
        
        var audioResourceGuid: String?
        if let noteResources = note.resources {
            for res in noteResources {
                if res.mime.hasPrefix("audio/") {
                    audioResourceGuid = res.guid
                    break
                }
            }
        }
        return audioResourceGuid
    }
    
    fileprivate static func generateNoteResources(withAudioFilePath audioFilePath: String) -> EDAMResource? {
        
        let audioData = NSData(contentsOfFile: audioFilePath)
        if audioData != nil {
            let audioRes = EDAMResource()
            audioRes.data = EDAMData()
            audioRes.data.body = Data(bytes:audioData!.bytes, count:audioData!.length)
            audioRes.data.bodyHash = audioData!.enmd5
            audioRes.data.size = NSNumber(value: audioData!.length)
            
            
            var audioMime = ENMIMEUtils.determineMIMEType(forFile: audioFilePath)
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
    
    fileprivate static func generateEvernoteContent(withAudioResource audioResource: EDAMResource?, plainText: String?) -> String? {
        
        if audioResource == nil && plainText == nil {
            return nil
        }
        
        var noteContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
        noteContent += "<en-note>"
        
        if audioResource != nil {
            let bodyHashLength = audioResource!.data.bodyHash.count
            var bodyHashBytes = [UInt8](repeating:0, count:bodyHashLength)
            audioResource!.data.bodyHash.copyBytes(to: &bodyHashBytes, count: bodyHashLength)
            let bodyHashData = NSData(bytes:bodyHashBytes, length:bodyHashLength)
            noteContent += "<en-media type=\"\(audioResource!.mime)\" hash=\"\(bodyHashData.enlowercaseHexDigits)\" />\n"
        }
        
        if plainText != nil {
            noteContent += "\(plainText!)"
        }
        
        noteContent += "</en-note>"
        
        return noteContent
    }
}
