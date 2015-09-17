//
//  RSProgressView.swift
//  SectionReading
//
//  Created by guangbo on 15/9/17.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

/** Helper Functions **/

func ToRadian(degree: CGFloat) -> CGFloat {
    return CGFloat(M_PI * Double(degree/180.0))
}

func ToDegree(radian: CGFloat) -> CGFloat {
    return CGFloat(Double(radian * 180.0)/M_PI)
}

class RSProgressView: UIView {

    var progress: CGFloat = 0 /** 进度，0 - 1 之间 */
        {
            didSet {
                setNeedsDisplay()
                
                if progress > 0 {
                    if progressLabel == nil {
                        
                        let label = UILabel(frame: CGRectMake(0, 0, 24, 24))
                        
                        label.backgroundColor = UIColor.clearColor()
                        label.textColor = self.tintColor
                        label.font = UIFont.systemFontOfSize(10)
                        
                        progressLabel = label
                        self.addSubview(progressLabel!)
                    }
                }
                
                // 转动角度
                
                let (arcCenter, radius) = RSProgressView.yieldArcAtRect(bounds)
                
                let rotateRadian = RSProgressView.rotateRadianWithProgress(progress)
                let labelCenterX = arcCenter.x + (radius + 15.0) * CGFloat(sinf(Float(rotateRadian)))
                let labelCenterY = arcCenter.y + (radius + 15.0) * CGFloat(cosf(Float(rotateRadian)))
                
                progressLabel?.center = CGPointMake(labelCenterX, labelCenterY)
            }
    }
    
    var progressLineWidth: CGFloat = 4 /** 进度线的宽度 */
        {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private (set) var progressLabel: UILabel? /** 进度文字视图 */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupProgressView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupProgressView()
    }

    override func tintColorDidChange() {
        progressLabel?.textColor = self.tintColor
    }
    
    override func drawRect(rect: CGRect) {
        
        let (arcCenter, radius) = RSProgressView.yieldArcAtRect(rect)
        
        let arcPath = UIBezierPath(arcCenter:arcCenter,
            radius:radius,
            startAngle:ToRadian(-90.0),
            endAngle:(ToRadian(-90.0) + RSProgressView.rotateRadianWithProgress(progress)),
            clockwise: true)
        arcPath.lineCapStyle = kCGLineCapRound
        arcPath.lineWidth = progressLineWidth
        tintColor.setStroke()
        arcPath.stroke()
    }
    
    private func setupProgressView() {
        tintColor = UIApplication.sharedApplication().keyWindow?.tintColor
    }
    
    private static func rotateRadianWithProgress(progress: CGFloat) -> CGFloat {
        
        var mProgress = progress
        if mProgress < 0 {
            mProgress = 0
        } else if mProgress > 1 {
            mProgress = 1
        }
        return CGFloat(2.0*M_PI*Double(mProgress))
    }
    
    private static func yieldArcAtRect(rect: CGRect) -> (CGPoint, CGFloat) {
        let halfWidth = rect.size.width/2
        let halfHeight = rect.size.height/2
        let radius = halfWidth > halfHeight ? halfHeight:halfWidth
        return (CGPointMake(halfWidth, halfHeight), radius)
    }
}
