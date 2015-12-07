//
//  SECNewReadingViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

/// 录音音频状态
enum SECRecordAudioState {
    case Stopped
    case Recording
    case Paused
}

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
    private var lastCombineAudioFilePath: String?           /** 上次音频合并的文件路径 */
    
    private var selectedWillScissorsScopeRange: NSRange?    /** 选中的将要剪切的区域 */
    
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
        return NSTemporaryDirectory().stringByAppendingString("/\(NSUUID().UUIDString).caf")
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
    
    private func stopRecord() {
        if recordState != .Stopped {
            audioRecorder?.stop()
            
            recordState = .Stopped
            stoppedRecord()
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
        
        alertVC.addAction(UIAlertAction(title: "否", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        alertVC.addAction(UIAlertAction(title: "去发布", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.presentViewController(SECEditReadingViewController(), animated: true, completion: nil)
            })
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
            if recordDuration >= 5 {
                self.mScissorsRecordButton.enabled = true
            }
        }
    }
    
    @objc private func toClosePage() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func toRecordHistory() {
        
    }
    
    @IBAction func clickedScissorsRecordButton(sender: UIButton) {
        if cutPanelHidden {
            // 创建一个新的
            cutPanel = createCutPanel()
            cutPanelHidden(true, animated: false)
            // TODO: 加入其他判定条件
            cutPanelHidden(!cutPanelHidden, animated: true)
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
        
        stopRecord()
    }
    
    // MARK: - SECCutPanelViewDelegate
    
    func clickedBackButtonOnCutPanel(panel: SECCutPanelView) {
        if cutPanelHidden == false {
            cutPanelHidden(true, animated: true)
        }
    }
    
    func clickedPlayRecordButtonOnCutPanel(panel: SECCutPanelView) {
        
    }
    
    func clickedScissorsButtonOnCutPanel(panel: SECCutPanelView) {
    
    }
    
    func willSlideScopeHandleOnCutPanel(panel: SECCutPanelView) {
        
    }
    
    func selectedScopeOnCutPanel(panel: SECCutPanelView, selectedScopeRange: SECCutPanelView.SECRecordRange) {
        
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        stoppedRecord()
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        stoppedRecord()
    }
}
