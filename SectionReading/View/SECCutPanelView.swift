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
    @objc optional func clickedBackButtonOnCutPanel(_ panel: SECCutPanelView)
    
    /**
     点击播放按钮
     
     - parameter panel:
     */
    @objc optional func clickedPlayRecordButtonOnCutPanel(_ panel: SECCutPanelView)
    
    /**
     点击裁剪按钮
     
     - parameter panel:
     */
    @objc optional func clickedScissorsButtonOnCutPanel(_ panel: SECCutPanelView)
    
    /**
     将要滑动范围选择滑块
     
     - parameter panel:
     */
    @objc optional func willSlideScopeHandleOnCutPanel(_ panel: SECCutPanelView)
    
    /**
     已选择范围
     
     - parameter panel:
     - parameter selectedScopeRange: 已选范围
     */
    @objc optional func selectedScopeOnCutPanel(_ panel: SECCutPanelView, selectedScopeRange: SECRecordRange)
}


/**
 *  剪切面板视图
 */
class SECCutPanelView: UIView, UIGestureRecognizerDelegate {
    
    @IBOutlet fileprivate weak var mSelectScopeContainnerView: UIView!
    @IBOutlet fileprivate weak var mSelectScopeBackgroundImageView: UIImageView!
    @IBOutlet fileprivate weak var mBackButton: UIButton!
    @IBOutlet fileprivate weak var mPlayButton: UIButton!
    @IBOutlet fileprivate weak var mScissorsButton: UIButton!
    @IBOutlet fileprivate weak var mLeftSlideHandle: UIImageView!
    @IBOutlet fileprivate weak var mRightSlideHandle: UIImageView!
    @IBOutlet fileprivate weak var mSelectedRangeOverlay: UIView!
    @IBOutlet fileprivate weak var mBackgroundTrackLine: UIView!
    @IBOutlet fileprivate weak var mActiveTrackLine: UIView!
    
