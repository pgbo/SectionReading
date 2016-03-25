//
//  SECReadingHistoryTableViewCell.swift
//  SectionReading
//
//  Created by guangbo on 15/12/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

@objc protocol SECReadingHistoryTableViewCellDelegate {
    
    optional func clickEditButtonIn(cell: SECReadingHistoryTableViewCell)
    
    optional func clickTrashButtonIn(cell: SECReadingHistoryTableViewCell)
    
    optional func clickShareButtonIn(cell: SECReadingHistoryTableViewCell)
    
    optional func clickPlayAudioButtonIn(cell: SECReadingHistoryTableViewCell)
}

class SECReadingHistoryTableViewCell: UITableViewCell, SECAudioPlayViewDelegate {

    weak var delegate: SECReadingHistoryTableViewCellDelegate?
    
    @IBOutlet private weak var mTextLabel: UILabel!
    @IBOutlet private weak var mDateLabel: UILabel!
    @IBOutlet private weak var mEditButton: UIButton!
    @IBOutlet private weak var mTrashButton: UIButton!
    @IBOutlet private weak var mShareButton: UIButton!
    
    @IBOutlet private weak var mAudioPanel: UIView!
    @IBOutlet private weak var mAudioPanelTop: NSLayoutConstraint!
    @IBOutlet private weak var mAudioPanelHeight: NSLayoutConstraint!
    
    var isPlaying: Bool = false {
        didSet {
            self.mAudioPlayView?.isPlaying = isPlaying
        }
    }
    
    private var mAudioPlayView: SECAudioPlayView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        setupReadingHistoryTableViewCell()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupReadingHistoryTableViewCell() {
        
        mAudioPanel.backgroundColor = UIColor.clearColor()
        mAudioPanel.clipsToBounds = true
        
        mAudioPlayView = SECAudioPlayView.instanceFromNib()
        mAudioPanel.addSubview(mAudioPlayView!)
        
        mAudioPlayView.delegate = self
        mAudioPlayView.hiddenProgressLabel = true
        
        mAudioPlayView.translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["mAudioPlayView":mAudioPlayView!]
        mAudioPanel.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        mAudioPanel.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
    }

    @IBAction func clickedActionButton(sender: AnyObject) {
        
        if sender.isEqual(mEditButton) {
            delegate?.clickEditButtonIn?(self)
            return
        }
        
        if sender.isEqual(mTrashButton) {
            delegate?.clickTrashButtonIn?(self)
            return
        }
        
        if sender.isEqual(mShareButton) {
            delegate?.clickShareButtonIn?(self)
            return
        }
    }
    
    // MARK: - SECAudioPlayViewDelegate
    
    func clickedPlayButtonOnAudioPlayView(view: SECAudioPlayView) {
    
        delegate?.clickPlayAudioButtonIn?(self)
    }
    
    struct DateFormatorStatic {
        static var onceToken : dispatch_once_t = 0
        static var formator : NSDateFormatter?
    }
    
    func configure(withReading reading: TReading) {
    
        dispatch_once(&DateFormatorStatic.onceToken) {
            DateFormatorStatic.formator = NSDateFormatter()
            DateFormatorStatic.formator!.dateStyle = NSDateFormatterStyle.ShortStyle
            DateFormatorStatic.formator!.timeStyle = NSDateFormatterStyle.MediumStyle
        }
        var readingDate: NSDate?
        if reading.fModifyTimestamp != nil {
            readingDate = NSDate(timeIntervalSince1970: NSTimeInterval(reading.fModifyTimestamp!.integerValue))
        } else if reading.fCreateTimestamp != nil {
            readingDate = NSDate(timeIntervalSince1970: NSTimeInterval(reading.fCreateTimestamp!.integerValue))
        } else {
            readingDate = NSDate()
        }
        
        mTextLabel.text = reading.fContent
        mDateLabel.text = DateFormatorStatic.formator!.stringFromDate(readingDate!)
        
        if reading.fLocalAudioFilePath != nil || reading.fUploadedAudioGuid != nil {
            mAudioPanelTop.constant = 10.0
            mAudioPanelHeight.constant = 32.0
            mAudioPanel.hidden = false
        } else {
            mAudioPanelTop.constant = 0
            mAudioPanelHeight.constant = 0
            mAudioPanel.hidden = true
        }
    }
}
