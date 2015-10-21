//
//  ScopeGradientView.swift
//  SectionReading
//
//  Created by guangbo on 15/10/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AngleGradientLayer

class ScopeGradientView: UIView {

    override class func layerClass() -> AnyClass {
        return AngleGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setColor(UIColor(white: 1, alpha: 0.6))
    }
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setColor(UIColor(white: 1, alpha: 0.6))
    }
    
    override func tintColorDidChange() {
        setColor(self.tintColor)
    }
    
    private func setColor(color: UIColor) {
        let alpha = CGColorGetAlpha(color.CGColor)
        
        let l: AngleGradientLayer = self.layer as! AngleGradientLayer
        l.colors = [color.CGColor, color.colorWithAlphaComponent(alpha*(CGFloat(0.1)/CGFloat(0.6))).CGColor, UIColor.clearColor().CGColor]
        
        if l.locations.count == 0 {
            l.locations = [0, 0.1, 1]
        }
    }
}
