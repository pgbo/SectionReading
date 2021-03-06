//
//  CircularButton.swift
//  SectionReading
//
//  Created by guangbo on 15/11/5.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

/// 圆形按钮
class CircularButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.frame
        self.layer.cornerRadius = fmax(frame.width, frame.height)/2
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 1.0
        self.layer.masksToBounds = true
    }
}
