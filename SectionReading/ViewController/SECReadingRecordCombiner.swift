//
//  SECReadingRecordCombiner.swift
//  SectionReading
//
//  Created by guangbo on 15/12/10.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

/// 读书录音组合器，将多段录音组合起来
class SECReadingRecordCombiner: NSObject {

    private (set) var sourceAudioFilePaths: [String]?
    private (set) var destinationFilePath: String?
    
    lazy private var oprerateQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(sourceAudioFilePaths: [String], destinationFilePath: String) {
        self.sourceAudioFilePaths = sourceAudioFilePaths
        self.destinationFilePath = destinationFilePath
    }
    
    func combineWithCompletion(completion: ((success: Bool) -> Void)?) {
        
        self.oprerateQueue.addOperationWithBlock { [weak self] () -> Void in
            
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            let sourceAudioFilePaths = strongSelf!.sourceAudioFilePaths
            let destinationFilePath = strongSelf!.destinationFilePath
            if strongSelf!.sourceAudioFilePaths == nil || sourceAudioFilePaths!.count == 0 || strongSelf!.destinationFilePath == nil {
                print("Fail to combine, cuase sourceAudioFilePaths or destinationFilePath is nil, or sourceAudioFilePaths is empty.")
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(success: false)
                })
                return
            }
            
            if sourceAudioFilePaths!.count == 1 {
                do {
                    try NSFileManager.defaultManager().copyItemAtPath(sourceAudioFilePaths!.first!, toPath: destinationFilePath!)
                } catch (let error as NSError) {
                    print("Fail to copy audio record file.error:\(error.localizedDescription)")
                    dispatch_async(dispatch_get_main_queue(), {
                        completion?(success: false)
                    })
                    return
                }
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(success: true)
                })
                return
            }
        
            let composition = AVMutableComposition()
            let compositionAudioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID:Int32(kCMPersistentTrackID_Invalid))
            
            var nextClipStartTime = kCMTimeZero
            for audioFile in sourceAudioFilePaths! {
                let asset = AVAsset(URL: NSURL(fileURLWithPath: audioFile))
                let tracks = asset.tracksWithMediaType(AVMediaTypeAudio)
                if tracks.count == 0 {
                    continue
                }
                let duration = asset.duration
                
                do {
                    try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), ofTrack: tracks.first!, atTime: nextClipStartTime)
                    nextClipStartTime = CMTimeAdd(nextClipStartTime, duration)
                } catch let error as NSError {
                    print("insertTimeRange failed, err: \(error.localizedDescription)")
                }
            }
            
            if CMTimeCompare(nextClipStartTime, kCMTimeZero) == 0 {
                print("fail to combineAudioFiles.")
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(success: false)
                })
                return
            }
            
            // export
            
            let combindFileURL = NSURL(fileURLWithPath: destinationFilePath!)
            let fileMan = NSFileManager.defaultManager()
            if fileMan.fileExistsAtPath(destinationFilePath!) {
                // remove it
                do {
                    try fileMan.removeItemAtURL(combindFileURL)
                } catch let error as NSError {
                    print("remove exist combine file failed, err: \(error.localizedDescription)")
                    dispatch_async(dispatch_get_main_queue(), {
                        completion?(success: false)
                    })
                    return
                }
            }
            
            let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            if exporter == nil {
                print("Fail to combine audio files, fail to initialize AVAssetExportSession.")
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(success: false)
                })
                return
            }
            
            exporter!.outputFileType = AVFileTypeAppleM4A
            exporter!.outputURL = combindFileURL
            
            // do it
            exporter!.exportAsynchronouslyWithCompletionHandler({ [weak self] () -> Void in
                
                let strongSelf = self
                if strongSelf == nil {
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    switch exporter!.status {
                    case .Failed:
                        print("export failed \(exporter!.error)")
                        completion?(success: false)
                        
                    case .Cancelled:
                        print("export cancelled \(exporter!.error)")
                        completion?(success: false)
                        
                    default:
                        print("export complete")
                        completion?(success: true)
                    }
                })
            })
        }
    }
}