    @IBOutlet fileprivate weak var mActiveTrackLineWidth: NSLayoutConstraint!
    @IBOutlet fileprivate weak var mLeftSlideHandleTrailing: NSLayoutConstraint!
    @IBOutlet fileprivate weak var mRightSlideHandleLeading: NSLayoutConstraint!
    @IBOutlet weak var mBackgroundTrackLineLeading: NSLayoutConstraint!
    @IBOutlet weak var mBackgroundTrackLineTrailing: NSLayoutConstraint!
    
    
    /**
     水平拽动方向
     
     - None:  无
     - Left:  向左
     - Right: 向右
     */
    fileprivate enum HorizonPanDirection {
        case none
        case left
        case right
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
            
            // 更新进度
            self.mActiveTrackLineWidth.constant = self.mSelectedRangeOverlay.bounds.width * playProgress
        }
    }
    
    /**
     *  播放进度,范围在 0 - 1 之间
     */
    var playProgress: CGFloat = 0 {
        didSet {
            
            // 更新进度
            self.mActiveTrackLineWidth.constant = self.mSelectedRangeOverlay.bounds.width * playProgress
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
            self.mPlayButton.setImage(playButtonImage, for: UIControlState())
            self.mPlayButton.setImage(playButtonHLImage, for: UIControlState.highlighted)
            self.mPlayButton.setImage(playButtonDisabledImage, for: UIControlState.disabled)
        }
    }
    
    @IBAction func clickedBackButton(_ button: UIButton) {
        self.delegate?.clickedBackButtonOnCutPanel?(self)
    }
    
    @IBAction func clickedPlayButton(_ button: UIButton) {
        self.delegate?.clickedPlayRecordButtonOnCutPanel?(self)
    }
    
    @IBAction func clickedScissorsButton(_ button: UIButton) {
        self.delegate?.clickedScissorsButtonOnCutPanel?(self)
    }
    
    /**
     左滑块滑动触发方法
     
     - parameter recognizer:
     */
    @IBAction func leftSlideHandlePanRecognized(_ recognizer: UIPanGestureRecognizer) {
        
        print("leftSlideHandlePanRecognized")
        
        let translation = recognizer.translation(in: recognizer.view)
        let state = recognizer.state
        
        switch state {
        case .changed:
            
            let leftSlideHandleFrame = mLeftSlideHandle.frame
            let rightSlideHandleFrame = mRightSlideHandle.frame
            
            print("leftSlideHandleFrame:\(leftSlideHandleFrame), rightSlideHandleFrame:\(rightSlideHandleFrame)")
            
            
            let slideHorizonSpacing = rightSlideHandleFrame.minX - leftSlideHandleFrame.maxX
            let leftSlideLeadingSpacing = leftSlideHandleFrame.minX
            
            var translationX = translation.x
            var panDir = HorizonPanDirection.none
            
            // 判断滑动方向
            if slideHorizonSpacing > 0 {
                if leftSlideLeadingSpacing > 0 {
                    // 可左可右滑动
                    if translationX > 0 {
                        // 右滑
                        panDir = .right
                    } else {
                        // 左滑
                        panDir = .left
                    }
                } else {
                    // 只能向右滑动
                    if translationX > 0 {
                        panDir = .right
                    }
                }
            } else {
                // 只能向左滑动
                if leftSlideLeadingSpacing > 0 && translationX < 0 {
                    panDir = .left
                }
            }
            
            switch panDir {
            case .right:
                let caculateNextTimeSlideSpacing = slideHorizonSpacing - translationX
                if caculateNextTimeSlideSpacing < 0 {
                    translationX = slideHorizonSpacing
                }
            case .left:
                let caculateNextTimeLeftSlideLeadingSpacing = leftSlideLeadingSpacing + translationX
                if caculateNextTimeLeftSlideLeadingSpacing < 0 {
                    translationX = -leftSlideLeadingSpacing
                }
            case .none:
                translationX = 0
            }
            
            if translationX != 0 {
                self.mLeftSlideHandleTrailing.constant += translationX
                recognizer.setTranslation(CGPoint(x: 0, y: translation.y), in: recognizer.view)
            }
    
        case .ended:
            
            delegate?.selectedScopeOnCutPanel?(self, selectedScopeRange: caculateSelectScopeRange())
            
        default:
            print("")
        }
    }
    
    /**
     右滑块滑动触发方法
     
     - parameter recognizer:
     */
    @IBAction func rightSlideHandlePanRecognized(_ recognizer: UIPanGestureRecognizer) {
        
        print("rightSlideHandlePanRecognized")
        
        let translation = recognizer.translation(in: recognizer.view)
        let state = recognizer.state
        
        switch state {
        case .changed:
            
            let leftSlideHandleFrame = mLeftSlideHandle.frame
            let rightSlideHandleFrame = mRightSlideHandle.frame
            
            print("leftSlideHandleFrame:\(leftSlideHandleFrame), rightSlideHandleFrame:\(rightSlideHandleFrame)")
            
            let slideHorizonSpacing = rightSlideHandleFrame.minX - leftSlideHandleFrame.maxX
            let rightSlideTrailingSpacing = self.mSelectScopeContainnerView.bounds.maxX - rightSlideHandleFrame.maxX
            
            var translationX = translation.x
            
            var panDir = HorizonPanDirection.none
            
            // 判断滑动方向
            if slideHorizonSpacing > 0 {
                if rightSlideTrailingSpacing > 0 {
                    // 可左可右滑动
                    if translationX > 0 {
                        // 右滑
                        panDir = .right
                    } else {
                        // 左滑
                        panDir = .left
                    }
                } else {
                    // 只能向左滑动
                    if translationX < 0 {
                        panDir = .left
                    }
                }
                
            } else {
                // 只能向右滑动
                if rightSlideTrailingSpacing > 0 && translationX > 0 {
                    panDir = .right
                }
            }
            
            switch panDir {
            case .right:
                let caculateNextTimeRightSlideTrailingSpacing = rightSlideTrailingSpacing - translationX
                if caculateNextTimeRightSlideTrailingSpacing < 0 {
                    translationX = rightSlideTrailingSpacing
                }
            case .left:
                let caculateNextTimeSlideSpacing = slideHorizonSpacing + translationX
                if caculateNextTimeSlideSpacing < 0 {
                    translationX = -slideHorizonSpacing
                }
            case .none:
                translationX = 0
            }
            
            if translationX != 0 {
                self.mRightSlideHandleLeading.constant += translationX
                recognizer.setTranslation(CGPoint(x: 0, y: translation.y), in: recognizer.view)
            }
            
        case .ended:
        
            delegate?.selectedScopeOnCutPanel?(self, selectedScopeRange: caculateSelectScopeRange())
            
        default:
            print("")
        }
    }
    
    class func instanceFromNib() -> SECCutPanelView {
        return UINib(nibName: "SECCutPanelView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! SECCutPanelView
    }
    
    override func awakeFromNib() {
        setupCutPanelView()
    }
    
    fileprivate func setupCutPanelView() {
        self.playProgress = 0
        self.defaultSelectedRange = SECRecordRange(location: 0.0, length: 0)
        self.isPlaying = false
    }
    
    /**
     轨迹总长度
     */
    fileprivate func trackTotalWidth() -> CGFloat {
        
        return self.mSelectScopeContainnerView.bounds.width - self.mBackgroundTrackLineLeading.constant - self.mBackgroundTrackLineTrailing.constant;
    }
    
    /**
     是否可以滑动左滑块
     
     - returns:
     */
    fileprivate func shouldSlideLeftHandle() -> Bool {
        return true
    }
    
    /**
     是否可以滑动右滑块
     
     - returns:
     */
    fileprivate func shouldSlideRightHandle() -> Bool {
        return true
    }
    
    /**
     计算滑块选择范围
     
     - returns:
     */
    fileprivate func caculateSelectScopeRange() -> SECRecordRange {
        
        let trackTotalWidth = self.trackTotalWidth()
        let selectedScopeWidth = self.mSelectedRangeOverlay.frame.width
        let leftSlideHandleMinX = self.mLeftSlideHandle.frame.minX
        
        if trackTotalWidth > 0 {
            return SECRecordRange(location: leftSlideHandleMinX/trackTotalWidth, length: selectedScopeWidth/trackTotalWidth)
        } else {
            return SECRecordRange(location: 0, length: 0)
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) == false {
            return false
        }
        
        delegate?.willSlideScopeHandleOnCutPanel?(self)
        
        return true
    }
}
