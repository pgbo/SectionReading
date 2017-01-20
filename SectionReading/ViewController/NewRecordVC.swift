//
//  NewRecordVC.swift
//  SectionReading
//
//  Created by 彭光波 on 15/9/17.
//  Copyright (c) 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

/// 录音音频状态
enum RecordAudioState {
    case normal
    case recording
    case recordPaused
    case audioPlaying
}

let LimitMinutesPerRecord = 3 /** 每个录音的限制时长，单位：分钟 */
let StopRecordButtonTopSpacing = CGFloat(24)
let PlayRecordButtonTopSpacing = CGFloat(12)

class NewRecordVC: UIViewController, AVAudioRecorderDelegate, UIViewControllerTransitioningDelegate, PlayRecordVCDelegate {
    
    fileprivate (set) var recordButtonView: RecordButtonView?
    fileprivate (set) var recordButtonViewCenterY: NSLayoutConstraint?
    
    fileprivate (set) var stopRecordButn: UIButton?
    fileprivate (set) var playRecordButn: UIButton?
    
    fileprivate (set) var fakeCDPlaySlider: CDPlaySlider?
    
    fileprivate var audioRecorder: AVAudioRecorder?
    fileprivate var recordAudioState = RecordAudioState.normal
    fileprivate var currentRecordFilePath: String?              /** 当前录音文件路径 */
    fileprivate var lastCombineAudioFilePath: String?           /** 上次音频合并的文件路径 */
    

    fileprivate var recordProcessDisplayLink: CADisplayLink? /** 进度定时器 */
    
