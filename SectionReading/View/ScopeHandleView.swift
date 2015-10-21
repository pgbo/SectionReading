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
    
    private func setupScopeHandleView() {
        self.tintColor = UIColor(white: 1, alpha: 0.6)
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
    
        let viewWidth = CGRectGetWidth(rect)
        let viewMidY = CGRectGetMidY(rect)
        let handleCenterX = viewWidth - self.handleSize/2 + self.handleShadowWidth
        
        let ctx = UIGraphicsGetCurrentContext()
        
        self.tintColor.setStroke()
        
        // 画 handle bar
        
        CGContextSetLineWidth(ctx, self.handlebarWidth)
        CGContextSetLineCap(ctx, CGLineCap.Round)
        CGContextMoveToPoint(ctx, 0, viewMidY)
        CGContextAddLineToPoint(ctx, handleCenterX, viewMidY)
        CGContextDrawPath(ctx, CGPathDrawingMode.Stroke)
        
        // 画 handle
        CGContextSaveGState(ctx);
        
        CGContextBeginPath(ctx);
        CGContextAddArc(ctx, handleCenterX, viewMidY, self.handleSize/2, 0, CGFloat(M_PI)*2, 1)
        CGContextDrawPath(ctx, CGPathDrawingMode.Fill)
        
        // 画阴影
        if self.handleShadowWidth > 0 {
            CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), self.handleShadowWidth*2, self.tintColor.CGColor);
        }
        CGContextRestoreGState(ctx);
        
    }
}
