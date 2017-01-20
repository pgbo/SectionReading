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

    fileprivate (set) var sourceAudioFilePaths: [String]?
    fileprivate (set) var destinationFilePath: String?
    
    lazy fileprivate var oprerateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(sourceAudioFilePaths: [String], destinationFilePath: String) {
        self.sourceAudioFilePaths = sourceAudioFilePaths
        self.destinationFilePath = destinationFilePath
    }
    
    func combineWithCompletion(_ completion: ((_ success: Bool) -> Void)?) {
        
        self.oprerateQueue.addOperation { [weak self] () -> Void in
            
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            let sourceAudioFilePaths = strongSelf!.sourceAudioFilePaths
            let destinationFilePath = strongSelf!.destinationFilePath
            if strongSelf!.sourceAudioFilePaths == nil || sourceAudioFilePaths!.count == 0 || strongSelf!.destinationFilePath == nil {
                print("Fail to combine, cuase sourceAudioFilePaths or destinationFilePath is nil, or sourceAudioFilePaths is empty.")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            if sourceAudioFilePaths!.count == 1 {
                do {
                    try FileManager.default.copyItem(atPath: sourceAudioFilePaths!.first!, toPath: destinationFilePath!)
                } catch (let error as NSError) {
                    print("Fail to copy audio record file.error:\(error.localizedDescription)")
                    DispatchQueue.main.async(execute: {
                        completion?(false)
                    })
                    return
                }
                DispatchQueue.main.async(execute: {
                    completion?(true)
                })
                return
            }
        
            let composition = AVMutableComposition()
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID:Int32(kCMPersistentTrackID_Invalid))
            
            var nextClipStartTime = kCMTimeZero
            for audioFile in sourceAudioFilePaths! {
                let asset = AVAsset(url: URL(fileURLWithPath: audioFile))
                let tracks = asset.tracks(withMediaType: AVMediaTypeAudio)
                if tracks.count == 0 {
                    continue
                }
                let duration = asset.duration
                
                do {
                    try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), of: tracks.first!, at: nextClipStartTime)
                    nextClipStartTime = CMTimeAdd(nextClipStartTime, duration)
                } catch let error as NSError {
                    print("insertTimeRange failed, err: \(error.localizedDescription)")
                }
            }
            
            if CMTimeCompare(nextClipStartTime, kCMTimeZero) == 0 {
                print("fail to combineAudioFiles.")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            // export
            
            let combindFileURL = URL(fileURLWithPath: destinationFilePath!)
            let fileMan = FileManager.default
            if fileMan.fileExists(atPath: destinationFilePath!) {
                // remove it
                do {
                    try fileMan.removeItem(at: combindFileURL)
                } catch let error as NSError {
                    print("remove exist combine file failed, err: \(error.localizedDescription)")
                    DispatchQueue.main.async(execute: {
                        completion?(false)
                    })
                    return
                }
            }
            
            let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            if exporter == nil {
                print("Fail to combine audio files, fail to initialize AVAssetExportSession.")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            exporter!.outputFileType = AVFileTypeAppleM4A
            exporter!.outputURL = combindFileURL
            
            // do it
            exporter!.exportAsynchronously(completionHandler: { [weak self] () -> Void in
                
                let strongSelf = self
                if strongSelf == nil {
                    return
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    switch exporter!.status {
                    case .failed:
                        print("export failed \(exporter!.error)")
                        completion?(false)
                        
                    case .cancelled:
                        print("export cancelled \(exporter!.error)")
                        completion?(false)
                        
                    default:
                        print("export complete")
                        completion?(true)
                    }
                })
            })
        }
    }
}
