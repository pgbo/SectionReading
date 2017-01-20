//
//  RecordButtonView.swift
//  SectionReading
//
//  Created by guangbo on 15/9/17.
//  Copyright (c) 2015年 pengguangbo. All rights reserved.
//

import UIKit

let ButtonSize = CGFloat(200.0)
let IconViewSize = CGFloat(50.0)
let TitleLabelHeight = CGFloat(22.0)
let ProgressViewInnerSpacing = CGFloat(1)
let ProgressViewLineWidth = CGFloat(2)

/// 录音按钮视图
class RecordButtonView: UIView {
    
    fileprivate (set) var button: UIButton?
    fileprivate (set) var iconView: UIImageView?
    fileprivate (set) var titleLabel: UILabel?
    fileprivate (set) var progressView: RSProgressView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRecordButtonView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupRecordButtonView()
    }
    
    fileprivate func setupRecordButtonView() {
        
        // 设置 progressView
        
        progressView = RSProgressView()
        self.addSubview(progressView!)
        
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        progressView?.backgroundColor = UIColor.clear
        progressView?.tintColor = UIColor(red: 0x48/255.0, green: 0x79/255.0, blue: 0xD2/255.0, alpha: 1.0)
        progressView?.progressLineWidth = ProgressViewLineWidth
        progressView?.clipsToBounds = false
        
        // 设置 button
        
        button = UIButton(type: UIButtonType.custom)
        self .addSubview(button!)
        
        button?.translatesAutoresizingMaskIntoConstraints = false
        button?.backgroundColor = UIColor(red: 0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1)
        
        // 设置 iconView
        
        iconView = UIImageView()
        self.addSubview(iconView!)
        
        iconView?.translatesAutoresizingMaskIntoConstraints = false
        
        
        // 设置 titleLabel
        
        titleLabel = UILabel()
        self .addSubview(titleLabel!)
        
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.backgroundColor = UIColor.clear
        titleLabel?.textColor = UIColor.white
        titleLabel?.font = UIFont.systemFont(ofSize: 18)
        titleLabel?.textAlignment = NSTextAlignment.center
        
        
        // 设置约束
        
        // progressView
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: ButtonSize + 2*ProgressViewInnerSpacing + 2*progressView!.progressLineWidth))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: progressView!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))
        
        // button
        
        self.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        button!.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: ButtonSize))
        
        button!.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: ButtonSize))
        
        
        // iconView
        
        self.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: -4))
        
        iconView!.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: IconViewSize))
        
        iconView!.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: IconViewSize))
        
        
        // titleLabel
        
        self.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: iconView!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 8))
        
        titleLabel!.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: ButtonSize))
        
        titleLabel!.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: TitleLabelHeight))
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonCornerRadius = ButtonSize/2
        if button != nil && button!.layer.cornerRadius != buttonCornerRadius {
            button?.layer.cornerRadius = buttonCornerRadius
            button?.layer.shadowOpacity = 0.5
            button?.layer.shadowOffset = CGSize(width: 0, height: 5.0)
            button?.layer.shadowRadius = 5.0
            button?.layer.masksToBounds = false
        }
        
    }
}
