//
//  SECHelper.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECHelper: NSObject {

    static func globalCustomSetNavigationBar() {
        
        let navBarAppearance = UINavigationBar.appearance()
        
        navBarAppearance.setBackgroundImage(UIImage(named: "NavBar"), forBarMetrics: UIBarMetrics.Default)
        navBarAppearance.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(17), NSForegroundColorAttributeName: UIColor.blackColor()]
        
        navBarAppearance.tintColor = UIColor(red: 0x53/255.0, green: 0x9d/255.0, blue: 0x9f/255.0, alpha: 1)
    }
    
    static func globalCustomSetBarButtonItem() {
        
        let barButtonItemAppearance = UIBarButtonItem.appearance()
        
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14),NSForegroundColorAttributeName: UIColor(red: 0x53/255.0, green: 0x9d/255.0, blue: 0x9f/255.0, alpha: 1)], forState: UIControlState.Normal)
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14),NSForegroundColorAttributeName: UIColor(red: 0x4D/255.0, green: 0x83/255.0, blue: 0x84/255.0, alpha: 1)], forState: UIControlState.Highlighted)
        barButtonItemAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14),NSForegroundColorAttributeName: UIColor(red: 0xA0/255.0, green: 0xB0/255.0, blue: 0xB1/255.0, alpha: 1)], forState: UIControlState.Disabled)
    }
}
