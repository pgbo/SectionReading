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
    case stopped
    case recording
    case paused
}

/// 播放音频状态
enum SECPlayAudioState {
    case stopped
    case playing
    case paused
}

let MininumRecordAudioSecondsToScissors = TimeInterval(3)

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
    
    fileprivate lazy var mCancelBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SECNewReadingViewController.toClosePage))
        return item
    }()
    
    fileprivate lazy var mRecordHistoryBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "列表", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SECNewReadingViewController.toRecordHistory))
        return item
    }()
    
    fileprivate var cutPanel: SECCutPanelView?
    
    fileprivate var cutPanelLeading: NSLayoutConstraint?
    fileprivate var cutPanelTrailing: NSLayoutConstraint?
    fileprivate var cutPanelWidth: NSLayoutConstraint?
    fileprivate var cutPanelHidden = true
    
    fileprivate var recordState: SECRecordAudioState = .stopped
    fileprivate var recordDuration: TimeInterval = 0.0
    fileprivate var wheelsLastTimeAngle: CGFloat = 0
    fileprivate var recordTimming: Timer?
    
    fileprivate var audioRecorder: AVAudioRecorder?             /** 录音器 */
    fileprivate var currentRecordFilePath: String?              /** 当前录音文件路径 */
    
    /** 选中的将要剪切的区域 */
    fileprivate var selectedWillScissorsScopeRange: SECRecordRange?
    
    fileprivate var audioPlayer: AVAudioPlayer?                 /** 播放器 */
    fileprivate var playState: SECPlayAudioState = .stopped
    fileprivate var playTimming: Timer?
    
    /** 录音文件路径片段集合 */
    fileprivate var audioRecordFilePathSnippets: [String] = []
    fileprivate var audioCombiner: SECReadingRecordCombiner?
    fileprivate var audioCropper: SECReadingRecordCropper?

    class func instanceFromSB() -> SECNewReadingViewController {
        return UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewController(withIdentifier: "SECNewReadingViewController") as! SECNewReadingViewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:, bundle:) has not been implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "新建读书"
        self.navigationItem.leftBarButtonItem = self.mCancelBarItem
        self.navigationItem.rightBarButtonItem = self.mRecordHistoryBarItem
        
        updateResumeRecordButtonImageForRecordState(recordState)
        self.mStopRecordButton.isEnabled = false
        self.mScissorsRecordButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func createCutPanel() -> SECCutPanelView {
        // 创建 cutPanel
        let cutPanel = SECCutPanelView.instanceFromNib()
        self.view.addSubview(cutPanel)
        
        cutPanel.defaultSelectedRange = SECRecordRange(location: 0, length: 1)
        cutPanel.delegate = self
        cutPanel.translatesAutoresizingMaskIntoConstraints = false
        let views = ["cutPanel": cutPanel]
        
        self.cutPanelLeading = NSLayoutConstraint(item: cutPanel, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0)
        self.view.addConstraint(self.cutPanelLeading!)
        self.cutPanelLeading?.identifier = "$_cutPanelLeading"
        
        self.cutPanelTrailing = NSLayoutConstraint(item: cutPanel, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0)
        self.view.addConstraint(self.cutPanelTrailing!)
        self.cutPanelTrailing?.identifier = "$_cutPanelTrailing"
        
        self.cutPanelWidth = NSLayoutConstraint(item: cutPanel, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: 0)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[cutPanel(180)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        
        return cutPanel
    }
    
    fileprivate func updateResumeRecordButtonImageForRecordState(_ state: SECRecordAudioState) {
        switch state {
        case .stopped, .paused:
            let buttonImage = UIImage(named: "ResumeRecordButton")
            let buttonImageHL = UIImage(named: "ResumeRecordButtonHL")
            
            mResumeRecordButton.setImage(buttonImage, for: UIControlState())
            mResumeRecordButton.setImage(buttonImageHL, for: UIControlState.highlighted)
        case .recording:
            let buttonImage = UIImage(named: "PauseRecordButton")
            let buttonImageHL = UIImage(named: "PauseRecordButtonHL")
            
            mResumeRecordButton.setImage(buttonImage, for: UIControlState())
            mResumeRecordButton.setImage(buttonImageHL, for: UIControlState.highlighted)
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
    
    fileprivate func randomObtainTemporaryAudioFilePath() -> String {
        return NSTemporaryDirectory() + "\(UUID().uuidString).caf"
    }
    
    fileprivate func randomReadingRecordCompletedFilePath() -> String? {
        let readingRecordDir = SECHelper.readingRecordStoreDirectory()
        return (readingRecordDir)! + "\(UUID().uuidString).caf"
    }
    
    fileprivate func resumeRecord() {
        
        if recordState == .recording {
            return
        }
        
        if activeRecordAudioSession() == false {
            print("Fail to activeRecordAudioSession.")
            return
        }
        
        if recordState == .paused {
            audioRecorder?.record()
            
        } else if recordState == .stopped {
        
            let settings = [AVFormatIDKey:NSNumber(value: kAudioFormatALaw as UInt32), AVSampleRateKey:NSNumber(value: 44100 as Int32), AVNumberOfChannelsKey:NSNumber(value: 1 as Int32)]
            
            do {
                let audioFilePath = randomObtainTemporaryAudioFilePath()
                audioRecorder = try AVAudioRecorder(url: URL(fileURLWithPath: audioFilePath), settings: settings)
                
                currentRecordFilePath = audioFilePath
                
                weak var weakSelf = self
                audioRecorder?.delegate = weakSelf
                
                audioRecorder?.prepareToRecord()
                audioRecorder?.record()
                
            } catch let error as NSError {
                print("error: \(error)")
                return
            }
        }
        
        recordState = .recording
        resumedRecord()
    }
    
    fileprivate func pauseRercord() {
        if recordState == .recording {
            audioRecorder?.pause()
            
            recordState = .paused
            pausedRecord()
        }
    }
    
    fileprivate func resumedRecord() {
        
        updateResumeRecordButtonImageForRecordState(.recording)
        
        if self.mStopRecordButton.isEnabled == false {
            self.mStopRecordButton.isEnabled = true
        }
        
        // 恢复计时并转动轮子
        recordTimming = Timer(timeInterval: 0.1, target: self, selector: #selector(SECNewReadingViewController.firedRecordTimming), userInfo: nil, repeats: true)
        RunLoop.main.add(recordTimming!, forMode: RunLoopMode.commonModes)
    }
    
    fileprivate func pausedRecord() {
        
        updateResumeRecordButtonImageForRecordState(.paused)
        
        // 停止计时和转动轮子
        recordTimming?.invalidate()
    }
    
    fileprivate func stoppedRecord() {
        
        recordTimming?.invalidate()
        updateResumeRecordButtonImageForRecordState(.stopped)
        
        let recordSnippetCount = audioRecordFilePathSnippets.count
        
        if recordSnippetCount == 0 {
            return
        } else if recordSnippetCount == 1 {
            
            let onlyRecordAudioSnippetFilePath = audioRecordFilePathSnippets.first!
            
            // 保存文件
            let recordCompletedFilePath = self.moveIntoRecordAudioIntoCompletedRecordFileFromTempFilePath(onlyRecordAudioSnippetFilePath)
            if recordCompletedFilePath != nil {
                
                self.audioRecordFilePathSnippets = [recordCompletedFilePath!]
                // 弹出提示
                self.showPublishAlertViewForReadingRecordFilePath(recordCompletedFilePath!)
            } else {
                // 提示失败
                SVProgressHUD.showError(withStatus: "出故障了, 请联系 App 运营人员")
            }
            
            return
        }
        
        // 合成音频
        let combineAudioFilePath = randomObtainTemporaryAudioFilePath()
        audioCombiner = SECReadingRecordCombiner(sourceAudioFilePaths: audioRecordFilePathSnippets, destinationFilePath: combineAudioFilePath)
        
        // 开始模态等待合成
        SVProgressHUD.show(withStatus: "")
        audioCombiner!.combineWithCompletion({ (success) -> Void in
            
            if success == false {
                SVProgressHUD.showError(withStatus: "出故障了, 请联系 App 运营人员")
                return
            }
            
            // 删除原来的录音片段
            let fileMan = FileManager.default
            for snippetFilePath in self.audioRecordFilePathSnippets {
                if snippetFilePath != combineAudioFilePath {
                    do {
                        try fileMan.removeItem(atPath: snippetFilePath)
                    } catch let error as NSError {
                        print("Fail to remove file item:\(snippetFilePath), error:\(error.localizedDescription)")
                    }
                }
            }
            
            // 取消模态等待
            SVProgressHUD.dismiss()
            
            // 合成文件设置成为唯一录音片段
            self.audioRecordFilePathSnippets = [combineAudioFilePath]
            
            // 保存文件
            let recordCompletedFilePath = self.moveIntoRecordAudioIntoCompletedRecordFileFromTempFilePath(combineAudioFilePath)
            if recordCompletedFilePath != nil {
                
                self.audioRecordFilePathSnippets = [recordCompletedFilePath!]
                // 弹出提示
                self.showPublishAlertViewForReadingRecordFilePath(recordCompletedFilePath!)
            } else {
                // 提示失败
                SVProgressHUD.showError(withStatus: "出故障了, 请联系 App 运营人员")
            }
        })
    }
    
    /**
     * 弹出马上发布的提示
     */
    fileprivate func showPublishAlertViewForReadingRecordFilePath(_ filePath: String) {
        
        // 弹出发布提示框
        let alertVC = UIAlertController(title: nil, message: "您录制了一段读书录音，是否现在发布？", preferredStyle: UIAlertControllerStyle.alert)
        
        alertVC.addAction(UIAlertAction(title: "否", style: UIAlertActionStyle.cancel, handler: nil))
        
        alertVC.addAction(UIAlertAction(title: "去发布", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.navigationController?.show(SECEditNewReadingViewController.instanceFromSB(filePath), sender: nil)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    /**
     *  将临时录音文件转移到最终的录音文件
     *
     *  @return   是否成功
     */
    fileprivate func moveIntoRecordAudioIntoCompletedRecordFileFromTempFilePath(_ tmpFilePath: String) -> String? {
        
        let recordCompletedFilePath = self.randomReadingRecordCompletedFilePath()
        if recordCompletedFilePath != nil {

            do {
                try FileManager.default.moveItem(atPath: tmpFilePath, toPath: recordCompletedFilePath!)
            } catch (let error as NSError) {
                print("Fail move file, error: \(error.localizedDescription)")
                return nil
            }
        }
        
        return recordCompletedFilePath
    }
    
    fileprivate func cutPanelHidden(_ hidden: Bool, animated: Bool) {
        
        let blockFunc = { [weak self] (hidden: Bool) -> Void in
            if let strongSelf = self {
                if hidden {
                    let viewWidth = strongSelf.view.bounds.width
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
            UIView.animate(withDuration: 0.4, animations: { [weak self] () -> Void in
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
    
    @objc fileprivate func firedRecordTimming() {
        
        if recordState == .recording {
            
            // 计时
            recordDuration += 0.1
            
            // 更新计时 lebal
            mRecordDurationLabel.text = SECHelper.createFormatTextForRecordDuration(recordDuration)
            
            // 转动轮子
            let newWheelAngle = wheelsLastTimeAngle + CGFloat((2.0*M_PI)/4.0)
            let newTransform = CGAffineTransform(rotationAngle: newWheelAngle)
            self.mFirstWheel.transform = newTransform
            self.mSecondWheel.transform = newTransform
            
            wheelsLastTimeAngle = newWheelAngle
            
            // 恢复剪切按钮状态
            if recordDuration > MininumRecordAudioSecondsToScissors {
                self.mScissorsRecordButton.isEnabled = true
            }
        }
    }
    
    @objc fileprivate func firedPlayTimming() {
        
        if audioPlayer != nil {
            var selectedRecordRange = selectedWillScissorsScopeRange
            if selectedRecordRange == nil {
                selectedRecordRange = cutPanel!.defaultSelectedRange
            }
            
            let audioDuration = audioPlayer!.duration
            
            let selectScopeAudioDuration = TimeInterval(selectedRecordRange!.length) * audioDuration
            let playerCurrentTimeAtSelectScope = audioPlayer!.currentTime - TimeInterval(selectedRecordRange!.location) * audioDuration
            
            var playProgress = CGFloat((playerCurrentTimeAtSelectScope)/selectScopeAudioDuration)
            if playProgress > 1 {
                playProgress = 1
            }
            cutPanel?.playProgress = playProgress
        }
    }
    
    @objc fileprivate func toClosePage() {
        // 弹出退出确认提示
        let alert = UIAlertController(title: nil, message: "确定要退出本次读书录音吗?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "退出", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func toRecordHistory() {
        
        // 暂停录音
        pauseRercord()
        
        // 暂停播放
        audioPlayer?.pause()
        playState = .paused
        
        // 关闭播放定时器
        playTimming?.invalidate()
        
        cutPanel?.isPlaying = false
        
        self.show(SECAudioFileListViewController.instanceFromSB(), sender: nil)
    }
    
    @IBAction func clickedScissorsRecordButton(_ sender: UIButton) {
        
        if cutPanelHidden {
            
            let toShowCutPanelBlock = { (audioFilePath: String) -> Void in
                
                do {
                    
                    // 重置播放器
                    self.audioPlayer?.stop()
                    self.playState = .stopped
                    
                    // 创建新的播放器
                    try self.audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioFilePath))
                    self.audioPlayer?.delegate = self
                    
                    self.audioPlayer?.prepareToPlay()
                    
                } catch let error as NSError {
                    
                    print("Fail to init AVAudioPlayer, error:\(error.localizedDescription)")
                    
                    let alert = UIAlertController(title: nil, message: "出故障了, 请联系 App 运营人员", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
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
            recordState = .stopped
            recordTimming?.invalidate()
            updateResumeRecordButtonImageForRecordState(.stopped)
            self.currentRecordFilePath = nil
            
            // 添加到录音片段
            if lastRecordFilePath != nil {
                audioRecordFilePathSnippets.append(lastRecordFilePath!)
            }
            
            // 合成音频
            let combineAudioFilePath = randomObtainTemporaryAudioFilePath()
            audioCombiner = SECReadingRecordCombiner(sourceAudioFilePaths: audioRecordFilePathSnippets, destinationFilePath: combineAudioFilePath)
            
            // 开始模态等待合成
            SVProgressHUD.show(withStatus: "")
            audioCombiner!.combineWithCompletion({ (success) -> Void in
                
                if success == false {
                    SVProgressHUD.showError(withStatus: "出故障了, 请联系 App 运营人员")
                    return
                }
                
                // 删除原来的录音片段
                let fileMan = FileManager.default
                for snippetFilePath in self.audioRecordFilePathSnippets {
                    if snippetFilePath != combineAudioFilePath {
                        do {
                            try fileMan.removeItem(atPath: snippetFilePath)
                        } catch let error as NSError {
                            print("Fail to remove file item:\(snippetFilePath), error:\(error.localizedDescription)")
                        }
                    }
                }
                
                // 取消模态等待
                SVProgressHUD.dismiss()
                
                // 合成文件设置成为唯一录音片段
                self.audioRecordFilePathSnippets = [combineAudioFilePath]
                
                toShowCutPanelBlock(combineAudioFilePath)
            })
        }
    }
    
    @IBAction func clickedResumeRecordButton(_ sender: UIButton) {
        
        switch recordState {
        case .stopped, .paused:
            
            resumeRecord()
            
        case .recording:
            
            pauseRercord()
        }
    }
    
    @IBAction func clickedStopRecordButton(_ sender: UIButton) {
        
        if recordState != .stopped {
            
            // 停止录音
            audioRecorder?.stop()
            
            recordState = .stopped
            
            // 添加到录音片段
            if currentRecordFilePath != nil {
                audioRecordFilePathSnippets.append(currentRecordFilePath!)
            }
            
            // 设置为空
            currentRecordFilePath = nil
        }
        
        stoppedRecord()
    }
    
    // MARK: - SECCutPanelViewDelegate
    
    func clickedBackButtonOnCutPanel(_ panel: SECCutPanelView) {
        
        if cutPanelHidden == false {
            cutPanelHidden(true, animated: true)
        }
        
        if playState == .playing {
            // 暂停播放
            audioPlayer?.pause()
            playState = .paused
            
            // 关闭播放定时器
            playTimming?.invalidate()
            
            cutPanel?.isPlaying = false
        }
    }
    
    func clickedPlayRecordButtonOnCutPanel(_ panel: SECCutPanelView) {
        
        if playState == .playing {
            // 暂停播放
            audioPlayer?.pause()
            playState = .paused
            
            // 关闭播放定时器
            playTimming?.invalidate()
        
            cutPanel?.isPlaying = false
            
        } else {
            
            let selectedWillScissorsScopeRange = self.selectedWillScissorsScopeRange
            if selectedWillScissorsScopeRange != nil && audioPlayer != nil {
                audioPlayer!.currentTime = TimeInterval(selectedWillScissorsScopeRange!.location) * audioPlayer!.duration
                audioPlayer!.prepareToPlay()
            }
            
            // 开始播放
            audioPlayer?.play()
            playState = .playing
            
            // 开启播放定时器
            playTimming?.invalidate()
            playTimming = Timer(timeInterval: 0.5, target: self, selector: #selector(SECNewReadingViewController.firedPlayTimming), userInfo: nil, repeats: true)
            RunLoop.main.add(playTimming!, forMode: RunLoopMode.commonModes)
            
            cutPanel?.isPlaying = true
        }
    }
    
    func clickedScissorsButtonOnCutPanel(_ panel: SECCutPanelView) {
        
        // 弹出剪切提示
        let alert = UIAlertController(title: "剪辑", message: "确定剪掉选中的录音吗？", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "确认", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            
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
            self.playState = .stopped
            
            let destinationCroppedFilePath = self.randomObtainTemporaryAudioFilePath()
            self.audioCropper = SECReadingRecordCropper(sourceRecordFilePath: playAudioFilePath!, cropRange: selectedRange!, destinationCroppedFilePath: destinationCroppedFilePath)
            
            // 开始裁切
            SVProgressHUD.show(withStatus: "")
            self.audioCropper!.cropWithCompletion({ (success) -> Void in
                
                // 隐藏裁剪框
                self.cutPanelHidden(true, animated: true)
                
                if success == false {
                    SVProgressHUD.showError(withStatus: "出故障了, 请联系 App 运营人员")
                    return
                }
                
                SVProgressHUD.dismiss()
                
                // 设置裁切音频为唯一录音片段
                
                self.audioRecordFilePathSnippets = [destinationCroppedFilePath]
                
                // 置空 selectedWillScissorsScopeRange
                self.selectedWillScissorsScopeRange = nil
                
                // 更新录音时间
                let croppedAudioDuration = self.recordDuration * TimeInterval(1.0 - selectedRange!.length)
                self.recordDuration = croppedAudioDuration
                self.mRecordDurationLabel.text = SECHelper.createFormatTextForRecordDuration(croppedAudioDuration)
                if croppedAudioDuration <= MininumRecordAudioSecondsToScissors {
                    self.mScissorsRecordButton.isEnabled = false
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler:nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func willSlideScopeHandleOnCutPanel(_ panel: SECCutPanelView) {
        
        panel.isPlaying = false
        panel.playProgress = 0
        
        if playState == .playing {
            audioPlayer?.pause()
            playState = .paused
        }
    }
    
    func selectedScopeOnCutPanel(_ panel: SECCutPanelView, selectedScopeRange: SECRecordRange) {
        
        self.selectedWillScissorsScopeRange = selectedScopeRange
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {

    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        
        recordState = .stopped
        
        // 添加到录音片段
        if currentRecordFilePath != nil {
            audioRecordFilePathSnippets.append(currentRecordFilePath!)
        }
        
        // 设置为空
        currentRecordFilePath = nil
        
        stoppedRecord()
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
        playState = .stopped
        cutPanel?.isPlaying = false
        playTimming?.invalidate()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        playState = .stopped
        cutPanel?.isPlaying = false
        playTimming?.invalidate()
    }
}
