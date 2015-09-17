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
let ProgressViewLineWidth = CGFloat(4)

/// 录音按钮视图
class RecordButtonView: UIView {
    
    private (set) var button: UIButton?
    private (set) var iconView: UIImageView?
    private (set) var titleLabel: UILabel?
    private (set) var progressView: RSProgressView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRecordButtonView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupRecordButtonView()
    }
    
    private func setupRecordButtonView() {
        
        // 设置 button
        
        button = UIButton.buttonWithType(UIButtonType.Custom) as? UIButton
        self .addSubview(button!)
        
        button?.setTranslatesAutoresizingMaskIntoConstraints(false)
        button?.backgroundColor = UIColor(red: 0x6f/255.0, green: 0xa9/255.0, blue: 0xaf/255.0, alpha: 1)
        
        // 设置 iconView
        
        iconView = UIImageView()
        self.addSubview(iconView!)
        
        iconView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        
        // 设置 titleLabel
        
        titleLabel = UILabel()
        self .addSubview(titleLabel!)
        
        titleLabel?.setTranslatesAutoresizingMaskIntoConstraints(false)
        titleLabel?.backgroundColor = UIColor.clearColor()
        titleLabel?.textColor = UIColor.whiteColor()
        titleLabel?.font = UIFont.systemFontOfSize(18)
        titleLabel?.textAlignment = NSTextAlignment.Center
        
        // 设置 progressView
        
        progressView = RSProgressView()
        self.addSubview(progressView!)
        
        progressView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        progressView?.backgroundColor = UIColor.clearColor()
        progressView?.tintColor = UIColor(red: 0x48/255.0, green: 0x79/255.0, blue: 0xD2/255.0, alpha: 1.0)
        progressView?.progressLineWidth = ProgressViewLineWidth
        progressView?.clipsToBounds = false
        
        
        // 设置约束
        
        // button
        
        self.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        button!.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: ButtonSize))
        
        button!.addConstraint(NSLayoutConstraint(item: button!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: ButtonSize))
        
        
        // iconView
        
        self.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: -4))
        
        iconView!.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: IconViewSize))
        
        iconView!.addConstraint(NSLayoutConstraint(item: iconView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: IconViewSize))
        
        
        // titleLabel
        
        self.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: iconView!, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 8))
        
        titleLabel!.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: ButtonSize))
        
        titleLabel!.addConstraint(NSLayoutConstraint(item: titleLabel!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: TitleLabelHeight))
        
        
        // progressView
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: ButtonSize + progressView!.progressLineWidth))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonCornerRadius = ButtonSize/2
        if button != nil && button!.layer.cornerRadius != buttonCornerRadius {
            button?.layer.cornerRadius = buttonCornerRadius
            button?.layer.shadowOpacity = 0.5
            button?.layer.shadowOffset = CGSizeMake(0, 5.0)
            button?.layer.shadowRadius = 5.0
            button?.layer.masksToBounds = false
        }
        
    }
    
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
