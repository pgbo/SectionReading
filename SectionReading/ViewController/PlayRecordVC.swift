//
//  PlayRecordVC.swift
//  SectionReading
//
//  Created by guangbo on 15/10/20.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

/// 播放录音 VC
class PlayRecordVC: UIViewController {

    private(set) var recordFilePath: String?

    convenience init(recordFilePath filePath: String) {
        self.init()
        self.recordFilePath = filePath
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
