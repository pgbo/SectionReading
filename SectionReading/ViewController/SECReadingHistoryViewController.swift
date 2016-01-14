//
//  SECReadingHistoryViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import UITableView_FDTemplateLayoutCell

/**
 *  读书纪录列表页面
 *  先展示本地数据、然后接收印象笔记同步下载通知并更新数据
 */
class SECReadingHistoryViewController: UITableViewController, SECReadingHistoryTableViewCellDelegate {

    private var readings: [TReading]?
    
    private lazy var mNewRecordBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "新建", style: UIBarButtonItemStyle.Plain, target: self, action: "toAddNewRecord")
        return item
    }()
    
    private lazy var mSettingBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "设置", style: UIBarButtonItemStyle.Plain, target: self, action: "toSetting")
        return item
    }()
    
    class func instanceFromSB() -> SECReadingHistoryViewController {
        return UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewControllerWithIdentifier("SECReadingHistoryViewController") as! SECReadingHistoryViewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: UITableViewStyle.Grouped)
    }
  
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
  
    override func viewDidLoad() {
       
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "recvEvernoteManagerSycnDownStateDidChangeNote:", name: SECEvernoteManagerSycnDownStateDidChangeNotification, object: nil)
        
        self.navigationItem.title = "读书记录"
        self.navigationItem.leftBarButtonItem = self.mNewRecordBarItem
        self.navigationItem.rightBarButtonItem = self.mSettingBarItem
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        self.refreshControl?.beginRefreshing()
        TReading.filterByOption(nil, completion: { [weak self] (results) -> Void in
            if let strongSelf = self {
                strongSelf.refreshControl?.endRefreshing()
                
                print("Reading count: \(results != nil ?results!.count :0)")
                strongSelf.readings = results
                strongSelf.tableView.reloadData()
            }
            })
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SECEvernoteManagerSycnDownStateDidChangeNotification, object: nil)
    }
    
    @objc private func refresh() {
    
        TReading.filterByOption(nil, completion: { [weak self] (results) -> Void in
            if let strongSelf = self {
                strongSelf.refreshControl?.endRefreshing()
                
                print("Reading count: \(results != nil ?results!.count :0)")
                strongSelf.readings = results
                strongSelf.tableView.reloadData()
            }
            })
    }
    
    @objc private func recvEvernoteManagerSycnDownStateDidChangeNote(note: NSNotification) {
        
        print("recv SECEvernoteManagerSycnDownStateDidChangeNotification.")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            if self.navigationController?.topViewController != self {
                let currentSyncDownState = note.userInfo?[SECEvernoteManagerNotificationSycnDownStateItem] as? Bool
                let syncDownNumber = note.userInfo?[SECEvernoteManagerNotificationSuccessSycnDownNoteCountItem] as? Int
                if currentSyncDownState == false && syncDownNumber > 0 {
                    TReading.filterByOption(nil, completion: { [weak self] (results) -> Void in
                        if let strongSelf = self {
                            print("Reading count: \(results != nil ?results!.count :0)")
                            strongSelf.readings = results
                            strongSelf.tableView.reloadData()
                        }
                        })
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc private func toAddNewRecord() {
        
        let nav = UINavigationController(rootViewController: SECNewReadingViewController.instanceFromSB())
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    @objc private func toSetting() {
       
        self.navigationController?.showViewController(SECSettingViewController.instanceFromSB(), sender: nil)
    }
    

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return readings != nil ?readings!.count :0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCellWithIdentifier("SECReadingHistoryTableViewCell", forIndexPath: indexPath) as! SECReadingHistoryTableViewCell
        cell.delegate = self
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    private func configureCell(cell: SECReadingHistoryTableViewCell, atIndexPath indexPath: NSIndexPath) {
    
        let reading = readings![indexPath.row]
        cell.configure(withReading: reading)
    }
    
    // MARK: -  UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return tableView.fd_heightForCellWithIdentifier("SECReadingHistoryTableViewCell", cacheByIndexPath: indexPath, configuration: { (cell) -> Void in
            self.configureCell(cell as! SECReadingHistoryTableViewCell, atIndexPath: indexPath)
        })
    }
    
    // MARK: - SECReadingHistoryTableViewCellDelegate
    
    func clickEditButtonIn(cell: SECReadingHistoryTableViewCell) {
        
        print("clickEditButtonIn.")
    }
    
    func clickTrashButtonIn(cell: SECReadingHistoryTableViewCell) {
        
        print("clickTrashButtonIn.")
    }
    
    func clickShareButtonIn(cell: SECReadingHistoryTableViewCell) {
        
        print("clickShareButtonIn.")
        let indexPath = indexPathOfCell(cell)
        if indexPath != nil {
            if let reading = readings?[indexPath!.row] {
                self.navigationController?.showViewController(SECShareReadingViewController.instanceFromSB(withShareReadingLocalId: reading.fLocalId!), sender: nil)
            }
        }
    }
    
    func clickPlayAudioButtonIn(cell: SECReadingHistoryTableViewCell) {
    
        print("clickPlayAudioButtonIn.")
    }
    
    private func indexPathOfCell(cell: UITableViewCell) -> NSIndexPath? {
        
        let cellBounds = cell.bounds
        let cellCenter = cell.convertPoint(CGPointMake(CGRectGetMidX(cellBounds), CGRectGetMidY(cellBounds)), toView:self.tableView)
        return self.tableView.indexPathForRowAtPoint(cellCenter)
    }
}
