//
//  SECAudioFileListViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/25.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECAudioFileListViewController: UITableViewController {

    private var audioStoreDirectory = SECHelper.readingRecordStoreDirectory()
    private var audioFileNameList: [String]?
    
    private lazy var mEditBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "编辑", style: UIBarButtonItemStyle.Plain, target: self, action: "toEdit")
        return item
    }()
    
    class func instanceFromSB() -> SECAudioFileListViewController {
        return UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewControllerWithIdentifier("SECAudioFileListViewController") as! SECAudioFileListViewController
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
        
        self.navigationItem.rightBarButtonItem = self.mEditBarItem
        
        if audioStoreDirectory != nil {
            do {
                audioFileNameList = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(audioStoreDirectory!)
                print("audioFileNameList:\(audioFileNameList!)")
                self.tableView.reloadData()
            } catch let error as NSError {
                print("error:\(error.localizedDescription)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func toEdit() {
    
        // TODO:
    }
    

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return audioFileNameList != nil ?audioFileNameList!.count :0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 76
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SECAudioFileTableViewCell", forIndexPath: indexPath) as! SECAudioFileTableViewCell
        
        cell.configure(withAudioFilePath: "\(audioStoreDirectory!)\(audioFileNameList![indexPath.row])")
        
        // TODO: configure playing state
        cell.isPlaying = false
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //TODO:
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
}
