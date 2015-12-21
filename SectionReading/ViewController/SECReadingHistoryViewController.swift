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
class SECReadingHistoryViewController: UITableViewController {

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
        fatalError("init(coder:) has not been implemented")
    }
  
    override func viewDidLoad() {
       
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = false
        self.view.backgroundColor = UIColor(red: 0xf2/255.0, green: 0xf2/255.0, blue: 0xf2/255.0, alpha: 1)
        
        self.navigationItem.title = "读书记录"
        self.navigationItem.leftBarButtonItem = self.mNewRecordBarItem
        self.navigationItem.rightBarButtonItem = self.mSettingBarItem
        
        TReading.filterByOption(nil, completion: { [weak self] (results) -> Void in
            if let strongSelf = self {
                print("Reading count: \(results != nil ?results!.count :0)")
                strongSelf.readings = results
                strongSelf.tableView.reloadData()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return tableView.fd_heightForCellWithIdentifier("SECReadingHistoryTableViewCell", cacheByIndexPath: indexPath, configuration: { (cell) -> Void in
            self.configureCell(cell as! SECReadingHistoryTableViewCell, atIndexPath: indexPath)
        })
    }
}
