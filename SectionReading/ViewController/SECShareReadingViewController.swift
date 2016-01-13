//
//  SECShareReadingViewController.swift
//  SectionReading
//
//  Created by guangbo on 16/1/13.
//  Copyright © 2016年 pengguangbo. All rights reserved.
//

import UIKit

class SECShareReadingViewController: UIViewController {

    private (set) var readingLocalId: String!
    
    class func instanceFromSB(withShareReadingLocalId readingLocalId: String) -> SECShareReadingViewController {
        
        let viewController = UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewControllerWithIdentifier("SECShareReadingViewController") as! SECShareReadingViewController
        viewController.readingLocalId = readingLocalId
        return viewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError("init(nibName:, bundle:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadShareReading()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func loadShareReading() {
        
        let option = ReadingQueryOption()
        option.localId = readingLocalId
        TReading.filterByOption(option) { (results) -> Void in
            // TODO: 显示在视图上
        }
    }
}
