//
//  SECNewReadingViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

/**
 *  建立新读书记录页面
 */
class SECNewReadingViewController: UIViewController, SECCutPanelViewDelegate {

    @IBOutlet weak var mRecordDurationLabel: UILabel!
    @IBOutlet weak var mFirstWheel: UIImageView!
    @IBOutlet weak var mSecondWheel: UIImageView!
    @IBOutlet weak var mStopRecordButton: UIButton!
    @IBOutlet weak var mResumeRecordButton: UIButton!
    @IBOutlet weak var mScissorsRecordButton: UIButton!
    
    private lazy var mCancelBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.Plain, target: self, action: "toClosePage")
        return item
    }()
    
    private lazy var mRecordHistoryBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "列表", style: UIBarButtonItemStyle.Plain, target: self, action: "toRecordHistory")
        return item
    }()
    
    private var cutPanel: SECCutPanelView?
    private var cutPanelLeading: NSLayoutConstraint?
    private var cutPanelTrailing: NSLayoutConstraint?
    private var cutPanelWidth: NSLayoutConstraint?
    private var cutPanelHidden = false
    
    convenience init() {
        self.init(nibName:"SECNewReadingViewController", bundle:nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(red: 0xf2/255.0, green: 0xf2/255.0, blue: 0xf2/255.0, alpha: 1)
        
        self.navigationItem.title = "新建读书"
        self.navigationItem.leftBarButtonItem = self.mCancelBarItem
        self.navigationItem.rightBarButtonItem = self.mRecordHistoryBarItem
        
        // 设置 cutPanel
        cutPanel = SECCutPanelView.instanceFromNib()
        self.view.addSubview(cutPanel!)
        
        
        cutPanel?.delegate = self
        cutPanel?.translatesAutoresizingMaskIntoConstraints = false
        let views = ["cutPanel": cutPanel!]
        
        self.cutPanelLeading = NSLayoutConstraint(item: cutPanel!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        self.view.addConstraint(self.cutPanelLeading!)
        self.cutPanelLeading?.identifier = "$_cutPanelLeading"
        
        self.cutPanelTrailing = NSLayoutConstraint(item: cutPanel!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        self.view.addConstraint(self.cutPanelTrailing!)
        self.cutPanelTrailing?.identifier = "$_cutPanelTrailing"
        
        self.cutPanelWidth = NSLayoutConstraint(item: cutPanel!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: 0)
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[cutPanel(180)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        
        cutPanelHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func cutPanelHidden(hidden: Bool, animated: Bool) {
        
        let blockFunc = { [weak self] (hidden: Bool) -> Void in
            if let strongSelf = self {
                if hidden {
                    let viewWidth = CGRectGetWidth(strongSelf.view.bounds)
                    strongSelf.cutPanelLeading?.constant = viewWidth
                    
                    if strongSelf.cutPanelTrailing != nil {
                        strongSelf.view.removeConstraint(strongSelf.cutPanelTrailing!)
                    }
                    
                    if strongSelf.cutPanelWidth != nil {
                        strongSelf.cutPanelWidth!.constant = viewWidth
                        strongSelf.cutPanel?.addConstraint(strongSelf.cutPanelWidth!)
                    }
                } else {
                    strongSelf.cutPanelLeading?.constant = 0
                    
                    if strongSelf.cutPanelTrailing != nil {
                        strongSelf.view.addConstraint(strongSelf.cutPanelTrailing!)
                    }
                    
                    if strongSelf.cutPanelWidth != nil {
                        strongSelf.cutPanel?.removeConstraint(strongSelf.cutPanelWidth!)
                    }
                }
            }
        }
        
        if animated {
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.4, animations: { [weak self] () -> Void in
                if let strongSelf = self {
                    blockFunc(hidden)
                    strongSelf.view.layoutIfNeeded()
                }
                }, completion: {[weak self] (finished: Bool) -> Void in
                    if let strongSelf = self {
                        strongSelf.cutPanelHidden = hidden
                    }
                })
        } else {
            blockFunc(hidden)
            self.cutPanelHidden = hidden
        }
    }
    
    
    @objc private func toClosePage() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func toRecordHistory() {
        
    }
    
    @IBAction func clickedScissorsRecordButton(sender: UIButton) {
        if cutPanelLeading != nil {
            // TODO: 加入其他判定条件
            cutPanelHidden(!cutPanelHidden, animated: true)
        }
    }
    
    @IBAction func clickedResumeRecordButton(sender: UIButton) {
        
    }
    
    @IBAction func clickedStopRecordButton(sender: UIButton) {
        
    }
    
    // MARK: - SECCutPanelViewDelegate
    
    func clickedBackButtonOnCutPanel(panel: SECCutPanelView) {
        if cutPanelHidden == false {
            cutPanelHidden(true, animated: true)
        }
    }
}
