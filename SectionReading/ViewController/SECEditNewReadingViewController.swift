//
//  SECEditNewReadingViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/14.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import KMPlaceholderTextView
import AVFoundation
import evernote_cloud_sdk_ios
import SVProgressHUD

class SECEditNewReadingViewController: UIViewController, SECAudioPlayViewDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var mAudioContainnerView: UIView!
    @IBOutlet weak var mAudioPlayViewContainnerView: UIView!
    @IBOutlet weak var mClearAudioButton: UIButton!
    @IBOutlet weak var mTextView: KMPlaceholderTextView!
    
    @IBOutlet weak var mAudioContainnerViewTop: NSLayoutConstraint!
    @IBOutlet weak var mAudioContainnerViewHeight: NSLayoutConstraint!
    
    private var mAudioPlayView: SECAudioPlayView?
    
    /// 音频附件文件路径
    private (set) var attachAudioFilePath: String?
    private var audioPlayer: AVAudioPlayer?
    private var playTimming: NSTimer?
    
    private var hasAttachAudio = false
    
    private lazy var mSaveBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "保存", style: UIBarButtonItemStyle.Plain, target: self, action: "toSaveReading")
        return item
    }()
    
    private var evernoteManager = SECAppDelegate.SELF()!.evernoteManager
    
    class func instanceFromSB(attachAudioFilePath: String?) -> SECEditNewReadingViewController {
        
        let editNewReadingViewController = UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewControllerWithIdentifier("SECEditNewReadingViewController") as! SECEditNewReadingViewController
        
        editNewReadingViewController.attachAudioFilePath = attachAudioFilePath
        
        return editNewReadingViewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError("init(nibName:, bundle:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mAudioPlayViewContainnerView.backgroundColor = UIColor.clearColor()
        
        if attachAudioFilePath != nil {
            do {
                // 创建新的播放器
                try audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: attachAudioFilePath!))
                audioPlayer!.delegate = self
                audioPlayer!.prepareToPlay()
                
                hasAttachAudio = true
                
            } catch let error as NSError {
                
                print("Fail to init AVAudioPlayer, error:\(error.localizedDescription)")
                
                let alert = UIAlertController(title: nil, message: "加载音频文件出故障了, 请联系 App 运营人员", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        if audioPlayer != nil {
            
            setupmAudioPlayView()
            mAudioPlayView?.duration = Int(audioPlayer!.duration)
            
            mClearAudioButton.addTarget(self, action: "clickedClearAudioButton:", forControlEvents: UIControlEvents.TouchUpInside)
            
        } else {
        
            mAudioContainnerViewTop.constant = 0
            mAudioContainnerViewHeight.constant = 0
            mAudioContainnerView.hidden = true
        }
        
        self.navigationItem.title = "保存读书"
        self.navigationItem.rightBarButtonItem = self.mSaveBarItem
        self.navigationItem.backBarButtonItem?.title = "返回"
        self.navigationItem.backBarButtonItem?.target = self
        self.navigationItem.backBarButtonItem?.action = "clickedBackBarButtonItem"
        
        mTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupmAudioPlayView() {
        
        if mAudioPlayView == nil {
            mAudioPlayView = SECAudioPlayView.instanceFromNib()
            mAudioPlayViewContainnerView.addSubview(mAudioPlayView!)
            
            mAudioPlayView!.delegate = self
            mAudioPlayView!.translatesAutoresizingMaskIntoConstraints = false
            
            let views = ["mAudioPlayView":mAudioPlayView!]
            mAudioPlayViewContainnerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
            mAudioPlayViewContainnerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        }
    }
    
    @IBAction func touchedDownBackground(sender: AnyObject) {
        mTextView.resignFirstResponder()
    }
    
    
    @objc private func clickedBackBarButtonItem() {
        // 弹出退出确认提示
        let alert = UIAlertController(title: nil, message: "确定要退出本次读书记录编辑吗?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "退出", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @objc private func toSaveReading() {
        
        audioPlayer?.pause()
        mAudioPlayView?.isPlaying = false
        playTimming?.invalidate()
        
        let textContent = mTextView.text
        let hasContent = textContent != nil && textContent.isEmpty == false
        let hasAudio = hasAttachAudio && audioPlayer != nil && audioPlayer!.duration != 0
        
        if hasContent ||  hasAudio{
            
            SVProgressHUD.showWithStatus("", maskType: SVProgressHUDMaskType.Gradient)
            TReading.create(withConstructBlock: { (newReading) -> Void in
                newReading.fLocalId = "\(NSUUID().UUIDString)"
                newReading.fContent = textContent
                
                if hasAudio && self.attachAudioFilePath != nil {
                    newReading.fUploadingAudioFilePath = self.attachAudioFilePath
                }
                
                let time = NSNumber(int: Int32(NSDate().timeIntervalSince1970))
                newReading.fCreateTimestamp = time
                newReading.fModifyTimestamp = time
                
                newReading.fSyncStatus = NSNumber(integer: ReadingSyncStatus.NeedSyncUpload.rawValue)
                
                // 同步
                let readingLocalid = newReading.fLocalId
                self.evernoteManager.createNote(withContent: newReading, completion: { (note) -> Void in
                    if note == nil {
                        SVProgressHUD.dismiss()
                        print("上传失败")
                        return
                    }
                    
                    let option = ReadingQueryOption()
                    option.localId = readingLocalid
                    TReading.filterByOption(option, completion: { (results) -> Void in
                        print("上传成功")
                        SVProgressHUD.dismiss()
                        if results == nil {
                            return
                        }
                        
                        for result in (results! as [TReading]) {
                            result.fillFields(fromEverNote: note!, onlyFillUnSettedFields: false)
                            result.fSyncStatus = NSNumber(integer: ReadingSyncStatus.Normal.rawValue)
                        }
                    })
                    
                    // TODO: 到分享页面
                    
                })
            })
        }
    }
    
    @objc private func clickedClearAudioButton(sender: UIButton) {

        self.view.layoutIfNeeded()
        
        UIView.animateWithDuration(0.4, animations: {
            
            self.mAudioContainnerViewTop.constant = 0
            self.mAudioContainnerViewHeight.constant = 0
            self.mAudioContainnerView.hidden = true
            
            self.view.layoutIfNeeded()
        })
        
        hasAttachAudio = false
    }
    
    @objc private func firedPlayTimming() {
        
        if audioPlayer != nil {
           
            let audioDuration = audioPlayer!.duration
            let currentTime = audioPlayer!.currentTime
            
            mAudioPlayView?.progress = Float(currentTime/audioDuration)
        }
    }
    
    // MARK: - SECAudioPlayViewDelegate
    
    func clickedPlayButtonOnAudioPlayView(view: SECAudioPlayView) {
        
        if audioPlayer!.playing {
            
            // 暂停
            audioPlayer!.pause()
            playTimming?.invalidate()
            
            mAudioPlayView?.isPlaying = false
            return
        }
        
        // 播放
        
        audioPlayer?.play()
        
        playTimming?.invalidate()
        playTimming = NSTimer(timeInterval: 0.5, target: self, selector: "firedPlayTimming", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(playTimming!, forMode: NSRunLoopCommonModes)
        
        mAudioPlayView?.isPlaying = true
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        
        playTimming?.invalidate()
        mAudioPlayView?.isPlaying = false
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
    
        playTimming?.invalidate()
        mAudioPlayView?.isPlaying = false
    }
}
