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
    
    fileprivate var selectScopeDegree: CGFloat = 0                  /** 选择范围的角度, 从顶部最高点顺时针开始计算 */
    {
        didSet {
            
            print("selectScopeDegree:\(selectScopeDegree)")
            
            let locateDegree = (selectScopeDegree + 270.0).truncatingRemainder(dividingBy: 360.0)
            
            print("locateDegree:\(locateDegree)")
            
            let newTransform = CGAffineTransform.identity.rotated(by: ToRadian(locateDegree))
//
//            // 更新 ui
            scopeGradientView?.transform = newTransform
            handleContainer?.transform = newTransform
        }
    }
    
    fileprivate (set) var cdTrackView: MultipleArcTracksView?   /* CD 轨道视图 */
    fileprivate (set) var progressView: RSProgressView?         /* 进度视图 */
    fileprivate var scopeGradientView: ScopeGradientView?       /* 范围选择区域渐变视图 */
    
    fileprivate var handleContainer: UIView?                    /* 范围选择手柄容器视图 */
    fileprivate var scopeHandleView: ScopeHandleView?           /* 范围选择手柄 */
    
    fileprivate var beginTouchPoint: CGPoint?                   /** 开始触碰的点 */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCDPlaySlider()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCDPlaySlider()
    }
    
    fileprivate func setupCDPlaySlider() {
        
        // 设置 cdTrackView
        self.backgroundColor = UIColor.clear
        
        cdTrackView = MultipleArcTracksView()
        self.addSubview(cdTrackView!)
        
        cdTrackView?.translatesAutoresizingMaskIntoConstraints = false
        cdTrackView?.isUserInteractionEnabled = false
        cdTrackView?.backgroundColor = UIColor.clear
        cdTrackView?.trackColors = [UIColor(red: 0x19/255.0, green: 0x6f/255.0, blue: 0x8c/255.0, alpha: 1), UIColor.clear, UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)]
        cdTrackView?.trackLineWidths = [30, 2, 68]
        
        // 设置 progressView
        
        progressView = RSProgressView()
        self.addSubview(progressView!)
        
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        progressView?.isUserInteractionEnabled = false
        progressView?.backgroundColor = UIColor.clear
        progressView?.tintColor = UIColor(red: 0x23/255.0, green: 0x96/255.0, blue: 0xBB/255.0, alpha: 1)
        progressView?.progressLineWidth = PlayProgressViewLineWidth
        progressView?.clipsToBounds = false
        
        
        // 设置 scopeHandleView
        
        handleContainer = UIView()
        self.addSubview(handleContainer!)
        
        handleContainer?.translatesAutoresizingMaskIntoConstraints = false
        handleContainer?.isUserInteractionEnabled = false
        
        scopeHandleView = ScopeHandleView()
        handleContainer?.addSubview(scopeHandleView!)
        
        scopeHandleView?.alpha = 1
        scopeHandleView?.translatesAutoresizingMaskIntoConstraints = false
        scopeHandleView?.isUserInteractionEnabled = false
        scopeHandleView?.handleSize = 20
        scopeHandleView?.handlebarWidth = 2
        scopeHandleView?.handleShadowWidth = 2
        scopeHandleView?.tintColor = UIColor(red: 0x19/255.0, green: 0x6f/255.0, blue: 0x8c/255.0, alpha: 1)
        
        // 设置 scopeGradientView
        
        let size = CDTrackSize + 2*PlayProgressViewInnerSpacing + 2*progressView!.progressLineWidth
        
        scopeGradientView = ScopeGradientView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        self.insertSubview(scopeGradientView!, belowSubview: handleContainer!)
        
        scopeGradientView?.translatesAutoresizingMaskIntoConstraints = false
        scopeGradientView?.alpha = 1
        scopeGradientView?.isUserInteractionEnabled = false
        scopeGradientView?.backgroundColor = UIColor.clear
        scopeGradientView?.layer.cornerRadius = scopeGradientView!.frame.midX
        scopeGradientView?.layer.masksToBounds = true
        
        
        // 设置约束
        
        // cdTrackView
        
        self.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        cdTrackView!.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: CDTrackSize))
        
        cdTrackView!.addConstraint(NSLayoutConstraint(item: cdTrackView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: cdTrackView!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))
        
        
        // progressView
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: CDTrackSize + 2*PlayProgressViewInnerSpacing + 2*progressView!.progressLineWidth))
        
        progressView!.addConstraint(NSLayoutConstraint(item: progressView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: progressView!, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))
        
        
        // scopeGradientView
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: progressView!, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: progressView!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: progressView!, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: scopeGradientView!, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: progressView!, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        
        
        // scopeHandleView
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: progressView, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: progressView!, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: handleContainer!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: scopeHandleView!.handleSize + scopeHandleView!.handleShadowWidth*2))
        
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: handleContainer!, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: handleContainer!, attribute: NSLayoutAttribute.width, multiplier: 0.5, constant:0))
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: handleContainer!, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        
        handleContainer!.addConstraint(NSLayoutConstraint(item: scopeHandleView!, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: handleContainer!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        
    }
    
    fileprivate static func rotateDegreeWithScope(_ scope: CGFloat) -> CGFloat {
        
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
    fileprivate static func RadiansFromNorth(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        var v = CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)
        let vmag = sqrt(v.x * v.x + v.y * v.y)
        v.x /= vmag
        v.y /= vmag
        let radians = atan2(v.y, v.x)
        return radians
    }
    
    
    fileprivate func didMovedToPoint(_ point: CGPoint) {
        
        // 计算旋转角度
        let arcCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        print("arcCenter: \(arcCenter), point: \(point  )")
        
        let radians = CDPlaySlider.RadiansFromNorth(point, arcCenter)
        print("radians:\(radians)")
        print("degree: \(ToDegree(radians))")
        
        // 转换圆周, 从顶点为 0 度算起, 顺时针增大角度
        
        self.selectScopeDegree = (ToDegree(radians) + 270.0).truncatingRemainder(dividingBy: 360.0)
        self.selectedScope = self.selectScopeDegree/360.0
    }
    
    // MARK: UIControl Override
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        
        beginTouchPoint = touch.location(in: self)
        didMovedToPoint(beginTouchPoint!)
        
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.scopeHandleView?.alpha = 1
            self.scopeGradientView?.alpha = 1
            }, completion: { (finished) -> Void in
        }) 
        
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        let touchPoint = touch.location(in: self)
        
        didMovedToPoint(touchPoint)
        
        self.sendActions(for: UIControlEvents.valueChanged)
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        
        // 隐藏
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.scopeHandleView?.alpha = 0
            self.scopeGradientView?.alpha = 0
            }, completion: { (finished) -> Void in
                UIApplication.shared.endIgnoringInteractionEvents()
        }) 
    }
}
