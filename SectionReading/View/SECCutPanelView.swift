//
//  SECCutPanelView.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

@objc protocol SECCutPanelViewDelegate {
    
    /**
     点击返回按钮
     
     - parameter panel:
     */
    optional func clickedBackButtonOnCutPanel(panel: SECCutPanelView)
    
    /**
     点击播放按钮
     
     - parameter panel:
     */
    optional func clickedPlayRecordButtonOnCutPanel(panel: SECCutPanelView)
    
    /**
     点击裁剪按钮
     
     - parameter panel:
     */
    optional func clickedScissorsButtonOnCutPanel(panel: SECCutPanelView)
    
    /**
     将要滑动范围选择滑块
     
     - parameter panel:
     */
    optional func willSlideScopeHandleOnCutPanel(panel: SECCutPanelView)
    
    /**
     已选择范围
     
     - parameter panel:
     - parameter selectedScopeRange: 已选范围
     */
    optional func selectedScopeOnCutPanel(panel: SECCutPanelView, selectedScopeRange: NSRange)
}


/**
 *  剪切面板视图
 */
class SECCutPanelView: UIView {
    
    @IBOutlet weak var mSelectScopeBackgroundImageView: UIImageView!
    @IBOutlet weak var mBackButton: UIButton!
    @IBOutlet weak var mPlayButton: UIButton!
    @IBOutlet weak var mScissorsButton: UIButton!
    @IBOutlet weak var mLeftSlideHandle: UIImageView!
    @IBOutlet weak var mRightSlideHandle: UIImageView!
    @IBOutlet weak var mSelectedRangeOverlay: UIView!
    @IBOutlet weak var mLeftUnactiveTrackLine: UIView!
    @IBOutlet weak var mMiddleActiveTrackLine: UIView!
    @IBOutlet weak var mRightUnactiveTrackLine: UIView!
    // 代理
    weak var delegate: SECCutPanelViewDelegate?
    
    // 默认选择的范围
    var defaultSelectedRange: NSRange = NSMakeRange(0, 0)
    
    // 播放进度
    var playProgress: CGFloat = 0
    
    // 是否在播放
    var isPlaying: Bool = false
    
    class func instanceFromNib() -> SECCutPanelView {
        return UINib(nibName: "SECCutPanelView", bundle: nil).instantiateWithOwner(nil, options: nil).first as! SECCutPanelView
    }
    
    override func awakeFromNib() {
     
        mBackButton.addTarget(self, action: "clickedBackButton:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    @objc private func clickedBackButton(sender: UIButton) {
        delegate?.clickedBackButtonOnCutPanel?(self)
    }
}
