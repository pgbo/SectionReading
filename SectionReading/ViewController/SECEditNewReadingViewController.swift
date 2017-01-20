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
    
    fileprivate var mAudioPlayView: SECAudioPlayView?
    
    /// 音频附件文件路径
    fileprivate (set) var attachAudioFilePath: String?
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var playTimming: Timer?
    
    fileprivate var hasAttachAudio = false
    
    fileprivate lazy var mSaveBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "保存", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SECEditNewReadingViewController.toSaveReading))
        return item
    }()
    
    fileprivate var evernoteManager = SECAppDelegate.SELF()!.evernoteManager
    
    class func instanceFromSB(_ attachAudioFilePath: String?) -> SECEditNewReadingViewController {
        
        let editNewReadingViewController = UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewController(withIdentifier: "SECEditNewReadingViewController") as! SECEditNewReadingViewController
        
        editNewReadingViewController.attachAudioFilePath = attachAudioFilePath
        
        return editNewReadingViewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:, bundle:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mAudioPlayViewContainnerView.backgroundColor = UIColor.clear
        
        if attachAudioFilePath != nil {
            do {
                // 创建新的播放器
                try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: attachAudioFilePath!))
                audioPlayer!.delegate = self
                audioPlayer!.prepareToPlay()
                
                hasAttachAudio = true
                
            } catch let error as NSError {
                
                print("Fail to init AVAudioPlayer, error:\(error.localizedDescription)")
                
                let alert = UIAlertController(title: nil, message: "加载音频文件出故障了, 请联系 App 运营人员", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        if audioPlayer != nil {
            
            setupmAudioPlayView()
            mAudioPlayView?.duration = Int(audioPlayer!.duration)
            
            mClearAudioButton.addTarget(self, action: #selector(SECEditNewReadingViewController.clickedClearAudioButton(_:)), for: UIControlEvents.touchUpInside)
            
        } else {
        
            mAudioContainnerViewTop.constant = 0
            mAudioContainnerViewHeight.constant = 0
            mAudioContainnerView.isHidden = true
        }
        
        self.navigationItem.title = "保存读书"
        self.navigationItem.rightBarButtonItem = self.mSaveBarItem
        self.navigationItem.backBarButtonItem?.title = "返回"
        self.navigationItem.backBarButtonItem?.target = self
        self.navigationItem.backBarButtonItem?.action = #selector(SECEditNewReadingViewController.clickedBackBarButtonItem)
        
        mTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupmAudioPlayView() {
        
        if mAudioPlayView == nil {
            mAudioPlayView = SECAudioPlayView.instanceFromNib()
            mAudioPlayViewContainnerView.addSubview(mAudioPlayView!)
            
            mAudioPlayView!.delegate = self
            mAudioPlayView!.translatesAutoresizingMaskIntoConstraints = false
            
            let views = ["mAudioPlayView":mAudioPlayView!]
            mAudioPlayViewContainnerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
            mAudioPlayViewContainnerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        }
    }
    
    @IBAction func touchedDownBackground(_ sender: AnyObject) {
        mTextView.resignFirstResponder()
    }
    
    
    @objc fileprivate func clickedBackBarButtonItem() {
        // 弹出退出确认提示
        let alert = UIAlertController(title: nil, message: "确定要退出本次读书记录编辑吗?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "退出", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func toSaveReading() {
        
        audioPlayer?.pause()
        mAudioPlayView?.isPlaying = false
        playTimming?.invalidate()
        
        let textContent = mTextView.text
        let hasContent = textContent != nil && textContent?.isEmpty == false
        let hasAudio = hasAttachAudio && audioPlayer != nil && audioPlayer!.duration != 0
        
        if hasContent == false && hasAudio == false {
            return
        }
        
        TReading.create(withConstructBlock: { (newReading) -> Void in
            newReading.fLocalId = "\(UUID().uuidString)"
            newReading.fContent = textContent
            
            if hasAudio && self.attachAudioFilePath != nil {
                newReading.fLocalAudioFilePath = self.attachAudioFilePath
            }
            
            let time = NSNumber(value: Int32(Date().timeIntervalSince1970) as Int32)
            newReading.fCreateTimestamp = time
            newReading.fModifyTimestamp = time
            
            newReading.fSyncStatus = NSNumber(value: ReadingSyncStatus.needSyncUpload.rawValue as Int)
            
            if self.evernoteManager?.isAuthenticated() == false {
                
                // 到分享页面
                self.tipGotoSharePage(withTipMessage: "保存成功，赶快分享给大家吧！", shareReadingLocalId: newReading.fLocalId!);
                return
            }
            
            // 同步到 evernote
            SVProgressHUD.show(withStatus: "", maskType: SVProgressHUDMaskType.gradient)
            
            // 同步
            self.evernoteManager?.createNote(withContent: newReading, completion: { (note) -> Void in
                if note == nil {
                    SVProgressHUD.dismiss()
                    print("上传失败")
                    return
                }
                
                print("上传成功")
                
                DispatchQueue.main.async {
                    let readingLocalId = newReading.fLocalId;
                    let option = ReadingQueryOption()
                    option.localId = readingLocalId
                    TReading.filterByOption(option, completion: { (results) -> Void in
                        SVProgressHUD.dismiss()
                        if results == nil {
                            return
                        }
                        
                        for result in (results! as [TReading]) {
                            result.fillFields(fromEverNote: note!, onlyFillUnSettedFields: true)
                            result.fSyncStatus = NSNumber(value: ReadingSyncStatus.normal.rawValue)
                        }
                        
                        self.tipGotoSharePage(withTipMessage: "上传成功，赶快分享给大家吧！", shareReadingLocalId: readingLocalId!);
                    })
                }
            })
        })
    }
    
    fileprivate func tipGotoSharePage(withTipMessage message: String, shareReadingLocalId readingLocalId: String) {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "去分享", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            // 到分享页面
            self.navigationController?.show(SECShareReadingViewController.instanceFromSB(withShareReadingLocalId: readingLocalId), sender: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func clickedClearAudioButton(_ sender: UIButton) {

        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.4, animations: {
            
            self.mAudioContainnerViewTop.constant = 0
            self.mAudioContainnerViewHeight.constant = 0
            self.mAudioContainnerView.isHidden = true
            
            self.view.layoutIfNeeded()
        })
        
        hasAttachAudio = false
    }
    
    @objc fileprivate func firedPlayTimming() {
        
        if audioPlayer != nil {
           
            let audioDuration = audioPlayer!.duration
            let currentTime = audioPlayer!.currentTime
            
            mAudioPlayView?.progress = Float(currentTime/audioDuration)
        }
    }
    
    // MARK: - SECAudioPlayViewDelegate
    
    func clickedPlayButtonOnAudioPlayView(_ view: SECAudioPlayView) {
        
        if audioPlayer!.isPlaying {
            
            // 暂停
            audioPlayer!.pause()
            playTimming?.invalidate()
            
            mAudioPlayView?.isPlaying = false
            return
        }
        
        // 播放
        
        audioPlayer?.play()
        
        playTimming?.invalidate()
        playTimming = Timer(timeInterval: 0.5, target: self, selector: #selector(SECEditNewReadingViewController.firedPlayTimming), userInfo: nil, repeats: true)
        RunLoop.main.add(playTimming!, forMode: RunLoopMode.commonModes)
        
        mAudioPlayView?.isPlaying = true
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        playTimming?.invalidate()
        mAudioPlayView?.isPlaying = false
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    
        playTimming?.invalidate()
        mAudioPlayView?.isPlaying = false
    }
}
