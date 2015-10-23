//
//  CDPlaySlider.swift
//  SectionReading
//
//  Created by guangbo on 15/10/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AngleGradientLayer

let CDTrackSize = CGFloat(200)
let PlayProgressViewInnerSpacing = CGFloat(1)
let PlayProgressViewLineWidth = CGFloat(2)

/// CD 样式的播放滑动条
class CDPlaySlider: UIControl {

    private (set) var cdTrackView: MultipleArcTracksView?       /* CD 轨道视图 */
    private (set) var progressView: RSProgressView?             /* 进度视图 */
    private (set) var scopeGradientView: ScopeGradientView?     /* 范围选择区域渐变视图 */
    private (set) var scopeHandleView: ScopeHandleView?         /* 范围选择手柄 */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCDPlaySlider()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCDPlaySlider()
    }
    
    private func setupCDPlaySlider() {
        
        // 设置 cdTrackView
        self.backgroundColor = UIColor.clearColor()
        
        cdTrackView = MultipleArcTracksView()
        self.addSubview(cdTrackView!)
        
        cdTrackView?.translatesAutoresizingMaskIntoConstraints = false
        cdTrackView?.backgroundColor = UIColor.clearColor()
        cdTrackView?.trackColors = [UIColor(red: 0x19/255.0, green: 0x6f/255.0, blue: 0x8c/255.0, alpha: 1), UIColor.clearColor(), UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)]
        cdTrackView?.trackLineWidths = [30, 2, 68]
        
        // 设置 progressView
        
        progressView = RSProgressView()
        self.addSubview(progressView!)
        
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        progressView?.backgroundColor = UIColor.clearColor()
        progressView?.tintColor = UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)
        progressView?.progressLineWidth = PlayProgressViewLineWidth
        progressView?.clipsToBounds = false
        
        // 设置 scopeGradientView
        
        scopeGradientView = ScopeGradientView()
        self.addSubview(scopeGradientView!)
        
        scopeGradientView?.alpha = 0
        scopeGradientView?.translatesAutoresizingMaskIntoConstraints = false
        scopeGradientView?.backgroundColor = UIColor.clearColor()
        
        // 设置 scopeHandleView
        
        scopeHandleView = ScopeHandleView()
        self.addSubview(scopeHandleView!)
        
        scopeHandleView?.alpha = 0
        scopeHandleView?.translatesAutoresizingMaskIntoConstraints = false
        scopeHandleView?.backgroundColor = UIColor.clearColor()
        scopeHandleView?.handleSize = 10
        scopeHandleView?.handlebarWidth = 2
        scopeHandleView?.handleShadowWidth = 2
        scopeHandleView?.tintColor = UIColor(red: 0x19/255.0, green: 0x6f/255.0, blue: 0x8c/255.0, alpha: 1)
        
        // 设置约束
        
        // cdTrackView
        
        self.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        cdTrackView!.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: CDTrackSize))
        
        cdTrackView!.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: cdTrackView!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
        
        // progressView
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: CDTrackSize + 2*PlayProgressViewInnerSpacing + 2*progressView!.progressLineWidth))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
        
        // scopeGradientView
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        
        
        // scopeHandleView
        
        self.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: cdTrackView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: CDTrackSize/2))
        
        self.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Width, multiplier: 0.5, constant: (scopeHandleView!.handleSize + scopeHandleView!.handleShadowWidth - progressView!.progressLineWidth)/2))
        
        self.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: scopeHandleView!.handleSize + scopeHandleView!.handleShadowWidth*2))
        
    }
    
    private func didMovedToPoint(point: CGPoint) {
        
        // TODO: 改变 scopeGradientView 和 scopeHandleView
        
    }
    
    // MARK: UIControl Override
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        super.beginTrackingWithTouch(touch, withEvent: event)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.progressView?.alpha = 1
            self.scopeHandleView?.alpha = 1
            }) { (finished) -> Void in
        }
        
        return true
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        super.continueTrackingWithTouch(touch, withEvent: event)
        
        let touchPoint = touch.locationInView(self)
        
        didMovedToPoint(touchPoint)
        
        self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        super.endTrackingWithTouch(touch, withEvent: event)
        
        // 隐藏
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.progressView?.alpha = 0
            self.scopeHandleView?.alpha = 0
            }) { (finished) -> Void in
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }
    }
    
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
}