    lazy fileprivate var presentRecordPlayTransition:PresentRecordPlayTransition = PresentRecordPlayTransition()
    lazy fileprivate var dismissRecordPlayTransition:DismissRecordPlayTransition = DismissRecordPlayTransition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: PlayRecordVCBackButtonClickNotification), object: nil, queue: OperationQueue.main) { (note) -> Void in
            if self.presentedViewController != nil && self.presentedViewController!.isKind(of: PlayRecordVC.self) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        self.view.backgroundColor = UIColor(red: 0xf5/255.0, green: 0xee/255.0, blue: 0xee/255.0, alpha: 1)
        
        self.navigationItem.title = "新建读书"
        
        // 设置 recordButtonView
        
        recordButtonView = RecordButtonView(frame: CGRect(x: 0, y: 0, width: 220, height: 220))
        self.view.addSubview(recordButtonView!)
        
        recordButtonView?.iconView?.image = UIImage(named: "RecordMicro")?.withRenderingMode(.alwaysTemplate)
        recordButtonView?.iconView?.tintColor = UIColor.white
        recordButtonView?.titleLabel?.text = "开始录音"
        
        recordButtonView?.button?.addTarget(self, action: #selector(NewRecordVC.recordButtonViewButtonClick), for: UIControlEvents.touchUpInside)
        
        
        recordButtonView?.translatesAutoresizingMaskIntoConstraints = false
        
        recordButtonViewCenterY = NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        self.view.addConstraint(recordButtonViewCenterY!)
        
        self.view.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        recordButtonView!.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: 220))
        
        recordButtonView!.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))
        
        
        // 设置 stopRecordButn
        
        stopRecordButn = UIButton(type: UIButtonType.custom)
        self.view.addSubview(stopRecordButn!)
        
        stopRecordButn?.alpha = 0
        stopRecordButn?.setTitle("停止录音", for: UIControlState())
        stopRecordButn?.backgroundColor = UIColor.clear
        stopRecordButn?.addTarget(self, action: #selector(NewRecordVC.stopRecord), for: UIControlEvents.touchUpInside)
        stopRecordButtonDisabled(stopRecordButn!.isEnabled == false)
        
        stopRecordButn?.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: StopRecordButtonTopSpacing))
        
        self.view.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        stopRecordButn!.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 100))
        
        stopRecordButn!.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 38))
        
        
        // 设置 playRecordButn
        
        playRecordButn = UIButton(type: UIButtonType.custom)
        self.view.addSubview(playRecordButn!)
        
        playRecordButn?.alpha = 0
        playRecordButn?.setTitle("播放", for: UIControlState())
        playRecordButn?.backgroundColor = UIColor.clear
        playRecordButn?.addTarget(self, action: #selector(NewRecordVC.playRecord), for: UIControlEvents.touchUpInside)
        playRecordButn?.setTitleColor(UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1), for: UIControlState())
        roundActionButton(playRecordButn, color: playRecordButn!.currentTitleColor)
        
        playRecordButn?.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: stopRecordButn!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: PlayRecordButtonTopSpacing))
        
        self.view.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        playRecordButn!.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 100))
        
        playRecordButn!.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 38))
        
        
        // 设置 fakeCDPlaySlider
        
        fakeCDPlaySlider = CDPlaySlider(frame: CGRect(x: 0, y: 0, width: 220, height: 220))
        self.view.addSubview(fakeCDPlaySlider!)
        
        fakeCDPlaySlider?.backgroundColor = UIColor.clear
        fakeCDPlaySlider?.alpha = 0
        fakeCDPlaySlider?.translatesAutoresizingMaskIntoConstraints = false
        
        // scopeGradientView
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopRecord()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
//    override func layoutSublayersOfLayer(layer: CALayer) {
//        super.layoutSublayersOfLayer(layer)
//        if layer == stopRecordButn?.layer {
//            stopRecordButtonDisabled(stopRecordButn!.enabled == false)
//            return
//        }
//        
//        if layer == playRecordButn?.layer {
//            borderActionButton(playRecordButn, color: playRecordButn!.currentTitleColor)
//            return
//        }
//    }
    
    @objc fileprivate func recordButtonViewButtonClick() {
        switch recordAudioState {
        case .normal:
            // 开始录音
            startRecord()
        case .recording:
            // 暂停录音
            pauseRecord()
        case .recordPaused:
            // 继续录音
            startRecord()
        default:
            print("recordAudioState:\(recordAudioState)")
        }
    }
    
    fileprivate func activeRecordAudioSession() -> Bool {
        
        var error: NSError?
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error1 as NSError {
            error = error1
        }
        
        if error != nil {
            print("failed, error:\(error!.localizedDescription)")
            return false
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error1 as NSError {
            error = error1
        }
        if error != nil {
            print("failed, error:\(error!.localizedDescription)")
            return false
        }
        
        return true
    }
    
    fileprivate func stopRecordButtonDisabled(_ disabled: Bool) {
        
        var tintColor: UIColor?
        if disabled {
            tintColor = UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 0.5)
            stopRecordButn?.setTitleColor(tintColor!, for: UIControlState.disabled)
        } else {
            tintColor = UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1)
            stopRecordButn?.setTitleColor(tintColor!, for: UIControlState())
        }
        
        roundActionButton(stopRecordButn, color: tintColor!)
    }
    
    fileprivate func roundActionButton(_ button: UIButton?, color: UIColor) {
        button?.layer.borderColor = color.cgColor
        button?.layer.borderWidth = 1.0
        button?.layer.cornerRadius = 8.0
        button?.layer.masksToBounds = true
    }
    
    fileprivate func stopRecordButtonTintColorWithState(_ state: UIControlState) -> UIColor {
        switch state {
        case UIControlState.highlighted:
            return UIColor(red:0x4f/255.0, green: 0x8c/255.0, blue: 0x93/255.0, alpha: 1)
        case UIControlState.disabled:
            return UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 0.5)
        default:
            return UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1)
        }
    }
    
    @objc fileprivate func recordProgressing() {
        if audioRecorder != nil && audioRecorder!.isRecording {
            
            // 改变录音 icon 颜色
            if let iconViewTintColor = recordButtonView?.iconView?.tintColor {
                var alpha: CGFloat = 0
                iconViewTintColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
                if alpha <= 0.5 {
                    alpha = 1
                } else {
                    alpha -= 0.15
                }
                recordButtonView?.iconView?.tintColor = recordButtonView?.iconView?.tintColor.withAlphaComponent(alpha)
            }
            
            // 改变进度
            
            let progress = audioRecorder!.currentTime/TimeInterval(LimitMinutesPerRecord*60)
            recordButtonView?.progressView?.progress = CGFloat(progress)
            
            recordButtonView?.progressView?.progressLabel?.text = "\(Int(audioRecorder!.currentTime))"
        }
    }
    
    fileprivate func startRecord() {
        if recordAudioState != .recording {
            
            if activeRecordAudioSession() == false {
                print("Fail to activeRecordAudioSession.")
                return
            }
            
            if audioRecorder == nil {
//                audioRecorder = RAQRecorder()
//                audioRecorder?.audioFilePath = NSTemporaryDirectory().stringByAppendingString("/\(NSUUID().UUIDString).caf")
//                
                let settings = [AVFormatIDKey:NSNumber(value: kAudioFormatALaw as UInt32), AVSampleRateKey:NSNumber(value: 44100 as Int32), AVNumberOfChannelsKey:NSNumber(value: 1 as Int32)]
                
                do {
                    let audioFilePath = randomObtainTemporaryAudioFilePath()
                    audioRecorder = try AVAudioRecorder(url: URL(fileURLWithPath: audioFilePath), settings: settings)
                    
                    currentRecordFilePath = audioFilePath
                    
                    weak var weakSelf = self
                    audioRecorder?.delegate = weakSelf
                    audioRecorder?.prepareToRecord()
                    
                    audioRecorder?.record(forDuration: TimeInterval(LimitMinutesPerRecord * 60))
                    
                } catch let error as NSError {
                    print("error: \(error)")
                }
                
            } else {
                audioRecorder?.record()
            }
            
            recordAudioState = .recording
            recordStarted()
        }
    }
    
    fileprivate func recordStarted() {
        // 启动进度定时器
        
        recordProcessDisplayLink?.invalidate()
        
        recordProcessDisplayLink = CADisplayLink(target: self, selector: #selector(NewRecordVC.recordProgressing))
        recordProcessDisplayLink?.frameInterval = 30
        recordProcessDisplayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        if recordButtonViewCenterY != nil && recordButtonViewCenterY!.constant == 0 {
           
            if stopRecordButn != nil {
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.4, animations: { () -> Void in
                    
                    self.recordButtonViewCenterY?.constant = -(self.stopRecordButn!.bounds.height + StopRecordButtonTopSpacing)/2
                    
                    self.stopRecordButn?.alpha = 1.0
                    
                    self.view.layoutIfNeeded()
                    
                    },
                    completion: { (finished) -> Void in
                        self.recordButtonView?.titleLabel?.text = "点击暂停"
                })
            } else {
                self.recordButtonView?.titleLabel?.text = "点击暂停"
            }
        } else {
            self.recordButtonView?.titleLabel?.text = "点击暂停"
        }
    }
    
    fileprivate func pauseRecord() {
        
        if recordAudioState == .recording {
            audioRecorder?.pause()
            recordAudioState = .recordPaused
            recordPaused()
        }
    }
    
    fileprivate func recordPaused() {
        recordProcessDisplayLink?.invalidate()
        recordButtonView?.iconView?.tintColor = recordButtonView?.iconView?.tintColor.withAlphaComponent(1)
        
        // 显示出播放按钮
        if self.playRecordButn?.alpha == 0 {
            
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                
                self.recordButtonViewCenterY?.constant = -(self.stopRecordButn!.bounds.height + StopRecordButtonTopSpacing + self.playRecordButn!.bounds.height + PlayRecordButtonTopSpacing)/2
                
                self.playRecordButn?.alpha = 1.0
                
                self.view.layoutIfNeeded()
                
                },
                completion: { (finished) -> Void in
                    self.recordButtonView?.titleLabel?.text = "点击继续"
            })
            
        }
    }
    
    @objc fileprivate func stopRecord() {
        
        if recordAudioState == .recording || recordAudioState == .recordPaused {
            audioRecorder?.stop()
            recordAudioState = .normal
            recordStopped()
        }
    }
    
    fileprivate func recordStopped() {
        recordProcessDisplayLink?.invalidate()
        
        self.recordButtonView?.progressView?.progress = 0.0
        recordButtonView?.iconView?.tintColor = recordButtonView?.iconView?.tintColor.withAlphaComponent(1)
        
        if recordButtonViewCenterY != nil && recordButtonViewCenterY!.constant != 0 {
            
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                
                self.recordButtonViewCenterY?.constant = 0.0
                
                self.stopRecordButn?.alpha = 0.0
                
                self.view.layoutIfNeeded()
                
                },
            completion: { (finished) -> Void in
                
                self.recordButtonView?.titleLabel?.text = "开始录音"
                
                // TODO: 进行保存到列表动画
                // TODO: 弹出可供选择的菜单(播放，裁减，发布)
            })
        }
    }
    
    @objc fileprivate func playRecord() {
        
        // 到播放页面
        
        if audioRecorder != nil {
            
            // 停止录音, 才能将音频保存到文件
            audioRecorder?.stop()
            
            var audioFiles: [String] = []
            if lastCombineAudioFilePath != nil {
                audioFiles.append(lastCombineAudioFilePath!)
            }
            if currentRecordFilePath != nil {
                audioFiles.append(currentRecordFilePath!)
            }
            
            if audioFiles.count > 0 {
                let targetCombineFilePath = randomObtainTemporaryAudioFilePath()
                asychCombineAudioFiles(audioFiles, targetCombineAufioFile: targetCombineFilePath, completion: { [weak self] (success) -> Void in
                    
                    let strongSelf = self
                    if strongSelf == nil {
                        return
                    }
                    
                    if success == false {
                        strongSelf!.present(UIAlertController(title: nil, message: "加载音频失败", preferredStyle: UIAlertControllerStyle.alert), animated: true, completion: nil)
                        return
                    }
                    
                    strongSelf!.lastCombineAudioFilePath = targetCombineFilePath
                    strongSelf!.currentRecordFilePath = nil
                    strongSelf!.audioRecorder = nil
                    
                    // 删除组合前的文件
                    let fileMan = FileManager.default
                    for audioFilePath in audioFiles {
                        do {
                            try fileMan.removeItem(atPath: audioFilePath)
                        } catch let error as NSError {
                            print("remove audio file failed, err: \(error.localizedDescription)")
                        }
                    }
                    
                    let playRecordVC = PlayRecordVC(recordFilePath: targetCombineFilePath)
                    playRecordVC.delegate = strongSelf
                    
                    playRecordVC.transitioningDelegate = strongSelf
                    strongSelf!.present(playRecordVC, animated: true, completion: nil)
                })
            }
        }
    }
    
    fileprivate func pauseRecordAudioPlay() {
    
    }
    
    fileprivate func stopRecordAudioPlay() {
        
    }
    
    fileprivate func randomObtainTemporaryAudioFilePath() -> String {
        return NSTemporaryDirectory() + "\(UUID().uuidString).caf"
    }
    
    /**
     组合音频
     
     - parameter audioFiles:             组合的音频文件路径集合
     - parameter targetCombineAufioFile: 组合后的目标存放文件路径
     - parameter completion:             结果 Block
     */
    fileprivate func asychCombineAudioFiles(_ audioFiles: [String], targetCombineAufioFile: String, completion: ((_ success: Bool)->Void)?) {
        
        // combine
        
        let composition = AVMutableComposition()
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID:Int32(kCMPersistentTrackID_Invalid))
        
        var nextClipStartTime = kCMTimeZero
        for audioFile in audioFiles {
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
            completion?(false)
            return
        }
        
        // export
        
        let combindFileURL = URL(fileURLWithPath: targetCombineAufioFile)
        let fileMan = FileManager.default
        if fileMan.fileExists(atPath: targetCombineAufioFile) {
            // remove it
            do {
                try fileMan.removeItem(at: combindFileURL)
            } catch let error as NSError {
                print("remove exist combine file failed, err: \(error.localizedDescription)")
                completion?(false)
                return
            }
        }
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        if exporter == nil {
            completion?(false)
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
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recordStopped()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        recordStopped()
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented.isKind(of: PlayRecordVC.self) {
            return self.presentRecordPlayTransition
        }
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed.isKind(of: PlayRecordVC.self) {
            return self.dismissRecordPlayTransition
        }
        return nil
    }
    
    // MARK: - PlayRecordVCDelegate
    
    func didCutAudio(_ playVC: PlayRecordVC, newAudioFilePath: String) {
        // TODO: 已经剪切完成
    }
}
