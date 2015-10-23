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
    case Normal
    case Recording
    case RecordPaused
    case AudioPlaying
}

let LimitMinutesPerRecord = 3 /** 每个录音的限制时长，单位：分钟 */
let StopRecordButtonTopSpacing = CGFloat(24)
let PlayRecordButtonTopSpacing = CGFloat(12)

class NewRecordVC: UIViewController, AVAudioRecorderDelegate, UIViewControllerTransitioningDelegate {
    
    private (set) var recordButtonView: RecordButtonView?
    private var recordButtonViewCenterY: NSLayoutConstraint?
    
    private var stopRecordButn: UIButton?
    private var playRecordButn: UIButton?
    
    private (set) var fakeCDPlaySlider: CDPlaySlider?
    
//    private var audioRecorder: RAQRecorder?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordAudioState = RecordAudioState.Normal

    private var recordProcessDisplayLink: CADisplayLink? /** 进度定时器 */
    
    lazy private var presentRecordPlayTransition:PresentRecordPlayTransition = PresentRecordPlayTransition()
    lazy private var dismissRecordPlayTransition:DismissRecordPlayTransition = DismissRecordPlayTransition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserverForName(PlayRecordVCBackButtonClickNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (note) -> Void in
            if self.presentedViewController != nil && self.presentedViewController!.isKindOfClass(PlayRecordVC) {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        
        self.view.backgroundColor = UIColor(red: 0xf5/255.0, green: 0xee/255.0, blue: 0xee/255.0, alpha: 1)
        
        self.navigationItem.title = "新建读书"
        
        // 设置 recordButtonView
        
        recordButtonView = RecordButtonView(frame: CGRectMake(0, 0, 220, 220))
        self.view.addSubview(recordButtonView!)
        
        recordButtonView?.iconView?.image = UIImage(named: "RecordMicro")?.imageWithRenderingMode(.AlwaysTemplate)
        recordButtonView?.iconView?.tintColor = UIColor.whiteColor()
        recordButtonView?.titleLabel?.text = "开始录音"
        
        recordButtonView?.button?.addTarget(self, action: "recordButtonViewButtonClick", forControlEvents: UIControlEvents.TouchUpInside)
        
        
        recordButtonView?.translatesAutoresizingMaskIntoConstraints = false
        
        recordButtonViewCenterY = NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        self.view.addConstraint(recordButtonViewCenterY!)
        
        self.view.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        recordButtonView!.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: 220))
        
        recordButtonView!.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
        
        // 设置 stopRecordButn
        
        stopRecordButn = UIButton(type: UIButtonType.Custom)
        self.view.addSubview(stopRecordButn!)
        
        stopRecordButn?.alpha = 0
        stopRecordButn?.setTitle("停止录音", forState: UIControlState.Normal)
        stopRecordButn?.backgroundColor = UIColor.clearColor()
        stopRecordButn?.addTarget(self, action: "stopRecord", forControlEvents: UIControlEvents.TouchUpInside)
        stopRecordButtonDisabled(stopRecordButn!.enabled == false)
        
