//
//  ReadingRecordsVC.swift
//  SectionReading
//
//  Created by 彭光波 on 15/9/16.
//  Copyright (c) 2015年 pengguangbo. All rights reserved.
//

import UIKit

let reuseIdentifier = "Cell"

/// 阅读记录 VC
class ReadingRecordsVC: UICollectionViewController {

    private var newRecordButtonWindow: UIWindow? /** 创建新纪录按钮所在的窗口 */
    private var newRecordButton: UIButton? /** 创建新记录按钮 */
    
    override init(collectionViewLayout layout: UICollectionViewLayout?) {
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 6
        flowLayout.minimumInteritemSpacing = 8
        
        super.init(collectionViewLayout: flowLayout)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        
        self.navigationItem.title = "读书记录"
        self.collectionView?.backgroundColor = UIColor.whiteColor()
        
        // Register cell classes
        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        setupNewRecordButton()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        newRecordButton?.alpha = 0
        newRecordButtonWindow?.hidden = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(1, delay: 0, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: { () -> Void in
            
                self.newRecordButton?.alpha = 1
            
            }) { (finished: Bool) -> Void in
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        newRecordButtonWindow?.hidden = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 0
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    /**
        设置创新新纪录按钮
    */
    private func setupNewRecordButton() {
        if newRecordButton == nil {
            
            let newRecordButnBgImage = UIImage(named: "NewRecordButnBg")
            let newRecordButnBgHLImage = UIImage(named: "NewRecordButnBgHL")
            let imageSize = newRecordButnBgImage!.size.height > newRecordButnBgImage!.size.width ? newRecordButnBgImage!.size.height:newRecordButnBgImage!.size.width
            
            let screenBounds = UIScreen.mainScreen().bounds
            
            newRecordButtonWindow = UIWindow(frame: CGRectMake((CGRectGetWidth(screenBounds) - imageSize)/2, CGRectGetHeight(screenBounds) - imageSize - 4, imageSize, imageSize))
            
            let mButn = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            
            mButn.frame = newRecordButtonWindow!.bounds
            
            mButn.setBackgroundImage(newRecordButnBgImage, forState: UIControlState.Normal)
            mButn.setBackgroundImage(newRecordButnBgHLImage, forState: UIControlState.Highlighted)
            
            mButn.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 8, 0)
            
            mButn.setTitle("+", forState: UIControlState.Normal)
            mButn.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            mButn.titleLabel?.font = UIFont.systemFontOfSize(48)
            mButn.addTarget(self, action: "addNewRecord", forControlEvents: UIControlEvents.TouchUpInside)
            
            newRecordButton = mButn
            newRecordButtonWindow?.addSubview(newRecordButton!)
        }
    }
    
    @objc private func addNewRecord() {
        
        self.showViewController(NewRecordVC(), sender: nil)
        
    }
}
