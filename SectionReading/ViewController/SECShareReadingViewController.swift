//
//  SECShareReadingViewController.swift
//  SectionReading
//
//  Created by guangbo on 16/1/13.
//  Copyright © 2016年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

class SECShareReadingViewController: UIViewController {

    private (set) var readingLocalId: String!
    
    @IBOutlet weak var mScrollView: UIScrollView!
    @IBOutlet weak var mWechatButton: UIButton!
    @IBOutlet weak var mPengYQButton: UIButton!
    @IBOutlet weak var mSaveShareContentButton: UIButton!
    private lazy var mTextLayoutView: SECReadingShareLayoutView = {
        return SECReadingShareLayoutView(frame: self.mScrollView.bounds)
    }()
    
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
        self.navigationItem.title = "分享"
        
        loadShareReading()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func loadShareReading() {
        
        let option = ReadingQueryOption()
        option.localId = readingLocalId
        TReading.filterByOption(option) { (results) -> Void in
            if results != nil && results!.count > 0 {
                
                let result = results!.first
                var duration: NSTimeInterval?
                
                let audioFilePath = result!.fLocalAudioFilePath
                if audioFilePath != nil {
                    let asset = AVAsset(URL: NSURL(fileURLWithPath: audioFilePath!))
                    duration = CMTimeGetSeconds(asset.duration)
                }
                
                let model = SECReadingShareLayoutViewDataModel()
                model.text = result!.fContent
                model.readingDuration = duration
                
                // Add a hard width constraint to make dynamic content views (like labels) expand vertically instead
                // of growing horizontally, in a flow-layout manner.
                
                let layoutView = self.mTextLayoutView
                
                layoutView.configureWithModel(model)
                
                layoutView.translatesAutoresizingMaskIntoConstraints = false
                let tempWidthConstraint = NSLayoutConstraint(item: layoutView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: CGRectGetWidth(UIScreen.mainScreen().bounds))
                
                layoutView.addConstraint(tempWidthConstraint)
                // Auto layout engine does its math
                let fittingSize = layoutView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                layoutView.removeConstraint(tempWidthConstraint)
                layoutView.translatesAutoresizingMaskIntoConstraints = true
                
                layoutView.frame = CGRectMake(0, 0, fittingSize.width, fittingSize.height)
                self.mScrollView.addSubview(layoutView)
                self.mScrollView.contentSize = fittingSize
                
            } else {
                // TODO: 提示找不到记录
            }
        }
    }
}
