//
//  SECReadingHistoryTableViewCell.swift
//  SectionReading
//
//  Created by guangbo on 15/12/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECReadingHistoryTableViewCell: UITableViewCell {

    @IBOutlet private weak var mTextLabel: UILabel!
    @IBOutlet private weak var mDateLabel: UILabel!
    @IBOutlet private weak var mEditButton: UIButton!
    @IBOutlet private weak var mTrashButton: UIButton!
    @IBOutlet private weak var mShareButton: UIButton!
    
    @IBOutlet private weak var mAudioPanel: UIView!
    @IBOutlet private weak var mAudioPanelHeight: NSLayoutConstraint!
    
    private var mAudioPlayView: SECAudioPlayView!
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        setupReadingHistoryTableViewCell()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupReadingHistoryTableViewCell() {
        
        mAudioPlayView = SECAudioPlayView.instanceFromNib()
        mAudioPlayView.hiddenProgressLabel = true
        
        mAudioPlayView.translatesAutoresizingMaskIntoConstraints = false
        // TODO: 添加约束
    }

    @IBAction func clickedActionButton(sender: AnyObject) {
    }
    
    func configure(withReading reading: TReading) {
    
        
    }
}
