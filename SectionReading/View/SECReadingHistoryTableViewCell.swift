//
//  SECReadingHistoryTableViewCell.swift
//  SectionReading
//
//  Created by guangbo on 15/12/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

@objc protocol SECReadingHistoryTableViewCellDelegate {
    
    @objc optional func clickEditButtonIn(_ cell: SECReadingHistoryTableViewCell)
    
    @objc optional func clickTrashButtonIn(_ cell: SECReadingHistoryTableViewCell)
    
    @objc optional func clickShareButtonIn(_ cell: SECReadingHistoryTableViewCell)
    
    @objc optional func clickPlayAudioButtonIn(_ cell: SECReadingHistoryTableViewCell)
}

class SECReadingHistoryTableViewCell: UITableViewCell, SECAudioPlayViewDelegate {

    private static var __once: () = {
            DateFormatorStatic.formator = DateFormatter()
            DateFormatorStatic.formator!.dateStyle = DateFormatter.Style.short
            DateFormatorStatic.formator!.timeStyle = DateFormatter.Style.medium
        }()

    weak var delegate: SECReadingHistoryTableViewCellDelegate?
    
    @IBOutlet fileprivate weak var mTextLabel: UILabel!
    @IBOutlet fileprivate weak var mDateLabel: UILabel!
    @IBOutlet fileprivate weak var mEditButton: UIButton!
    @IBOutlet fileprivate weak var mTrashButton: UIButton!
    @IBOutlet fileprivate weak var mShareButton: UIButton!
    
    @IBOutlet fileprivate weak var mAudioPanel: UIView!
    @IBOutlet fileprivate weak var mAudioPanelTop: NSLayoutConstraint!
    @IBOutlet fileprivate weak var mAudioPanelHeight: NSLayoutConstraint!
    
    var isPlaying: Bool = false {
        didSet {
            self.mAudioPlayView?.isPlaying = isPlaying
        }
    }
    
    fileprivate var mAudioPlayView: SECAudioPlayView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        setupReadingHistoryTableViewCell()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    fileprivate func setupReadingHistoryTableViewCell() {
        
        mAudioPanel.backgroundColor = UIColor.clear
        mAudioPanel.clipsToBounds = true
        
        mAudioPlayView = SECAudioPlayView.instanceFromNib()
        mAudioPanel.addSubview(mAudioPlayView!)
        
        mAudioPlayView.delegate = self
        mAudioPlayView.hiddenProgressLabel = true
        
        mAudioPlayView.translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["mAudioPlayView":mAudioPlayView!]
        mAudioPanel.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        mAudioPanel.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[mAudioPlayView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
    }

    @IBAction func clickedActionButton(_ sender: AnyObject) {
        
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
    
    func clickedPlayButtonOnAudioPlayView(_ view: SECAudioPlayView) {
    
        delegate?.clickPlayAudioButtonIn?(self)
    }
    
    struct DateFormatorStatic {
        static var onceToken : Int = 0
        static var formator : DateFormatter?
    }
    
    func configure(withReading reading: TReading) {
    
        _ = SECReadingHistoryTableViewCell.__once
        var readingDate: Date?
        if reading.fModifyTimestamp != nil {
            readingDate = Date(timeIntervalSince1970: TimeInterval(reading.fModifyTimestamp!.intValue))
        } else if reading.fCreateTimestamp != nil {
            readingDate = Date(timeIntervalSince1970: TimeInterval(reading.fCreateTimestamp!.intValue))
        } else {
            readingDate = Date()
        }
        
        mTextLabel.text = reading.fContent
        mDateLabel.text = DateFormatorStatic.formator!.string(from: readingDate!)
        
        if reading.fLocalAudioFilePath != nil || reading.fUploadedAudioGuid != nil {
            mAudioPanelTop.constant = 10.0
            mAudioPanelHeight.constant = 32.0
            mAudioPanel.isHidden = false
        } else {
            mAudioPanelTop.constant = 0
            mAudioPanelHeight.constant = 0
            mAudioPanel.isHidden = true
        }
    }
}
