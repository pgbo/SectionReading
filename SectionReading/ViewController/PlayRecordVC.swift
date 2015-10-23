//
//  PlayRecordVC.swift
//  SectionReading
//
//  Created by guangbo on 15/10/20.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

let PlayRecordVCBackButtonClickNotification = "PlayRecordVCBackButtonClickNotification"

let PlayRecordVCPlayRecordButtonTopSpacing = CGFloat(38)
let PlayRecordVCActionButtonSize = CGFloat(38)

/// 播放录音 VC
class PlayRecordVC: UIViewController {

    private (set) var recordFilePath: String?
    private (set) var playSlider: CDPlaySlider?
    private var playButn: UIButton?
    private var backButn: UIButton?
    private var cutButn: UIButton?
    private var playSliderCenterYConstraint: NSLayoutConstraint?

    convenience init(recordFilePath filePath: String) {
        self.init()
        self.recordFilePath = filePath
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 0xf5/255.0, green: 0xee/255.0, blue: 0xee/255.0, alpha: 1)
        
        self.navigationItem.title = "播放声音"
        
        // 设置 recordButtonView
        
        playSlider = CDPlaySlider(frame: CGRectMake(0, 0, 220, 220))
        self.view.addSubview(playSlider!)
        
        playSlider?.translatesAutoresizingMaskIntoConstraints = false
        
        playSliderCenterYConstraint = NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        self.view.addConstraint(playSliderCenterYConstraint!)
        
        self.view.addConstraint(NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        playSlider!.addConstraint(NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: 220))
        
        playSlider!.addConstraint(NSLayoutConstraint(item: playSlider!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: playSlider!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
        
        
        let actionButnColor = UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)
        
        // 设置 playButn
        
        playButn = UIButton(type: UIButtonType.Custom)
        self.view.addSubview(playButn!)
        
        playButn?.translatesAutoresizingMaskIntoConstraints = false
        roundActionButton(playButn, color: actionButnColor)
        
        self.view.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: playSlider!, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: PlayRecordVCPlayRecordButtonTopSpacing))
        
        self.view.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        playButn!.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: PlayRecordVCActionButtonSize))
        
        playButn!.addConstraint(NSLayoutConstraint(item: playButn!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: playButn!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
        
        // 设置 backButn
        
        backButn = UIButton(type: UIButtonType.Custom)
        self.view.addSubview(backButn!)
        
        backButn?.translatesAutoresizingMaskIntoConstraints = false
        roundActionButton(backButn, color: actionButnColor)
        
        backButn?.addTarget(self, action: "backButnClick", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: playButn!, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: playButn!, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: -30.0))
        
        backButn!.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: PlayRecordVCActionButtonSize))
        
        backButn!.addConstraint(NSLayoutConstraint(item: backButn!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: backButn!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
        // 设置 cutButn
        
        cutButn = UIButton(type: UIButtonType.Custom)
        self.view.addSubview(cutButn!)
        
        cutButn?.translatesAutoresizingMaskIntoConstraints = false
        roundActionButton(cutButn, color: actionButnColor)
        
        self.view.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: playButn!, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: playButn!, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 30.0))
        
        cutButn!.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: PlayRecordVCActionButtonSize))
        
        cutButn!.addConstraint(NSLayoutConstraint(item: cutButn!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: cutButn!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func roundActionButton(button: UIButton?, color: UIColor) {
        button?.layer.borderColor = color.CGColor
        button?.layer.borderWidth = 1.0
        if button != nil {
            button!.layer.cornerRadius = fmax(CGRectGetWidth(button!.frame), CGRectGetHeight(button!.frame))/2
        }
        button?.layer.masksToBounds = true
    }
    
    @objc private func backButnClick() {
        NSNotificationCenter.defaultCenter().postNotificationName(PlayRecordVCBackButtonClickNotification, object: self)
    }
}
