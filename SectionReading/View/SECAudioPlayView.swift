//
//  SECAudioPlayView.swift
//  SectionReading
//
//  Created by guangbo on 15/12/14.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

@objc protocol SECAudioPlayViewDelegate {
    
    @objc optional func clickedPlayButtonOnAudioPlayView(_ view: SECAudioPlayView)
    
}

/// 音频播放视图
class SECAudioPlayView: UIView {

    @IBOutlet fileprivate weak var mPlayButton: UIButton!
    @IBOutlet fileprivate weak var mProgressView: UIProgressView!
    @IBOutlet fileprivate weak var mProgressLabel: UILabel!

    // 代理
    weak var delegate: SECAudioPlayViewDelegate?
    
    /// 音频时长
    var duration: Int = 0 {
        didSet {
            self.mProgressLabel.text = "\(Int(progress*Float(duration)))/\(duration) s"
            self.mProgressView.progress = progress
        }
    }
    
    /// 进度，在 0 - 1 之间
    var progress: Float = 0 {
        didSet {
            self.mProgressLabel.text = "\(Int(progress*Float(duration)))/\(duration) s"
            self.mProgressView.progress = progress
        }
    }
    
    /// 是否在播放
    var isPlaying: Bool = false {
        didSet {
            var image: UIImage?
            var imageHL: UIImage?
            if isPlaying {
                image = UIImage(named: "AudioPausedButn")
                imageHL = UIImage(named: "AudioPausedButnHL")
            } else {
                image = UIImage(named: "AudioPlayButn")
                imageHL = UIImage(named: "AudioPlayButnHL")
            }
            self.mPlayButton.setImage(image, for: UIControlState())
            self.mPlayButton.setImage(imageHL, for: UIControlState.highlighted)
        }
    }
    
    /// 是否隐藏进度 label
    var hiddenProgressLabel: Bool = false {
        didSet {
            if hiddenProgressLabel {
                mProgressLabel.text = ""
            } else {
                mProgressLabel.text = "\(Int(progress*Float(duration)))/\(duration) s"
            }
        }
    }
    
    
    class func instanceFromNib() -> SECAudioPlayView {
        return UINib(nibName: "SECAudioPlayView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! SECAudioPlayView
    }
    
    override func awakeFromNib() {
        setupAudioPlayView()
    }
    
    fileprivate func setupAudioPlayView() {
        
        self.duration = 0
        self.progress = 0
        self.isPlaying = false
        self.hiddenProgressLabel = false
        
        self.mPlayButton.addTarget(self, action: #selector(SECAudioPlayView.clickedPlayButton(_:)), for: UIControlEvents.touchUpInside)
    }
    
    @objc fileprivate func clickedPlayButton(_ sender: UIButton) {
        delegate?.clickedPlayButtonOnAudioPlayView?(self)
    }
}
