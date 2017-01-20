//
//  PlayRecordVC.swift
//  SectionReading
//
//  Created by guangbo on 15/10/20.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

let PlayRecordVCBackButtonClickNotification = "PlayRecordVCBackButtonClickNotification"

let PlayRecordVCPlayRecordButtonTopSpacing = CGFloat(34)
let PlayRecordVCActionButtonSize = CGFloat(50)

/**
 *  播放录音 VC 的代理
 */
@objc protocol PlayRecordVCDelegate {
    /**
     已经完成剪切
     */
    @objc optional func didCutAudio(_ playVC: PlayRecordVC, newAudioFilePath: String)
}

/**
 播放器状态
 
 - Stopped: 停止
 - Playing: 正在播放
 - Paused:  暂停中
 */
enum PlayRecordVCPlayerState {
    case stopped
    case playing
    case paused
}

// 播放录音 VC
class PlayRecordVC: UIViewController, AVAudioPlayerDelegate {

    weak var delegate: PlayRecordVCDelegate?
    
    fileprivate var recordFilePath: String?
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var playerState: PlayRecordVCPlayerState = .stopped
    
    fileprivate (set) var playSlider: CDPlaySlider?
    fileprivate (set) var playButn: CircularButton?
    fileprivate (set) var backButn: CircularButton?
    fileprivate (set) var cutButn: CircularButton?
    fileprivate (set) var playSliderCenterYConstraint: NSLayoutConstraint?
    
    fileprivate var playProcessDisplayLink: CADisplayLink? /** 播放进度定时器 */

    convenience init(recordFilePath filePath: String) {
        self.init()
        
        self.recordFilePath = filePath
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayRecordVC.receiveAudioSessionInterrutionNote(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: filePath))
            audioPlayer?.delegate = self
            
            audioPlayer?.prepareToPlay()
            
        } catch let error as NSError {
            print("error: \(error)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 0xf5/255.0, green: 0xee/255.0, blue: 0xee/255.0, alpha: 1)
        
        // 设置 recordButtonView
        
        playSlider = CDPlaySlider(frame: CGRect(x: 0, y: 0, width: 220, height: 220))
        self.view.addSubview(playSlider!)
        
        playSlider?.backgroundColor = UIColor.clear
        playSlider?.translatesAutoresizingMaskIntoConstraints = false
        
        playSliderCenterYConstraint = NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        self.view.addConstraint(playSliderCenterYConstraint!)
        
        self.view.addConstraint(NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        playSlider!.addConstraint(NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: 220))
        
        playSlider!.addConstraint(NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: playSlider!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))
        
        
        
        let actionButnColor = UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)
        
        // 设置 playButn
        
        playButn = CircularButton(type: UIButtonType.custom)
        self.view.addSubview(playButn!)
        
        playButn?.translatesAutoresizingMaskIntoConstraints = false
        playButn?.setImage(UIImage(named: "play"), for: UIControlState())
        playButn?.setImage(UIImage(named: "play"), for: UIControlState.highlighted)
        playButn?.backgroundColor = actionButnColor
        
        playButn?.addTarget(self, action: #selector(PlayRecordVC.togglePlayAudio), for: UIControlEvents.touchUpInside)
        
        self.view.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: playSlider!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: PlayRecordVCPlayRecordButtonTopSpacing))
        
        self.view.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        playButn!.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: PlayRecordVCActionButtonSize))
        
        playButn!.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: playButn!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))
        
        
        // 设置 backButn
        
        backButn = CircularButton(type: UIButtonType.custom)
        self.view.addSubview(backButn!)
        
        backButn?.translatesAutoresizingMaskIntoConstraints = false
        backButn?.setImage(UIImage(named: "undo"), for: UIControlState())
        backButn?.setImage(UIImage(named: "undo"), for: UIControlState.highlighted)
        backButn?.backgroundColor = actionButnColor
        
        
        backButn?.addTarget(self, action: #selector(PlayRecordVC.backButnClick), for: UIControlEvents.touchUpInside)
        
        self.view.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: playButn!, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: playButn!, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: -30.0))
        
        backButn!.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: PlayRecordVCActionButtonSize))
        
        backButn!.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: backButn!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))
        
        
        
        // 设置 cutButn
        
        cutButn = CircularButton(type: UIButtonType.custom)
        self.view.addSubview(cutButn!)
        
        cutButn?.translatesAutoresizingMaskIntoConstraints = false
        cutButn?.setImage(UIImage(named: "cut"), for: UIControlState())
        cutButn?.setImage(UIImage(named: "cut"), for: UIControlState.highlighted)
        cutButn?.backgroundColor = actionButnColor
        
        
        self.view.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: playButn!, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: playButn!, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 30.0))
        
        cutButn!.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: PlayRecordVCActionButtonSize))
        
        cutButn!.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: cutButn!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc fileprivate func backButnClick() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: PlayRecordVCBackButtonClickNotification), object: self)
    }
    
    @objc fileprivate func togglePlayAudio() {
        // 播放音频
        if playerState == .playing {
            audioPlayer?.pause()
            playerState = .paused
            pausedPlayer()
        } else {
            audioPlayer?.play()
            playerState = .playing
            playingPlayer()
        }
    }
    
    fileprivate func playingPlayer() {
        
        playProcessDisplayLink?.invalidate()
        playProcessDisplayLink = CADisplayLink(target: self, selector: #selector(PlayRecordVC.playingAudio))
        playProcessDisplayLink?.frameInterval = 30
        playProcessDisplayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        playButn?.setImage(UIImage(named: "pause"), for: UIControlState())
        playButn?.setImage(UIImage(named: "pause"), for: UIControlState.highlighted)
    }
    
    fileprivate func pausedPlayer() {
        
        playProcessDisplayLink?.invalidate()
        
        playButn?.setImage(UIImage(named: "play"), for: UIControlState())
        playButn?.setImage(UIImage(named: "play"), for: UIControlState.highlighted)
    }
    
    fileprivate func stoppedPlayer() {
        
        playProcessDisplayLink?.invalidate()
        
        playButn?.setImage(UIImage(named: "play"), for: UIControlState())
        playButn?.setImage(UIImage(named: "play"), for: UIControlState.highlighted)
    }
    
    // MARK: AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerState = .stopped
        stoppedPlayer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        playerState = .stopped
        stoppedPlayer()
    }
    
    // MARK: notification
    
    @objc fileprivate func receiveAudioSessionInterrutionNote(_ note: Notification) {
        let interruptionType = (note as NSNotification).userInfo![AVAudioSessionInterruptionTypeKey]
        let type = AVAudioSessionInterruptionType(rawValue: (interruptionType as! NSNumber).uintValue)!
        if type == .began {
            playerState = .paused
            pausedPlayer()
        }
    }
    
    // 音频播放中
    @objc fileprivate func playingAudio() {
        
        if audioPlayer != nil && audioPlayer!.isPlaying {
            // 改变进度
            let audioDuration = audioPlayer!.duration
            let currentTime = audioPlayer!.currentTime
            
            var progress: CGFloat = 0.0
            if audioDuration > 0 {
                progress = CGFloat(currentTime/audioDuration)
            }
            
            playSlider?.progressView?.progress = progress
            playSlider?.progressView?.progressLabel?.text = "\(Int(currentTime))"
//            playSlider.scopeGradientView.
        }
    }
}
