//
//  SECReadingShareLayoutView.swift
//  SectionReading
//
//  Created by guangbo on 16/1/13.
//  Copyright © 2016年 pengguangbo. All rights reserved.
//

import UIKit
import SnapKit

class SECReadingShareLayoutViewDataModel {
    var text: String?
    var readingDuration: TimeInterval?
}

let SECReadingShareLayoutViewTextRowHeight = CGFloat(47)
let SERReadingShareTextFont = UIFont.systemFont(ofSize: 17.0)

class SECReadingShareLayoutView: UIView {
    
    fileprivate var mSeperatorBackgroudView: UIImageView?
    fileprivate var mLabel: UILabel?
    fileprivate var mLogoMottoImageView: UIImageView?
    fileprivate lazy var mRecordDurationLabel: UILabel = {
        
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor(red: 0xCE/255.0, green: 0xCE/255.0, blue: 0xCE/255.0, alpha: 1)
        var font = UIFont(name: "Yuanti SC Light", size: 13.0)
        if font == nil {
            font = UIFont.systemFont(ofSize: 13.0)
        }
        label.font = font
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let shareTextFont: UIFont = {
        var font = UIFont(name: "Yuanti SC Light", size: 17.0)
        if font == nil {
            font = UIFont.systemFont(ofSize: 17.0)
        }
        return font!
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShareLayoutView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupShareLayoutView()
    }
    
    func configureWithModel(_ model: SECReadingShareLayoutViewDataModel) {
        
        let showDuration = model.readingDuration != nil
        let trailNewLineStr = showDuration ?"\n\n" :"\n"
        
        var showText = model.text
        showText = showText != nil ?(showText! + trailNewLineStr) :trailNewLineStr
        
        mLabel!.attributedText = buildLabelAttributedTextWithText(showText!)
        
        if showDuration {
            mRecordDurationLabel.text = "本次录音时长 \(SECHelper.createFormatTextForRecordDuration(model.readingDuration!))"
            mRecordDurationLabel.isHidden = false
            if mRecordDurationLabel.superview == nil {
                self.addSubview(mRecordDurationLabel)
                mRecordDurationLabel.snp_makeConstraints({ (make) -> Void in
                    make.leading.equalTo(22)
                    make.bottom.equalTo(mLabel!.snp_bottom).offset(-((SECReadingShareLayoutViewTextRowHeight + self.shareTextFont.lineHeight)/CGFloat(2.0) + CGFloat(4)))
                })
            }
        } else {
            mRecordDurationLabel.text = nil
            mRecordDurationLabel.isHidden = true
        }
    }
    
    fileprivate func setupShareLayoutView() {
    
        // mLabel
        mLabel = UILabel()
        mLabel!.backgroundColor = UIColor.clear
        mLabel!.numberOfLines = 0
        self.addSubview(mLabel!)
        
        mLabel!.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(80)
            make.leading.equalTo(22)
            make.trailing.equalTo(-22)
        }
        
        
        // mSeperatorBackgroudView
        mSeperatorBackgroudView = UIImageView(image: UIImage(named: "ShareTextRowBg")?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: UIImageResizingMode.tile))
        self.insertSubview(mSeperatorBackgroudView!, belowSubview: mLabel!)
        
        mSeperatorBackgroudView!.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(mLabel!.snp_top).offset(-(SECReadingShareLayoutViewTextRowHeight + (SECReadingShareLayoutViewTextRowHeight - self.shareTextFont.lineHeight)/CGFloat(2.0)))
            make.bottom.equalTo(mLabel!.snp_bottom).offset((SECReadingShareLayoutViewTextRowHeight - self.shareTextFont.lineHeight)/CGFloat(2.0))
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
        }
        
        // mLogoMottoImageView
        mLogoMottoImageView = UIImageView(image: UIImage(named: "LogoMotto"))
        self.addSubview(mLogoMottoImageView!)
        
        mLogoMottoImageView!.snp_makeConstraints({ (make) -> Void in
            make.top.equalTo(mSeperatorBackgroudView!.snp_bottom).offset(20)
            make.centerX.equalTo(0)
        })
        
        self.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(mLogoMottoImageView!.snp_bottom).offset(20)
        }
    }
    
    fileprivate func buildLabelAttributedTextWithText(_ text: String) -> NSAttributedString {
        
        let font = self.shareTextFont
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = SECReadingShareLayoutViewTextRowHeight - font.lineHeight
        
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font,
            NSParagraphStyleAttributeName: style, NSForegroundColorAttributeName: UIColor(red: 0x2E/255.0, green: 0x2E/255.0, blue: 0x2E/255.0, alpha: 1)])
    }
}
