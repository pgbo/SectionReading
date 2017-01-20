//
//  SECReadingRecordCropper.swift
//  SectionReading
//
//  Created by guangbo on 15/12/8.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

class SECRecordRange: NSObject {
    fileprivate (set) var location: CGFloat = 0
    fileprivate (set) var length: CGFloat = 0
    
    init(location: CGFloat, length: CGFloat) {
        self.location = location
        self.length = length
    }
}

/// 读书录音裁切器，cropRange 中的部分将会被菜切掉
class SECReadingRecordCropper: NSObject {

    // 源文件路径
    fileprivate (set) var sourceRecordFilePath: String?
    
    // 裁切范围
    fileprivate (set) var cropRange: SECRecordRange?
    
    // 目标裁切文件存放路径
    fileprivate (set) var destinationCroppedFilePath: String?
    
    lazy fileprivate var oprerateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(sourceRecordFilePath: String, cropRange: SECRecordRange, destinationCroppedFilePath: String) {
        self.sourceRecordFilePath = sourceRecordFilePath
        self.cropRange = cropRange
        self.destinationCroppedFilePath = destinationCroppedFilePath
    }
    
    /**
     裁切
     
     - parameter completion:
     */
    func cropWithCompletion(_ completion: ((_ success: Bool) -> Void)?) {
        
        self.oprerateQueue.addOperation { [weak self] () -> Void in
            
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            let sourceRecordFilePath = strongSelf!.sourceRecordFilePath
            let cropRange = strongSelf!.cropRange
            let destinationCroppedFilePath = strongSelf!.destinationCroppedFilePath
            
            if sourceRecordFilePath == nil || cropRange == nil || destinationCroppedFilePath == nil {
                print("Fail to crop audio, cause sourceRecordFilePath, cropRange or destinationCroppedFilePath is nil.")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            // 截去中间选中的部分
            
            let asset = AVAsset(url: URL(fileURLWithPath: sourceRecordFilePath!))
            let tracks = asset.tracks(withMediaType: AVMediaTypeAudio)
            if tracks.count == 0 {
                print("Fail to crop audio, cause tracks is empty.")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            let duration = asset.duration
            if duration.seconds == 0  {
                print("Fail to crop audio, cause duration is 0.")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            let timeScale = Int32(1)
            var insertTimeRanges: [CMTimeRange] = []
            
            if cropRange!.location > 0 {
                // 插入第一段
                let startTime = kCMTimeZero
                let endTime = CMTimeMakeWithSeconds(Float64(cropRange!.location * CGFloat(timeScale) * CGFloat(duration.seconds)), timeScale)
                let firstTimeRange = CMTimeRangeMake(startTime, endTime)
                insertTimeRanges.append(firstTimeRange)
            }
            
            if (cropRange!.location + cropRange!.length) < 1 {
                // 插入第二段
                let startTime = CMTimeMakeWithSeconds(Float64((cropRange!.location + cropRange!.length) * CGFloat(timeScale) * CGFloat(duration.seconds)), timeScale)
                let endTime = CMTimeMake(Int64(CGFloat(timeScale) * CGFloat(duration.seconds)), timeScale)
                let secondTimeRange = CMTimeRangeMake(startTime, endTime)
                insertTimeRanges.append(secondTimeRange)
            }
            
            if insertTimeRanges.count == 0 {
                // 没有选取裁切区域
                DispatchQueue.main.async(execute: {
                    completion?(true)
                })
                return
            }
            
            let composition = AVMutableComposition()
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID:Int32(kCMPersistentTrackID_Invalid))
            
            do {
                var nextClipStartTime = kCMTimeZero
                for timeRange in insertTimeRanges {
                
                    try compositionAudioTrack.insertTimeRange(timeRange, of: tracks.first!, at: nextClipStartTime)
                    nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRange.duration)
                    
//                    print("timeRange:\(timeRange), timeRange.start:\(CMTimeGetSeconds(timeRange.start)), timeRange.duration:\(CMTimeGetSeconds(timeRange.duration))")
                }
                
            } catch let error as NSError {
                print("Fail to crop audio, err: \(error.localizedDescription)")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            // 导出到目的路径
            let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            if exporter == nil {
                print("Fail to crop audio, initialize AVAssetExportSession failed.")
                DispatchQueue.main.async(execute: {
                    completion?(false)
                })
                return
            }
            
            exporter!.outputFileType = AVFileTypeAppleM4A
            exporter!.outputURL = URL(fileURLWithPath: destinationCroppedFilePath!)
            
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
    
    fileprivate func randomObtainTemporaryAudioFilePath() -> String {
        return NSTemporaryDirectory() + "\(UUID().uuidString).caf"
    }
    
    /**
     导出部分的音频
     
     - parameter sourceAsset: 源音频
     - parameter exportRange: 导出的选区
     - parameter exportDestinationFilePath: 导出目的文件路径
     - parameter completion:  结束 block
     */
    fileprivate static func exportPartForAudioAsset(_ sourceAsset: AVAsset, exportRange: SECRecordRange, exportDestinationFilePath: String, completion: ((_ success:Bool) -> Void)?) {
        
        // 导出第一段
        let exporter = AVAssetExportSession(asset: sourceAsset, presetName: AVAssetExportPresetAppleM4A)
        exporter!.outputFileType = AVFileTypeAppleM4A
        exporter!.outputURL = URL(fileURLWithPath: exportDestinationFilePath)
        
        let timeScale = Int32(10)
        let startTime = CMTimeMake(Int64(exportRange.location * CGFloat(timeScale)), timeScale)
        let endTime = CMTimeMake(Int64((exportRange.location + exportRange.length) * CGFloat(timeScale)), timeScale)
        exporter!.timeRange = CMTimeRangeFromTimeToTime(startTime, endTime)
        
        // set up the audio mix
        let tracks = sourceAsset.tracks(withMediaType: AVMediaTypeAudio)
        if tracks.count == 0 {
            print("Fail to exportPartForAudioAsset, cause tracks is empty.")
            DispatchQueue.main.async(execute: {
                completion?(false)
            })
            return
        }
        
        let exportAudioMix = AVMutableAudioMix()
        let exportAudioMixInputParameters = AVMutableAudioMixInputParameters(track: tracks.first!)
        exportAudioMixInputParameters.setVolume(1.0, at: CMTimeMake(0, 1))
        exportAudioMix.inputParameters = [exportAudioMixInputParameters]
        exporter!.audioMix = exportAudioMix
        
        
        // do it
        exporter!.exportAsynchronously(completionHandler: { () -> Void in

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
        
    }
}
