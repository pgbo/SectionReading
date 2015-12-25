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
    
    optional func clickPlayAudioButtonIn(cell: SECAudioFileTableViewCell)
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
            mPlayButton.setImage(normalImage, forState: UIControlState.Normal)
            mPlayButton.setImage(hlImage, forState: UIControlState.Highlighted)
        }
    }
    
    @IBOutlet private weak var mBriefDayLabel: UILabel!
    @IBOutlet private weak var mTimeLabel: UILabel!
    @IBOutlet private weak var mDayLabel: UILabel!
    @IBOutlet private weak var mAudioDurationLabel: UILabel!
    @IBOutlet private weak var mPlayButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAudioFileTableViewCell()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupAudioFileTableViewCell() {
    
        isPlaying = false
    }
    
    @IBAction func clickedPlayButton(sender: AnyObject) {
        delegate?.clickPlayAudioButtonIn?(self)
    }
    
    func configure(withAudioFilePath audioFilePath: String) {
        
        do {
            let attr = try NSFileManager.defaultManager().attributesOfItemAtPath(audioFilePath)
            let modificationDate = attr[NSFileModificationDate] as! NSDate
            
            let defaultCalendar = SECHelper.defaultCalendar()
            let dateComponents = defaultCalendar.components(NSCalendarUnit(rawValue: NSCalendarUnit.Year.rawValue|NSCalendarUnit.Month.rawValue|NSCalendarUnit.Day.rawValue|NSCalendarUnit.Hour.rawValue|NSCalendarUnit.Minute.rawValue), fromDate: modificationDate)
            
            mBriefDayLabel.text = "\(dateComponents.month)月\(dateComponents.day)日"
            mTimeLabel.text = "\(dateComponents.hour)点\(dateComponents.minute)分"
            mDayLabel.text = "\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day)"
            
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
            mBriefDayLabel.text = "-月-日"
            mTimeLabel.text = "-点-分"
            mDayLabel.text = "-----)"
        }
        
        let asset = AVAsset(URL: NSURL(fileURLWithPath: audioFilePath))
        let duration = CMTimeGetSeconds(asset.duration)
        mAudioDurationLabel.text = SECHelper.createFormatTextForRecordDuration(duration)
        
    }
}
