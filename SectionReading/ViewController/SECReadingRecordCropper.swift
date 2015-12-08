//
//  SECReadingRecordCropper.swift
//  SectionReading
//
//  Created by guangbo on 15/12/8.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

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

    private (set) var sourceRecordFilePath: String?
    private (set) var cropRange: SECRecordRange?
    
    lazy private var oprerateQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(sourceRecordFilePath: String, cropRange: SECRecordRange) {
        self.sourceRecordFilePath = sourceRecordFilePath
        self.cropRange = cropRange
    }
    
    /**
     裁切
     
     - parameter completion:
     */
    func cropWithCompletion(completion: ((croppedFilePath: String?) -> Void)?) {
        
        /*
        let audioAsset = AVAsset(URL: NSURL(fileURLWithPath: strongSelf!.prepareTrimRecordFilePath!))
        
        // 截去中间选中的部分
        
        // 截段 1
        let trimmedAudioFile1 = strongSelf!.randomObtainTemporaryAudioFilePath()
        let trimmedAudioFile1_URL = NSURL(fileURLWithPath: trimmedAudioFile1)
        
        // 截段 2
        let trimmedAudioFile2 = strongSelf!.randomObtainTemporaryAudioFilePath()
        let trimmedAudioFile2_URL = NSURL(fileURLWithPath: trimmedAudioFile2)
        
        var exportSuccess = false
        var exporter: AVAssetExportSession?
        var startTime: CMTime?
        var endTime: CMTime?
        var exportAudioMix: AVMutableAudioMix?
        let timeScale = Int32(10)
        
        
        // 导出第一段
        exporter = AVAssetExportSession(asset: audioAsset, presetName: AVAssetExportPresetAppleM4A)
        exporter!.outputFileType = AVFileTypeAppleM4A
        exporter!.outputURL = trimmedAudioFile1_URL
        
        
        startTime = CMTimeMake(0, timeScale)
        endTime = CMTimeMake(Int64(selectedRange!.location * CGFloat(timeScale)), timeScale)
        exporter!.timeRange = CMTimeRangeFromTimeToTime(startTime!, endTime!)
        
        // set up the audio mix
        let tracks = audioAsset.tracksWithMediaType(AVMediaTypeAudio)
        if tracks.count == 0 {
            return
        }
        
        SVProgressHUD.showWithStatus("")
        
        exportAudioMix = AVMutableAudioMix()
        let exportAudioMixInputParameters = AVMutableAudioMixInputParameters(track: tracks.first!)
        exportAudioMixInputParameters.setVolume(1.0, atTime: CMTimeMake(0, 1))
        exportAudioMix!.inputParameters = [exportAudioMixInputParameters]
        exporter!.audioMix = exportAudioMix
        
        
        // do it
        exporter!.exportAsynchronouslyWithCompletionHandler({ [weak self] () -> Void in
            
            let strongSelf = self
            if strongSelf == nil {
                return
            }
            
            switch exporter!.status {
            case .Failed:
                print("export failed \(exporter!.error)")
                SVProgressHUD.showErrorWithStatus("剪辑失败")
                
            case .Cancelled:
                print("export cancelled \(exporter!.error)")
                SVProgressHUD.showErrorWithStatus("剪辑失败")
                
            default:
                print("export complete")
                
                // 设置新文件
                
                strongSelf!.recordFileURL = trimmedSoundFileURL
                strongSelf!.recordAsset = AVAsset.assetWithURL(strongSelf!.recordFileURL!) as? AVAsset
                
                // 调用代理方法
                strongSelf!.delegate?.cutRecordVC?(strongSelf!, didTrimRecordToFile:trimedSouldFile)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SVProgressHUD.showSuccessWithStatus("裁减成功")
                    // 设置界面
                    strongSelf!.cutDurationLabel.text = nil
                    strongSelf!.audioDurationLabel.text = "\(Int(strongSelf!.recordDuration())) s"
                    
                    strongSelf!.playProcessViewWidthConstraint.constant = 0
                    strongSelf!.cutSlideViewWidthConstraint.constant = 0
                })
            }
            })
        */
        
    }
}
