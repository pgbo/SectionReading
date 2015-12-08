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
    optional func selectedScopeOnCutPanel(panel: SECCutPanelView, selectedScopeRange: SECRecordRange)
}


/**
 *  剪切面板视图
 */
class SECCutPanelView: UIView, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var mSelectScopeContainnerView: UIView!
    @IBOutlet private weak var mSelectScopeBackgroundImageView: UIImageView!
    @IBOutlet private weak var mBackButton: UIButton!
    @IBOutlet private weak var mPlayButton: UIButton!
    @IBOutlet private weak var mScissorsButton: UIButton!
    @IBOutlet private weak var mLeftSlideHandle: UIImageView!
    @IBOutlet private weak var mRightSlideHandle: UIImageView!
    @IBOutlet private weak var mSelectedRangeOverlay: UIView!
    @IBOutlet private weak var mLeftUnactiveTrackLine: UIView!
    @IBOutlet private weak var mMiddleActiveTrackLine: UIView!
    @IBOutlet private weak var mRightUnactiveTrackLine: UIView!
    
    
    @IBOutlet private weak var mLeftUnactiveTrackLineWidth: NSLayoutConstraint!
    @IBOutlet private weak var mMiddleActiveTrackLineWidth: NSLayoutConstraint!
    @IBOutlet private weak var mLeftSlideHandleTrailing: NSLayoutConstraint!
    @IBOutlet private weak var mRightSlideHandleLeading: NSLayoutConstraint!
    @IBOutlet weak var mLeftUnactiveTrackLineLeading: NSLayoutConstraint!
    @IBOutlet weak var mRightUnactiveTrackLineTrailing: NSLayoutConstraint!
    
    
    /**
     水平拽动方向
     
     - None:  无
     - Left:  向左
     - Right: 向右
     */
    private enum HorizonPanDirection {
        case None
        case Left
        case Right
    }
    
    // 代理
    weak var delegate: SECCutPanelViewDelegate?
    
    /**
     *  默认选择的范围, location 和 length 范围在 0 - 1 之间
     */
    var defaultSelectedRange: SECRecordRange = SECRecordRange(location: 0, length: 0) {
        didSet {
            let trackTotalWidth = self.trackTotalWidth()
            
            // 更新滑块位置
            self.mLeftSlideHandleTrailing.constant = defaultSelectedRange.location * trackTotalWidth
            self.mRightSlideHandleLeading.constant = self.mLeftSlideHandleTrailing.constant + defaultSelectedRange.length * trackTotalWidth
            
            self.mLeftUnactiveTrackLineWidth.constant = self.mLeftSlideHandleTrailing.constant
            // 更新进度
            self.mMiddleActiveTrackLineWidth.constant = CGRectGetWidth(self.mSelectedRangeOverlay.bounds) * playProgress
        }
    }
    
    /**
     *  播放进度,范围在 0 - 1 之间
     */
    var playProgress: CGFloat = 0 {
        didSet {
            
            // 更新进度
            self.mMiddleActiveTrackLineWidth.constant = CGRectGetWidth(self.mSelectedRangeOverlay.bounds) * playProgress
        }
    }
    
    // 是否在播放
    var isPlaying: Bool = false {
        didSet {
            
            // 更新播放按钮的图标
            let playButtonImage :UIImage?
            let playButtonHLImage :UIImage?
            let playButtonDisabledImage :UIImage?
            if isPlaying {
                playButtonImage = UIImage(named: "CutPanelPauseButton")
                playButtonHLImage = UIImage(named: "CutPanelPauseButtonHL")
                playButtonDisabledImage = UIImage(named: "CutPanelPauseButtonDisabled")
            } else {
                playButtonImage = UIImage(named: "CutPanelPlayButton")
                playButtonHLImage = UIImage(named: "CutPanelPlayButtonHL")
                playButtonDisabledImage = UIImage(named: "CutPanelPlayButtonDisabled")
            }
            self.mPlayButton.setImage(playButtonImage, forState: UIControlState.Normal)
            self.mPlayButton.setImage(playButtonHLImage, forState: UIControlState.Highlighted)
            self.mPlayButton.setImage(playButtonDisabledImage, forState: UIControlState.Disabled)
        }
    }
    
    @IBAction func clickedBackButton(button: UIButton) {
        self.delegate?.clickedBackButtonOnCutPanel?(self)
    }
    
    @IBAction func clickedPlayButton(button: UIButton) {
        self.delegate?.clickedPlayRecordButtonOnCutPanel?(self)
    }
    
    @IBAction func clickedScissorsButton(button: UIButton) {
        self.delegate?.clickedScissorsButtonOnCutPanel?(self)
    }
    
    /**
     左滑块滑动触发方法
     
     - parameter recognizer:
     */
    @IBAction func leftSlideHandlePanRecognized(recognizer: UIPanGestureRecognizer) {
        
        print("leftSlideHandlePanRecognized")
        
        let translation = recognizer.translationInView(recognizer.view)
        let state = recognizer.state
        
        switch state {
        case .Changed:
            
            let leftSlideHandleFrame = mLeftSlideHandle.frame
            let rightSlideHandleFrame = mRightSlideHandle.frame
            
            print("leftSlideHandleFrame:\(leftSlideHandleFrame), rightSlideHandleFrame:\(rightSlideHandleFrame)")
            
            
            let slideHorizonSpacing = CGRectGetMinX(rightSlideHandleFrame) - CGRectGetMaxX(leftSlideHandleFrame)
            let leftSlideLeadingSpacing = CGRectGetMinX(leftSlideHandleFrame)
            
            var translationX = translation.x
            var panDir = HorizonPanDirection.None
            
            // 判断滑动方向
            if slideHorizonSpacing > 0 {
                if leftSlideLeadingSpacing > 0 {
                    // 可左可右滑动
                    if translationX > 0 {
                        // 右滑
                        panDir = .Right
                    } else {
                        // 左滑
                        panDir = .Left
                    }
                } else {
                    // 只能向右滑动
                    if translationX > 0 {
                        panDir = .Right
                    }
                }
            } else {
                // 只能向左滑动
                if leftSlideLeadingSpacing > 0 && translationX < 0 {
                    panDir = .Left
                }
            }
            
            switch panDir {
            case .Right:
                let caculateNextTimeSlideSpacing = slideHorizonSpacing - translationX
                if caculateNextTimeSlideSpacing < 0 {
                    translationX = slideHorizonSpacing
                }
            case .Left:
                let caculateNextTimeLeftSlideLeadingSpacing = leftSlideLeadingSpacing + translationX
                if caculateNextTimeLeftSlideLeadingSpacing < 0 {
                    translationX = -leftSlideLeadingSpacing
                }
            case .None:
                translationX = 0
            }
            
            if translationX != 0 {
                self.mLeftSlideHandleTrailing.constant += translationX
                recognizer.setTranslation(CGPointMake(0, translation.y), inView: recognizer.view)
            }
    
        case .Ended:
            
            delegate?.selectedScopeOnCutPanel?(self, selectedScopeRange: caculateSelectScopeRange())
            
        default:
            print("")
        }
    }
    
    /**
     右滑块滑动触发方法
     
     - parameter recognizer:
     */
    @IBAction func rightSlideHandlePanRecognized(recognizer: UIPanGestureRecognizer) {
        
        print("rightSlideHandlePanRecognized")
        
        let translation = recognizer.translationInView(recognizer.view)
        let state = recognizer.state
        
        switch state {
        case .Changed:
            
            let leftSlideHandleFrame = mLeftSlideHandle.frame
            let rightSlideHandleFrame = mRightSlideHandle.frame
            
            print("leftSlideHandleFrame:\(leftSlideHandleFrame), rightSlideHandleFrame:\(rightSlideHandleFrame)")
            
            let slideHorizonSpacing = CGRectGetMinX(rightSlideHandleFrame) - CGRectGetMaxX(leftSlideHandleFrame)
            let rightSlideTrailingSpacing = CGRectGetMaxX(self.mSelectScopeContainnerView.bounds) - CGRectGetMaxX(rightSlideHandleFrame)
            
            var translationX = translation.x
            
            var panDir = HorizonPanDirection.None
            
            // 判断滑动方向
            if slideHorizonSpacing > 0 {
                if rightSlideTrailingSpacing > 0 {
                    // 可左可右滑动
                    if translationX > 0 {
                        // 右滑
                        panDir = .Right
                    } else {
                        // 左滑
                        panDir = .Left
                    }
                } else {
                    // 只能向左滑动
                    if translationX < 0 {
                        panDir = .Left
                    }
                }
                
            } else {
                // 只能向右滑动
                if rightSlideTrailingSpacing > 0 && translationX > 0 {
                    panDir = .Right
                }
            }
            
            switch panDir {
            case .Right:
                let caculateNextTimeRightSlideTrailingSpacing = rightSlideTrailingSpacing - translationX
                if caculateNextTimeRightSlideTrailingSpacing < 0 {
                    translationX = rightSlideTrailingSpacing
                }
            case .Left:
                let caculateNextTimeSlideSpacing = slideHorizonSpacing + translationX
                if caculateNextTimeSlideSpacing < 0 {
                    translationX = -slideHorizonSpacing
                }
            case .None:
                translationX = 0
            }
            
            if translationX != 0 {
                self.mRightSlideHandleLeading.constant += translationX
                recognizer.setTranslation(CGPointMake(0, translation.y), inView: recognizer.view)
            }
            
        case .Ended:
        
            delegate?.selectedScopeOnCutPanel?(self, selectedScopeRange: caculateSelectScopeRange())
            
        default:
            print("")
        }
    }
    
    class func instanceFromNib() -> SECCutPanelView {
        return UINib(nibName: "SECCutPanelView", bundle: nil).instantiateWithOwner(nil, options: nil).first as! SECCutPanelView
    }
    
    override func awakeFromNib() {
        setupCutPanelView()
    }
    
    private func setupCutPanelView() {
        self.playProgress = 0
        self.defaultSelectedRange = SECRecordRange(location: 0.0, length: 0)
        self.isPlaying = false
    }
    
    /**
     轨迹总长度
     */
    private func trackTotalWidth() -> CGFloat {
        
        return CGRectGetWidth(self.mSelectScopeContainnerView.bounds) - self.mLeftUnactiveTrackLineLeading.constant - self.mRightUnactiveTrackLineTrailing.constant;
    }
    
    /**
     是否可以滑动左滑块
     
     - returns:
     */
    private func shouldSlideLeftHandle() -> Bool {
        return true
    }
    
    /**
     是否可以滑动右滑块
     
     - returns:
     */
    private func shouldSlideRightHandle() -> Bool {
        return true
    }
    
    /**
     计算滑块选择范围
     
     - returns:
     */
    private func caculateSelectScopeRange() -> SECRecordRange {
        
        let trackTotalWidth = self.trackTotalWidth()
        let selectedScopeWidth = CGRectGetWidth(self.mSelectedRangeOverlay.frame)
        let leftSlideHandleMinX = CGRectGetMinX(self.mLeftSlideHandle.frame)
        
        if trackTotalWidth > 0 {
            return SECRecordRange(location: leftSlideHandleMinX/trackTotalWidth, length: selectedScopeWidth/trackTotalWidth)
        } else {
            return SECRecordRange(location: 0, length: 0)
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer.isKindOfClass(UIPanGestureRecognizer) == false {
            return false
        }
        
        delegate?.willSlideScopeHandleOnCutPanel?(self)
        
        return true
    }
}
