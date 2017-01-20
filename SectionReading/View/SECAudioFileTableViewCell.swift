//
//  SECAudioFileTableViewCell.swift
//  SectionReading
//
//  Created by guangbo on 15/12/25.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol SECAudioFileTableViewCellDelegate {
    
    @objc optional func clickPlayAudioButtonIn(_ cell: SECAudioFileTableViewCell)
}

class SECAudioFileTableViewCell: UITableViewCell {

    weak var delegate: SECAudioFileTableViewCellDelegate?
    
    var isPlaying: Bool = false {
        didSet {
            var normalImage: UIImage?
            var hlImage: UIImage?
            if isPlaying {
                normalImage = UIImage(named: "RecordListPauseButton")
                hlImage = UIImage(named: "RecordListPauseButtonHL")
            } else {
                normalImage = UIImage(named: "RecordListPlayButton")
                hlImage = UIImage(named: "RecordListPlayButtonHL")
            }
            mPlayButton?.setImage(normalImage, for: UIControlState())
            mPlayButton?.setImage(hlImage, for: UIControlState.highlighted)
        }
    }

    @IBOutlet fileprivate weak var mBriefDayLabel: UILabel!
    @IBOutlet fileprivate weak var mTimeLabel: UILabel!
    @IBOutlet fileprivate weak var mDayLabel: UILabel!
    @IBOutlet fileprivate weak var mAudioDurationLabel: UILabel!
    
    fileprivate var mPlayButton: UIButton?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAudioFileTableViewCell()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    fileprivate func setupAudioFileTableViewCell() {
    
        mPlayButton = UIButton(type: UIButtonType.custom)
        mPlayButton?.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        mPlayButton?.addTarget(self, action: #selector(SECAudioFileTableViewCell.clickedPlayButton), for: UIControlEvents.touchUpInside)
        self.accessoryView = mPlayButton
        
        self.editingAccessoryType = UITableViewCellAccessoryType.disclosureIndicator
        self.selectionStyle = UITableViewCellSelectionStyle.default
        
        isPlaying = false
    }
    
    @objc fileprivate func clickedPlayButton() {
        delegate?.clickPlayAudioButtonIn?(self)
    }
    
    func configure(withAudioFilePath audioFilePath: String) {
        
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: audioFilePath)
            let modificationDate = attr[FileAttributeKey.modificationDate] as! Date
            
            let defaultCalendar = SECHelper.defaultCalendar()
            let dateComponents = (defaultCalendar as NSCalendar).components(NSCalendar.Unit(rawValue: NSCalendar.Unit.year.rawValue|NSCalendar.Unit.month.rawValue|NSCalendar.Unit.day.rawValue|NSCalendar.Unit.hour.rawValue|NSCalendar.Unit.minute.rawValue), from: modificationDate)
            
            mBriefDayLabel.text = "\(dateComponents.month)月\(dateComponents.day)日"
            mTimeLabel.text = "\(dateComponents.hour)点\(dateComponents.minute)分"
            mDayLabel.text = "\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day)"
            
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
            mBriefDayLabel.text = "-月-日"
            mTimeLabel.text = "-点-分"
            mDayLabel.text = "-----)"
        }
        
        let asset = AVAsset(url: URL(fileURLWithPath: audioFilePath))
        let duration = CMTimeGetSeconds(asset.duration)
        mAudioDurationLabel.text = "时长:\(SECHelper.createFormatTextForRecordDuration(duration))"
        
    }
}
