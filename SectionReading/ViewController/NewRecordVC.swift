//
//  NewRecordVC.swift
//  SectionReading
//
//  Created by 彭光波 on 15/9/17.
//  Copyright (c) 2015年 pengguangbo. All rights reserved.
//

import UIKit

class NewRecordVC: UIViewController {
    
    private var recordButtonView: RecordButtonView?
    private var recordButtonViewCenterY: NSLayoutConstraint?
    private var recordButtonViewTop: NSLayoutConstraint?
    
    private var stopRecordButn: UIButton?
    private var finishedRecordContaintScroll: UIScrollView?
    
    private var taskFinished = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 0xf5/255.0, green: 0xee/255.0, blue: 0xee/255.0, alpha: 1)
        
        self.navigationItem.title = "新建读书"
        
        recordButtonView = RecordButtonView(frame: CGRectMake(0, 0, 220, 220))
        self.view.addSubview(recordButtonView!)
        
        recordButtonView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        recordButtonViewCenterY = NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        self.view.addConstraint(recordButtonViewCenterY!)
        
        self.view.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        
        recordButtonView!.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: 220))
        
        recordButtonView!.addConstraint(NSLayoutConstraint(item: recordButtonView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: recordButtonView!, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if taskFinished {
            recordButtonViewTop?.active = false
            recordButtonViewCenterY?.active = true
            
            recordButtonView?.titleLabel?.text = "录音"
            recordButtonView?.iconView?.image = UIImage(named: "RecordMicro")
        } else {
            recordButtonViewTop?.active = true
            recordButtonViewCenterY?.active = false
            
            recordButtonView?.titleLabel?.text = "继续"
            recordButtonView?.iconView?.image = UIImage(named: "RecordPaused")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
