//
//  ScopeHandleView.swift
//  SectionReading
//
//  Created by guangbo on 15/10/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class ScopeHandleView: UIView {

    var handlebarWidth: CGFloat = 0
    {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var handleSize: CGFloat = 0
    {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var handleShadowWidth: CGFloat = 0
    {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScopeHandleView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupScopeHandleView()
    }
    
    override func tintColorDidChange() {
        setNeedsDisplay()
    }
    
    fileprivate func setupScopeHandleView() {
        self.tintColor = UIColor(white: 1, alpha: 0.6)
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
    
        let viewWidth = rect.width
        let viewMidY = rect.midY
        let handleCenterX = viewWidth - self.handleSize/2 + self.handleShadowWidth
        
        let ctx = UIGraphicsGetCurrentContext()
        
        self.tintColor.set()
        
        // 画 handle bar
        
        ctx?.setLineWidth(self.handlebarWidth)
        ctx?.setLineCap(CGLineCap.round)
        ctx?.move(to: CGPoint(x: 0, y: viewMidY))
        ctx?.addLine(to: CGPoint(x: handleCenterX, y: viewMidY))
        ctx?.drawPath(using: CGPathDrawingMode.stroke)
        
        // 画 handle
        ctx?.saveGState();
        
        ctx?.beginPath();
        ctx?.addArc(center: CGPoint(x:handleCenterX, y: viewMidY), radius: self.handleSize/2, startAngle: 0, endAngle: CGFloat(M_PI)*2, clockwise: true)
        ctx?.drawPath(using: CGPathDrawingMode.fill)
        
        // 画阴影
        if self.handleShadowWidth > 0 {
            ctx?.setShadow(offset: CGSize(width: 0, height: 0), blur: self.handleShadowWidth*2, color: self.tintColor.cgColor);
        }
        ctx?.restoreGState();
        
    }
}
