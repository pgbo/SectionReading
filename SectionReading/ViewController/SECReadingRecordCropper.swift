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
    private (set) var location: CGFloat = 0
    private (set) var length: CGFloat = 0
    
    init(location: CGFloat, length: CGFloat) {
        self.location = location
        self.length = length
    }
}

/// 读书录音裁切器，cropRange 中的部分将会被菜切掉
class SECReadingRecordCropper: NSObject {

    // 源文件路径
    private (set) var sourceRecordFilePath: String?
    
    // 裁切范围
    private (set) var cropRange: SECRecordRange?
    
    // 目标裁切文件存放路径
    private (set) var destinationCroppedFilePath: String?
    
    lazy private var oprerateQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
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
    func cropWithCompletion(completion: ((success: Bool) -> Void)?) {
        
        self.oprerateQueue.addOperationWithBlock { [weak self] () -> Void in
            
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            let sourceRecordFilePath = strongSelf!.sourceRecordFilePath
            let cropRange = strongSelf!.cropRange
            let destinationCroppedFilePath = strongSelf!.destinationCroppedFilePath
            
            if sourceRecordFilePath == nil || cropRange == nil || destinationCroppedFilePath == nil {
                print("Fail to crop audio, cause sourceRecordFilePath, cropRange or destinationCroppedFilePath is nil.")
                completion?(success: false)
                return
            }
            
            // 截去中间选中的部分
            
            let asset = AVAsset(URL: NSURL(fileURLWithPath: sourceRecordFilePath!))
            let tracks = asset.tracksWithMediaType(AVMediaTypeAudio)
            if tracks.count == 0 {
                print("Fail to crop audio, cause tracks is empty.")
                completion?(success: false)
                return
            }
            
            let duration = asset.duration
            if duration.seconds == 0  {
                print("Fail to crop audio, cause duration is 0.")
                completion?(success: false)
                return
            }
            
            let timeScale = Int32(10)
            var insertTimeRanges: [CMTimeRange] = []
            
            if cropRange!.location > 0 {
                // 插入第一段
                let startTime = kCMTimeZero
                let endTime = CMTimeMake(Int64(cropRange!.location * CGFloat(timeScale)), timeScale)
                let firstTimeRange = CMTimeRangeMake(startTime, endTime)
                insertTimeRanges.append(firstTimeRange)
            }
            
            if (cropRange!.location + cropRange!.length) < 1 {
                // 插入第二段
                let startTime = CMTimeMake(Int64((cropRange!.location + cropRange!.length) * CGFloat(timeScale)), timeScale)
                let endTime = CMTimeMake(Int64(1.0 * CGFloat(timeScale)), timeScale)
                let secondTimeRange = CMTimeRangeMake(startTime, endTime)
                insertTimeRanges.append(secondTimeRange)
            }
            
            if insertTimeRanges.count == 0 {
                // 没有选取裁切区域
                completion?(success: true)
                return
            }
            
            let composition = AVMutableComposition()
            let compositionAudioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID:Int32(kCMPersistentTrackID_Invalid))
            
            do {
                var nextClipStartTime = kCMTimeZero
                for timeRange in insertTimeRanges {
                
                    try compositionAudioTrack.insertTimeRange(timeRange, ofTrack: tracks.first!, atTime: nextClipStartTime)
                    nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRange.duration)
                }
                
            } catch let error as NSError {
                print("Fail to crop audio, err: \(error.localizedDescription)")
                completion?(success: false)
                return
            }
            
            // 导出到目的路径
            let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            if exporter == nil {
                print("Fail to crop audio, initialize AVAssetExportSession failed.")
                completion?(success: false)
                return
            }
            
            exporter!.outputFileType = AVFileTypeAppleM4A
            exporter!.outputURL = NSURL(fileURLWithPath: destinationCroppedFilePath!)
            
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
    
    private func randomObtainTemporaryAudioFilePath() -> String {
        return NSTemporaryDirectory().stringByAppendingString("/\(NSUUID().UUIDString).caf")
    }
    
    /**
     导出部分的音频
     
     - parameter sourceAsset: 源音频
     - parameter exportRange: 导出的选区
     - parameter exportDestinationFilePath: 导出目的文件路径
     - parameter completion:  结束 block
     */
    private static func exportPartForAudioAsset(sourceAsset: AVAsset, exportRange: SECRecordRange, exportDestinationFilePath: String, completion: ((success:Bool) -> Void)?) {
        
//        var exportSuccess = false
//        var exporter: AVAssetExportSession?
//        var startTime: CMTime?
//        var endTime: CMTime?
//        var exportAudioMix: AVMutableAudioMix?
        
        
        // 导出第一段
        let exporter = AVAssetExportSession(asset: sourceAsset, presetName: AVAssetExportPresetAppleM4A)
        exporter!.outputFileType = AVFileTypeAppleM4A
        exporter!.outputURL = NSURL(fileURLWithPath: exportDestinationFilePath)
        
        let timeScale = Int32(10)
        let startTime = CMTimeMake(Int64(exportRange.location * CGFloat(timeScale)), timeScale)
        let endTime = CMTimeMake(Int64((exportRange.location + exportRange.length) * CGFloat(timeScale)), timeScale)
        exporter!.timeRange = CMTimeRangeFromTimeToTime(startTime, endTime)
        
        // set up the audio mix
        let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)
        if tracks.count == 0 {
            print("Fail to exportPartForAudioAsset, cause tracks is empty.")
            completion?(success: false)
            return
        }
        
        let exportAudioMix = AVMutableAudioMix()
        let exportAudioMixInputParameters = AVMutableAudioMixInputParameters(track: tracks.first!)
        exportAudioMixInputParameters.setVolume(1.0, atTime: CMTimeMake(0, 1))
        exportAudioMix.inputParameters = [exportAudioMixInputParameters]
        exporter!.audioMix = exportAudioMix
        
        
        // do it
        exporter!.exportAsynchronouslyWithCompletionHandler({ () -> Void in

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
        
    }
}
