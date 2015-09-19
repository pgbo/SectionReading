//
//  FinishedRecordItemView.swift
//  SectionReading
//
//  Created by guangbo on 15/9/18.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class MultipleArcTracksView: UIView {
    
    var trackColors: [UIColor]? /** 轨道的颜色集合, 需要和 trackLineWidths 的集合数量保持一致，否则报错 */
        {
        didSet{
            let trackLineWidthsCount = trackLineWidths != nil ? trackLineWidths!.count:Int(0)
            let trackColorsCount = trackColors != nil ? trackColors!.count:Int(0)
            if trackLineWidthsCount == trackColorsCount {
                setNeedsDisplay()
            }
        }
    }
    
    var trackLineWidths: [CGFloat]? /** 轨道的宽度集合，需要和 trackColors 的集合数量保持一致，否则报错 */
        {
        didSet{
            let trackLineWidthsCount = trackLineWidths != nil ? trackLineWidths!.count:Int(0)
            let trackColorsCount = trackColors != nil ? trackColors!.count:Int(0)
            if trackLineWidthsCount == trackColorsCount {
                setNeedsDisplay()
            }
        }
    }
    
    override func tintColorDidChange() {
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        
        let trackLineWidthsCount = trackLineWidths != nil ? trackLineWidths!.count:Int(0)
        let trackColorsCount = trackColors != nil ? trackColors!.count:Int(0)
        if trackLineWidthsCount != trackColorsCount {
            print("trackLineWidths.count is not equal to trackLineWidths.Count")
            return
        }
        
        if trackColorsCount == 0 {
            print("trackLineWidths.count and trackLineWidths.Count is 0")
            return
        }
        
        let center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
        
        var increaseRadius = CGFloat(0)
        for var idx = 0; idx < trackLineWidthsCount; ++idx {
            let color = trackColors![idx]
            let lineWidth = trackLineWidths![idx]
            
            increaseRadius += lineWidth
            
            let path = UIBezierPath(arcCenter: center, radius: increaseRadius - lineWidth/2.0, startAngle: CGFloat(0), endAngle: CGFloat(2*M_PI), clockwise: true)
            
            path.lineWidth = lineWidth
            color.setStroke()
            path.stroke()
        }
    }
}
