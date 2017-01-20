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

    override class var layerClass : AnyClass {
        return AngleGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.tintColor = UIColor(white: 1, alpha: 0.6)
    }
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.tintColor = UIColor(white: 1, alpha: 0.6)
    }
    
    override func tintColorDidChange() {
        setColor(self.tintColor)
    }
    
    fileprivate func setColor(_ color: UIColor) {
        let alpha = color.cgColor.alpha
        
        let l: AngleGradientLayer = self.layer as! AngleGradientLayer
        l.colors = [color.cgColor, color.withAlphaComponent(alpha*(CGFloat(0.1)/CGFloat(0.6))).cgColor, UIColor.clear.cgColor]
        
        if l.locations == nil || l.locations!.count == 0 {
            l.locations = [0, 0.1, 1]
        }
    }
}
