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

    var selectedScope: CGFloat = 0                              /** 选择范围，范围从 0 到 1 */
    {
        didSet {
            
            // 计算旋转角度
            let selectScopeDegree = CDPlaySlider.rotateDegreeWithScope(selectedScope)
            if self.selectScopeDegree != selectScopeDegree {
                self.selectScopeDegree = selectScopeDegree
            }
        }
    }
    
    private var selectScopeDegree: CGFloat = 0                  /** 选择范围的角度, 从顶部最高点顺时针开始计算 */
    {
        didSet {
            
            print("selectScopeDegree:\(selectScopeDegree)")
            
            let locateDegree = (selectScopeDegree + 270.0) % 360.0
            
            print("locateDegree:\(locateDegree)")
            
            let newTransform = CGAffineTransformRotate(CGAffineTransformIdentity, ToRadian(locateDegree))
//
//            // 更新 ui
            scopeGradientView?.transform = newTransform
            handleContainer?.transform = newTransform
        }
    }
    
    private (set) var cdTrackView: MultipleArcTracksView?   /* CD 轨道视图 */
    private (set) var progressView: RSProgressView?         /* 进度视图 */
    private var scopeGradientView: ScopeGradientView?       /* 范围选择区域渐变视图 */
    
    private var handleContainer: UIView?                    /* 范围选择手柄容器视图 */
    private var scopeHandleView: ScopeHandleView?           /* 范围选择手柄 */
    
    private var beginTouchPoint: CGPoint?                   /** 开始触碰的点 */
    
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
        cdTrackView?.userInteractionEnabled = false
        cdTrackView?.backgroundColor = UIColor.clearColor()
        cdTrackView?.trackColors = [UIColor(red: 0x19/255.0, green: 0x6f/255.0, blue: 0x8c/255.0, alpha: 1), UIColor.clearColor(), UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)]
        cdTrackView?.trackLineWidths = [30, 2, 68]
        
        // 设置 progressView
        
        progressView = RSProgressView()
        self.addSubview(progressView!)
        
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        progressView?.userInteractionEnabled = false
        progressView?.backgroundColor = UIColor.clearColor()
        progressView?.tintColor = UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)
        progressView?.progressLineWidth = PlayProgressViewLineWidth
        progressView?.clipsToBounds = false
        
        
        // 设置 scopeHandleView
        
        handleContainer = UIView()
        self.addSubview(handleContainer!)
        
        handleContainer?.translatesAutoresizingMaskIntoConstraints = false
        handleContainer?.userInteractionEnabled = false
        
        scopeHandleView = ScopeHandleView()
        handleContainer?.addSubview(scopeHandleView!)
        
        scopeHandleView?.alpha = 1
        scopeHandleView?.translatesAutoresizingMaskIntoConstraints = false
        scopeHandleView?.userInteractionEnabled = false
        scopeHandleView?.handleSize = 20
        scopeHandleView?.handlebarWidth = 2
        scopeHandleView?.handleShadowWidth = 2
        scopeHandleView?.tintColor = UIColor(red: 0x19/255.0, green: 0x6f/255.0, blue: 0x8c/255.0, alpha: 1)
        
        // 设置 scopeGradientView
        
        let size = CDTrackSize + 2*PlayProgressViewInnerSpacing + 2*progressView!.progressLineWidth
        
        scopeGradientView = ScopeGradientView(frame: CGRectMake(0, 0, size, size))
        self.insertSubview(scopeGradientView!, belowSubview: handleContainer!)
        
        scopeGradientView?.translatesAutoresizingMaskIntoConstraints = false
        scopeGradientView?.alpha = 1
        scopeGradientView?.userInteractionEnabled = false
        scopeGradientView?.backgroundColor = UIColor.clearColor()
        scopeGradientView?.layer.cornerRadius = CGRectGetMidX(scopeGradientView!.frame)
        scopeGradientView?.layer.masksToBounds = true
        
        
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
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: progressView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: progressView!, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: scopeHandleView!.handleSize + scopeHandleView!.handleShadowWidth*2))
        
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: handleContainer!, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: handleContainer!, attribute: NSLayoutAttribute.Width, multiplier: 0.5, constant:0))
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: handleContainer!, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: handleContainer!, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        
    }
    
    private static func rotateDegreeWithScope(scope: CGFloat) -> CGFloat {
        
        var mScope = scope
        if mScope < 0 {
            mScope = 0
        } else if mScope > 1 {
            mScope = 1
        }
        return CGFloat(360.0 * Double(mScope))
    }
    
    /**
     计算两点间的角度
     
     - parameter p1:
     - parameter p2:
     
     - returns: 角度
     */
    private static func RadiansFromNorth(p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        var v = CGPointMake(p2.x - p1.x, p2.y - p1.y)
        let vmag = sqrt(v.x * v.x + v.y * v.y)
        v.x /= vmag
        v.y /= vmag
        let radians = atan2(v.y, v.x)
        return radians
    }
    
    
    private func didMovedToPoint(point: CGPoint) {
        
        // 计算旋转角度
        let arcCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        print("arcCenter: \(arcCenter), point: \(point  )")
        
        let radians = CDPlaySlider.RadiansFromNorth(point, arcCenter)
        print("radians:\(radians)")
        print("degree: \(ToDegree(radians))")
        
        // 转换圆周, 从顶点为 0 度算起, 顺时针增大角度
        
        self.selectScopeDegree = (ToDegree(radians) + 270.0) % 360.0
        self.selectedScope = self.selectScopeDegree/360.0
    }
    
    // MARK: UIControl Override
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        super.beginTrackingWithTouch(touch, withEvent: event)
        
        beginTouchPoint = touch.locationInView(self)
        didMovedToPoint(beginTouchPoint!)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.scopeHandleView?.alpha = 1
            self.scopeGradientView?.alpha = 1
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
            self.scopeHandleView?.alpha = 0
            self.scopeGradientView?.alpha = 0
            }) { (finished) -> Void in
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }
    }
}
