//
//  RSProgressView.swift
//  SectionReading
//
//  Created by guangbo on 15/9/17.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

/** Helper Functions **/

func ToRadian(_ degree: CGFloat) -> CGFloat {
    return CGFloat(M_PI * Double(degree/180.0))
}

func ToDegree(_ radian: CGFloat) -> CGFloat {
    return CGFloat(Double(radian * 180.0)/M_PI)
}

func min(_ x1:CGFloat = 0, x2: CGFloat = 0) -> CGFloat {
    return x1 < x2 ? x1:x2
}

class RSProgressView: UIView {

    var progress: CGFloat = 0 /** 进度，0 - 1 之间 */
        {
            didSet {
                setNeedsDisplay()
                
                if progress > 0 {
                    if progressLabel == nil {
                        
                        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                        
                        label.backgroundColor = UIColor.clear
                        label.textColor = self.tintColor
                        label.font = UIFont.systemFont(ofSize: 10)
                        label.textAlignment = NSTextAlignment.center
                        
                        progressLabel = label
                        self.addSubview(progressLabel!)
                    }
                }
                
                // 转动角度
                
                let radius = min((self.bounds.width - progressLineWidth)/2, (self.bounds.height - progressLineWidth)/2)
                
                let arcCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                
                
                let rotateRadian = RSProgressView.rotateRadianWithProgress(progress)
                let locateRadian = ToRadian(-90.0) + rotateRadian
                let labelCenterX = arcCenter.x + (radius + 15.0) * CGFloat(cosf(Float(locateRadian)))
                let labelCenterY = arcCenter.y + (radius + 15.0) * CGFloat(sinf(Float(locateRadian)))
                
                progressLabel?.center = CGPoint(x: labelCenterX, y: labelCenterY)
            }
    }
    
    var progressLineWidth: CGFloat = 4 /** 进度线的宽度 */
        {
        didSet {
            setNeedsDisplay()
        }
    }
    
    fileprivate (set) var progressLabel: UILabel? /** 进度文字视图 */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupProgressView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupProgressView()
    }

    override func tintColorDidChange() {
        progressLabel?.textColor = self.tintColor
    }
    
    override func draw(_ rect: CGRect) {
        
        let radius = min((rect.width - progressLineWidth)/2, (rect.height - progressLineWidth)/2)
        
        // 居中
        
        let arcCenter = CGPoint(x: rect.midX, y: rect.midY)
        
        let arcPath = UIBezierPath(arcCenter:arcCenter,
            radius:radius,
            startAngle:ToRadian(-90.0),
            endAngle:(ToRadian(-90.0) + RSProgressView.rotateRadianWithProgress(progress)),
            clockwise: true)
        arcPath.lineCapStyle = CGLineCap.round
        arcPath.lineWidth = progressLineWidth
        tintColor.setStroke()
        arcPath.stroke()
    }
    
    fileprivate func setupProgressView() {
        tintColor = UIApplication.shared.keyWindow?.tintColor
    }
    
    fileprivate static func rotateRadianWithProgress(_ progress: CGFloat) -> CGFloat {
        
        var mProgress = progress
        if mProgress < 0 {
            mProgress = 0
        } else if mProgress > 1 {
            mProgress = 1
        }
        return CGFloat(2.0*M_PI*Double(mProgress))
    }
}