        stopRecordButn?.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: StopRecordButtonTopSpacing))
        
        self.view.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        stopRecordButn!.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 100))
        
        stopRecordButn!.addConstraint(NSLayoutConstraint(item: stopRecordButn!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 38))
        
        
        // 设置 playRecordButn
        
        playRecordButn = UIButton(type: UIButtonType.Custom)
        self.view.addSubview(playRecordButn!)
        
        playRecordButn?.alpha = 0
        playRecordButn?.setTitle("播放", forState: UIControlState.Normal)
        playRecordButn?.backgroundColor = UIColor.clearColor()
        playRecordButn?.addTarget(self, action: "playRecord", forControlEvents: UIControlEvents.TouchUpInside)
        playRecordButn?.setTitleColor(UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1), forState: UIControlState.Normal)
        roundActionButton(playRecordButn, color: playRecordButn!.currentTitleColor)
        
        playRecordButn?.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: stopRecordButn!, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: PlayRecordButtonTopSpacing))
        
        self.view.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        playRecordButn!.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 100))
        
        playRecordButn!.addConstraint(NSLayoutConstraint(item: playRecordButn!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 38))
        
        
        // 设置 fakeCDPlaySlider
        
        fakeCDPlaySlider = CDPlaySlider(frame: CGRectMake(0, 0, 220, 220))
        self.view.addSubview(fakeCDPlaySlider!)
        
        fakeCDPlaySlider?.backgroundColor = UIColor.clearColor()
        fakeCDPlaySlider?.alpha = 0
        fakeCDPlaySlider?.translatesAutoresizingMaskIntoConstraints = false
        
        // scopeGradientView
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: fakeCDPlaySlider!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
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
    
    @objc private func recordButtonViewButtonClick() {
        switch recordAudioState {
        case .Normal:
            // 开始录音
            startRecord()
        case .Recording:
            // 暂停录音
            pauseRecord()
        case .RecordPaused:
            // 继续录音
            startRecord()
        default:
            print("recordAudioState:\(recordAudioState)")
        }
    }
    
    private func activeRecordAudioSession() -> Bool {
        
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
    
    private func stopRecordButtonDisabled(disabled: Bool) {
        
        var tintColor: UIColor?
        if disabled {
            tintColor = UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 0.5)
            stopRecordButn?.setTitleColor(tintColor!, forState: UIControlState.Disabled)
        } else {
            tintColor = UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1)
            stopRecordButn?.setTitleColor(tintColor!, forState: UIControlState.Normal)
        }
        
        roundActionButton(stopRecordButn, color: tintColor!)
    }
    
    private func roundActionButton(button: UIButton?, color: UIColor) {
        button?.layer.borderColor = color.CGColor
        button?.layer.borderWidth = 1.0
        button?.layer.cornerRadius = 8.0
        button?.layer.masksToBounds = true
    }
    
    private func stopRecordButtonTintColorWithState(state: UIControlState) -> UIColor {
        switch state {
        case UIControlState.Highlighted:
            return UIColor(red:0x4f/255.0, green: 0x8c/255.0, blue: 0x93/255.0, alpha: 1)
        case UIControlState.Disabled:
            return UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 0.5)
        default:
            return UIColor(red:0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1)
        }
    }
    
    @objc private func recordProgressing() {
        if audioRecorder != nil && audioRecorder!.recording {
            
            // 改变录音 icon 颜色
            if let iconViewTintColor = recordButtonView?.iconView?.tintColor {
                var alpha: CGFloat = 0
                iconViewTintColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
                if alpha <= 0.5 {
                    alpha = 1
                } else {
                    alpha -= 0.15
                }
                recordButtonView?.iconView?.tintColor = recordButtonView?.iconView?.tintColor.colorWithAlphaComponent(alpha)
            }
            
            // 改变进度
            
            let progress = audioRecorder!.currentTime/NSTimeInterval(LimitMinutesPerRecord*60)
            recordButtonView?.progressView?.progress = CGFloat(progress)
            
            recordButtonView?.progressView?.progressLabel?.text = "\(Int(audioRecorder!.currentTime))"
        }
    }
    
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        recordStopped()
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        recordStopped()
    }
    
    private func startRecord() {
        if recordAudioState != .Recording {
            
            if activeRecordAudioSession() == false {
                print("Fail to activeRecordAudioSession.")
                return
            }
            
            if audioRecorder == nil {
//                audioRecorder = RAQRecorder()
//                audioRecorder?.audioFilePath = NSTemporaryDirectory().stringByAppendingString("/\(NSUUID().UUIDString).caf")
//                
                let settings = [AVFormatIDKey:NSNumber(unsignedInt: kAudioFormatALaw), AVSampleRateKey:NSNumber(int: 44100), AVNumberOfChannelsKey:NSNumber(int:1)]
                
                do {
                    audioRecorder = try AVAudioRecorder(URL: NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingString("/\(NSUUID().UUIDString).caf")), settings: settings)
                    
                    weak var weakSelf = self
                    audioRecorder?.delegate = weakSelf
                    audioRecorder?.prepareToRecord()
                    
                    audioRecorder?.recordForDuration(NSTimeInterval(LimitMinutesPerRecord * 60))
                    
                } catch let error as NSError {
                    print("error: \(error)")
                }
                
            } else {
                audioRecorder?.record()
            }
            
            recordAudioState = .Recording
            recordStarted()
        }
    }
    
    private func recordStarted() {
        // 启动进度定时器
        
        recordProcessDisplayLink?.invalidate()
        
        recordProcessDisplayLink = CADisplayLink(target: self, selector: "recordProgressing")
        recordProcessDisplayLink?.frameInterval = 30
        recordProcessDisplayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        if recordButtonViewCenterY != nil && recordButtonViewCenterY!.constant == 0 {
           
            if stopRecordButn != nil {
                self.view.layoutIfNeeded()
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    
                    self.recordButtonViewCenterY?.constant = -(CGRectGetHeight(self.stopRecordButn!.bounds) + StopRecordButtonTopSpacing)/2
                    
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
    
    private func pauseRecord() {
        
        if recordAudioState == .Recording {
            audioRecorder?.pause()
            recordAudioState = .RecordPaused
            recordPaused()
        }
    }
    
    private func recordPaused() {
        recordProcessDisplayLink?.invalidate()
//        recordButtonView?.titleLabel?.text = "点击继续"
        recordButtonView?.iconView?.tintColor = recordButtonView?.iconView?.tintColor.colorWithAlphaComponent(1)
        
        // 显示出播放按钮
        if self.playRecordButn?.alpha == 0 {
            
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                
                self.recordButtonViewCenterY?.constant = -(CGRectGetHeight(self.stopRecordButn!.bounds) + StopRecordButtonTopSpacing + CGRectGetHeight(self.playRecordButn!.bounds) + PlayRecordButtonTopSpacing)/2
                
                self.playRecordButn?.alpha = 1.0
                
                self.view.layoutIfNeeded()
                
                },
                completion: { (finished) -> Void in
                    self.recordButtonView?.titleLabel?.text = "点击继续"
            })
            
        }
    }
    
    @objc private func stopRecord() {
        
        if recordAudioState == .Recording || recordAudioState == .RecordPaused {
            audioRecorder?.stop()
            recordAudioState = .Normal
            recordStopped()
        }
    }
    
    private func recordStopped() {
        recordProcessDisplayLink?.invalidate()
        
        self.recordButtonView?.progressView?.progress = 0.0
        recordButtonView?.iconView?.tintColor = recordButtonView?.iconView?.tintColor.colorWithAlphaComponent(1)
        
        if recordButtonViewCenterY != nil && recordButtonViewCenterY!.constant != 0 {
            
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                
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
    
    @objc private func playRecord() {
        // TODO: 到播放页面
        
        if audioRecorder != nil {
            let playRecordVC = PlayRecordVC(recordFilePath: audioRecorder!.url.absoluteString)
            playRecordVC.transitioningDelegate = self
            self.presentViewController(playRecordVC, animated: true, completion: nil)
        }
    }
    
    private func pauseRecordAudioPlay() {
    
    }
    
    private func stopRecordAudioPlay() {
        
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented.isKindOfClass(PlayRecordVC) {
            return self.presentRecordPlayTransition
        }
        return nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed.isKindOfClass(PlayRecordVC) {
            return self.dismissRecordPlayTransition
        }
        return nil
    }
}
