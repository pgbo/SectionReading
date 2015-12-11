//
//  SECNewReadingViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation
import SVProgressHUD

/// 录音音频状态
enum SECRecordAudioState {
    case Stopped
    case Recording
    case Paused
}

/// 播放音频状态
enum SECPlayAudioState {
    case Stopped
    case Playing
    case Paused
}

let MininumRecordAudioSecondsToScissors = NSTimeInterval(3)

/**
 *  建立新读书记录页面
 */
class SECNewReadingViewController: UIViewController, SECCutPanelViewDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var mRecordDurationLabel: UILabel!
    @IBOutlet weak var mFirstWheel: UIImageView!
    @IBOutlet weak var mSecondWheel: UIImageView!
    @IBOutlet weak var mStopRecordButton: UIButton!
    @IBOutlet weak var mResumeRecordButton: UIButton!
    @IBOutlet weak var mScissorsRecordButton: UIButton!
    
    private lazy var mCancelBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.Plain, target: self, action: "toClosePage")
        return item
    }()
    
    private lazy var mRecordHistoryBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "列表", style: UIBarButtonItemStyle.Plain, target: self, action: "toRecordHistory")
        return item
    }()
    
    private var cutPanel: SECCutPanelView?
    
    private var cutPanelLeading: NSLayoutConstraint?
    private var cutPanelTrailing: NSLayoutConstraint?
    private var cutPanelWidth: NSLayoutConstraint?
    private var cutPanelHidden = true
    
    private var recordState: SECRecordAudioState = .Stopped
    private var recordDuration: NSTimeInterval = 0.0
    private var wheelsLastTimeAngle: CGFloat = 0
    private var recordTimming: NSTimer?
    
    private var audioRecorder: AVAudioRecorder?             /** 录音器 */
    private var currentRecordFilePath: String?              /** 当前录音文件路径 */
    
    /** 选中的将要剪切的区域 */
    private var selectedWillScissorsScopeRange: SECRecordRange?
    
    private var audioPlayer: AVAudioPlayer?                 /** 播放器 */
    private var playState: SECPlayAudioState = .Stopped
    private var playTimming: NSTimer?
    
    /** 录音文件路径片段集合 */
    private var audioRecordFilePathSnippets: [String] = []
    private var audioCombiner: SECReadingRecordCombiner?
    private var audioCropper: SECReadingRecordCropper?
    
    convenience init() {
        self.init(nibName:"SECNewReadingViewController", bundle:nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(red: 0xf2/255.0, green: 0xf2/255.0, blue: 0xf2/255.0, alpha: 1)
        
        self.navigationItem.title = "新建读书"
        self.navigationItem.leftBarButtonItem = self.mCancelBarItem
        self.navigationItem.rightBarButtonItem = self.mRecordHistoryBarItem
        
        updateResumeRecordButtonImageForRecordState(recordState)
        self.mStopRecordButton.enabled = false
        self.mScissorsRecordButton.enabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func createCutPanel() -> SECCutPanelView {
        // 创建 cutPanel
        let cutPanel = SECCutPanelView.instanceFromNib()
        self.view.addSubview(cutPanel)
        
        cutPanel.defaultSelectedRange = SECRecordRange(location: 0, length: 1)
        cutPanel.delegate = self
        cutPanel.translatesAutoresizingMaskIntoConstraints = false
        let views = ["cutPanel": cutPanel]
        
        self.cutPanelLeading = NSLayoutConstraint(item: cutPanel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        self.view.addConstraint(self.cutPanelLeading!)
        self.cutPanelLeading?.identifier = "$_cutPanelLeading"
        
        self.cutPanelTrailing = NSLayoutConstraint(item: cutPanel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        self.view.addConstraint(self.cutPanelTrailing!)
        self.cutPanelTrailing?.identifier = "$_cutPanelTrailing"
        
        self.cutPanelWidth = NSLayoutConstraint(item: cutPanel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: 0)
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[cutPanel(180)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        
        return cutPanel
    }
    
    private func updateResumeRecordButtonImageForRecordState(state: SECRecordAudioState) {
        switch state {
        case .Stopped, .Paused:
            let buttonImage = UIImage(named: "ResumeRecordButton")
            let buttonImageHL = UIImage(named: "ResumeRecordButtonHL")
            
            mResumeRecordButton.setImage(buttonImage, forState: UIControlState.Normal)
            mResumeRecordButton.setImage(buttonImageHL, forState: UIControlState.Highlighted)
        case .Recording:
            let buttonImage = UIImage(named: "PauseRecordButton")
            let buttonImageHL = UIImage(named: "PauseRecordButtonHL")
            
            mResumeRecordButton.setImage(buttonImage, forState: UIControlState.Normal)
            mResumeRecordButton.setImage(buttonImageHL, forState: UIControlState.Highlighted)
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
    
    private func randomObtainTemporaryAudioFilePath() -> String {
        return NSTemporaryDirectory().stringByAppendingString("\(NSUUID().UUIDString).caf")
    }
    
    private func resumeRecord() {
        if recordState != .Recording {
            
            if activeRecordAudioSession() == false {
                print("Fail to activeRecordAudioSession.")
                return
            }
            
            if audioRecorder == nil {
                
                let settings = [AVFormatIDKey:NSNumber(unsignedInt: kAudioFormatALaw), AVSampleRateKey:NSNumber(int: 44100), AVNumberOfChannelsKey:NSNumber(int:1)]
                
                do {
                    let audioFilePath = randomObtainTemporaryAudioFilePath()
                    audioRecorder = try AVAudioRecorder(URL: NSURL(fileURLWithPath: audioFilePath), settings: settings)
                    
                    currentRecordFilePath = audioFilePath
                    
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
            
            recordState = .Recording
            resumedRecord()
        }
    }
    
    private func pauseRercord() {
        if recordState == .Recording {
            audioRecorder?.pause()
            
            recordState = .Paused
            pausedRecord()
        }
    }
    
    private func stopRecordWithCompletion(completion: (Void -> ())?) {
        if recordState != .Stopped {
            audioRecorder?.stop()
            
            recordState = .Stopped
            if completion != nil {
                completion!()
            }
        }
    }
    
    private func resumedRecord() {
        
        updateResumeRecordButtonImageForRecordState(.Recording)
        
        if self.mStopRecordButton.enabled == false {
            self.mStopRecordButton.enabled = true
        }
        
        // 恢复计时并转动轮子
        recordTimming = NSTimer(timeInterval: 0.1, target: self, selector: "firedRecordTimming", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(recordTimming!, forMode: NSRunLoopCommonModes)
    }
    
    private func pausedRecord() {
        
        updateResumeRecordButtonImageForRecordState(.Paused)
        
        // 停止计时和转动轮子
        recordTimming?.invalidate()
    }
    
    private func stoppedRecord() {
        
        updateResumeRecordButtonImageForRecordState(.Stopped)
        
        // 停止计时和转动轮子
        recordTimming?.invalidate()
        
        // TODO: 保存录音到本地
        
        // 弹出发布提示框
        let alertVC = UIAlertController(title: nil, message: "您录制了一段读书录音，是否现在发布？", preferredStyle: UIAlertControllerStyle.Alert)
        
        alertVC.addAction(UIAlertAction(title: "否", style: UIAlertActionStyle.Cancel, handler: nil))
        
        alertVC.addAction(UIAlertAction(title: "去发布", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.presentViewController(SECEditReadingViewController(), animated: true, completion: nil)
        }))
        
        self.presentViewController(alertVC, animated: true, completion: nil)
    }
    
    private func cutPanelHidden(hidden: Bool, animated: Bool) {
        
        let blockFunc = { [weak self] (hidden: Bool) -> Void in
            if let strongSelf = self {
                if hidden {
                    let viewWidth = CGRectGetWidth(strongSelf.view.bounds)
                    strongSelf.cutPanelLeading?.constant = viewWidth
                    
                    if strongSelf.cutPanelTrailing != nil {
                        strongSelf.view.removeConstraint(strongSelf.cutPanelTrailing!)
                    }
                    
                    if strongSelf.cutPanelWidth != nil {
                        strongSelf.cutPanelWidth!.constant = viewWidth
                        strongSelf.cutPanel?.addConstraint(strongSelf.cutPanelWidth!)
                    }
                } else {
                    strongSelf.cutPanelLeading?.constant = 0
                    
                    if strongSelf.cutPanelTrailing != nil {
                        strongSelf.view.addConstraint(strongSelf.cutPanelTrailing!)
                    }
                    
                    if strongSelf.cutPanelWidth != nil {
                        strongSelf.cutPanel?.removeConstraint(strongSelf.cutPanelWidth!)
                    }
                }
            }
        }
        
        if animated {
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.4, animations: { [weak self] () -> Void in
                if let strongSelf = self {
                    blockFunc(hidden)
                    strongSelf.view.layoutIfNeeded()
                }
                }, completion: {[weak self] (finished: Bool) -> Void in
                    if let strongSelf = self {
                        strongSelf.cutPanelHidden = hidden
                    }
                })
        } else {
            blockFunc(hidden)
            self.cutPanelHidden = hidden
        }
    }
    
    @objc private func firedRecordTimming() {
        
        if recordState == .Recording {
            
            // 计时
            recordDuration += 0.1
            
            // 更新计时 lebal
            mRecordDurationLabel.text = SECHelper.createFormatTextForRecordDuration(recordDuration)
            
            // 转动轮子
            let newWheelAngle = wheelsLastTimeAngle + CGFloat((2.0*M_PI)/4.0)
            let newTransform = CGAffineTransformMakeRotation(newWheelAngle)
            self.mFirstWheel.transform = newTransform
            self.mSecondWheel.transform = newTransform
            
            wheelsLastTimeAngle = newWheelAngle
            
            // 恢复剪切按钮状态
            if recordDuration > MininumRecordAudioSecondsToScissors {
                self.mScissorsRecordButton.enabled = true
            }
        }
    }
    
    @objc private func firedPlayTimming() {
        
        if audioPlayer != nil && playState == .Playing {
            
            var selectedRecordRange = selectedWillScissorsScopeRange
            if selectedRecordRange == nil {
                selectedRecordRange = cutPanel!.defaultSelectedRange
            }
            
            let audioDuration = audioPlayer!.duration
            
            let selectScopeAudioDuration = NSTimeInterval(selectedRecordRange!.length) * audioDuration
            let playerCurrentTimeAtSelectScope = audioPlayer!.currentTime - NSTimeInterval(selectedRecordRange!.location) * audioDuration
            
            var playProgress = CGFloat((playerCurrentTimeAtSelectScope)/selectScopeAudioDuration)
            if playProgress > 1 {
                playProgress = 1
            }
            cutPanel?.playProgress = playProgress
        }
    }
    
    @objc private func toClosePage() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func toRecordHistory() {
        
        // TODO: 到列表页面
    }
    
    @IBAction func clickedScissorsRecordButton(sender: UIButton) {
        
        if cutPanelHidden {
            
            let toShowCutPanelBlock = { (audioFilePath: String) -> Void in
                
                do {
                    
                    // 重置播放器
                    self.audioPlayer?.stop()
                    self.playState = .Stopped
                    
                    // 创建新的播放器
                    try self.audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: audioFilePath))
                    self.audioPlayer?.delegate = self
                    
                    self.audioPlayer?.prepareToPlay()
                    
                } catch let error as NSError {
                    
                    print("Fail to init AVAudioPlayer, error:\(error.localizedDescription)")
                    
                    let alert = UIAlertController(title: nil, message: "出故障了, 请联系 App 运营人员", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    return
                }
                
                // 创建一个新的剪切视图
                self.cutPanel = self.createCutPanel()
                self.cutPanelHidden(true, animated: false)
                self.cutPanelHidden(false, animated: true)
            }
            
            
            
            let lastRecordFilePath = self.currentRecordFilePath
            let hasNewRecord = lastRecordFilePath != nil
            
            // 没有新的录音
            if hasNewRecord == false && audioRecordFilePathSnippets.count == 1 {
                toShowCutPanelBlock(audioRecordFilePathSnippets.first!)
                return
            }
            
            // 停止录音
            audioRecorder?.stop()
            recordState = .Stopped
            recordTimming?.invalidate()
            updateResumeRecordButtonImageForRecordState(.Stopped)
            self.currentRecordFilePath = nil
            
            // 添加到录音片段
            if lastRecordFilePath != nil {
                audioRecordFilePathSnippets.append(lastRecordFilePath!)
            }
            
            // 合成音频
            let combineAudioFilePath = randomObtainTemporaryAudioFilePath()
            audioCombiner = SECReadingRecordCombiner(sourceAudioFilePaths: audioRecordFilePathSnippets, destinationFilePath: combineAudioFilePath)
            
            // 开始模态等待合成
            SVProgressHUD.showWithStatus("")
            audioCombiner!.combineWithCompletion({ (success) -> Void in
                
                if success == false {
                    SVProgressHUD.showErrorWithStatus("出故障了, 请联系 App 运营人员")
                    return
                }
                
                // 取消模态等待
                SVProgressHUD.dismiss()
                
                // 合成文件设置成为唯一录音片段
                self.audioRecordFilePathSnippets = [combineAudioFilePath]
                
                toShowCutPanelBlock(combineAudioFilePath)
            })
        }
    }
    
    @IBAction func clickedResumeRecordButton(sender: UIButton) {
        
        switch recordState {
        case .Stopped, .Paused:
            
            resumeRecord()
            
        case .Recording:
            
            pauseRercord()
        }
    }
    
    @IBAction func clickedStopRecordButton(sender: UIButton) {
        
        stopRecordWithCompletion { [weak self] () -> () in
            if let strongSelf = self {
                strongSelf.stoppedRecord()
            }
        }
    }
    
    // MARK: - SECCutPanelViewDelegate
    
    func clickedBackButtonOnCutPanel(panel: SECCutPanelView) {
        
        if cutPanelHidden == false {
            cutPanelHidden(true, animated: true)
        }
    }
    
    func clickedPlayRecordButtonOnCutPanel(panel: SECCutPanelView) {
        
        if playState == .Playing {
            // 暂停播放
            audioPlayer?.pause()
            playState = .Paused
            
            // 关闭播放定时器
            playTimming?.invalidate()
        
            cutPanel?.isPlaying = false
            
        } else {
            
            let selectedWillScissorsScopeRange = self.selectedWillScissorsScopeRange
            if selectedWillScissorsScopeRange != nil && audioPlayer != nil {
                audioPlayer!.currentTime = NSTimeInterval(selectedWillScissorsScopeRange!.location) * audioPlayer!.duration
                audioPlayer!.prepareToPlay()
            }
            
            // 开始播放
            audioPlayer?.play()
            playState = .Playing
            
            // 开启播放定时器
            playTimming?.invalidate()
            playTimming = NSTimer(timeInterval: 0.5, target: self, selector: "firedPlayTimming", userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(playTimming!, forMode: NSRunLoopCommonModes)
            
            cutPanel?.isPlaying = true
        }
    }
    
    func clickedScissorsButtonOnCutPanel(panel: SECCutPanelView) {
        
        // 弹出剪切提示
        let alert = UIAlertController(title: "剪辑", message: "确定剪掉选中的录音吗？", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "确认", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            let selectedRange = self.selectedWillScissorsScopeRange
            if selectedRange == nil {
                self.cutPanelHidden(true, animated: true)
                return
            }
            
            // 没有做任何裁切
            if selectedRange!.length == 0 {
                self.cutPanelHidden(true, animated: true)
                return
            }
            
            let playAudioFilePath = self.audioRecordFilePathSnippets.first
    
            if playAudioFilePath == nil {
                self.cutPanelHidden(true, animated: true)
                return
            }
    
            
            // 重置播放器
            self.audioPlayer?.stop()
            self.playState = .Stopped
            
            let destinationCroppedFilePath = self.randomObtainTemporaryAudioFilePath()
            self.audioCropper = SECReadingRecordCropper(sourceRecordFilePath: playAudioFilePath!, cropRange: selectedRange!, destinationCroppedFilePath: destinationCroppedFilePath)
            
            // 开始裁切
            SVProgressHUD.showWithStatus("")
            self.audioCropper!.cropWithCompletion({ (success) -> Void in
                
                // 隐藏裁剪框
                self.cutPanelHidden(true, animated: true)
                
                if success == false {
                    SVProgressHUD.showErrorWithStatus("出故障了, 请联系 App 运营人员")
                    return
                }
                
                SVProgressHUD.dismiss()
                
                // 设置裁切音频为唯一录音片段
                
                self.audioRecordFilePathSnippets = [destinationCroppedFilePath]
                
                // 置空 selectedWillScissorsScopeRange
                self.selectedWillScissorsScopeRange = nil
                
                // 更新录音时间
                let croppedAudioDuration = self.recordDuration * NSTimeInterval(1.0 - selectedRange!.length)
                self.recordDuration = croppedAudioDuration
                self.mRecordDurationLabel.text = SECHelper.createFormatTextForRecordDuration(croppedAudioDuration)
                if croppedAudioDuration <= MininumRecordAudioSecondsToScissors {
                    self.mScissorsRecordButton.enabled = false
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler:nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func willSlideScopeHandleOnCutPanel(panel: SECCutPanelView) {
        
        panel.isPlaying = false
        panel.playProgress = 0
        
        if playState == .Playing {
            audioPlayer?.pause()
            playState = .Paused
        }
    }
    
    func selectedScopeOnCutPanel(panel: SECCutPanelView, selectedScopeRange: SECRecordRange) {
        
        self.selectedWillScissorsScopeRange = selectedScopeRange
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {

    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        
        recordState = .Stopped
        stoppedRecord()
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        
        playState = .Stopped
        cutPanel?.isPlaying = false
        playTimming?.invalidate()
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        
        playState = .Stopped
        cutPanel?.isPlaying = false
        playTimming?.invalidate()
    }
}
