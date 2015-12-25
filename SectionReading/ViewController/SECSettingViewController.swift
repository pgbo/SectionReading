//
//  SECSettingViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECSettingViewController: UITableViewController {

    private var evernoteManager = SECAppDelegate.SELF()!.evernoteManager
    private var needSycnDownNoteNumber: Int = 0
    private var needSycnUpNoteNumber: Int = 0
    
    class func instanceFromSB() -> SECSettingViewController {
        return UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewControllerWithIdentifier("SECSettingViewController") as! SECSettingViewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError("init(nibName:, bundle:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.title = "设置"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadAndShowSyncDownAndUpCount()
    }
    
    private func loadAndShowSyncDownAndUpCount() {
    
        evernoteManager.getNeedSyncDownNoteCount(withSuccess: { [weak self] (count) -> Void in
            if let strongSelf = self {
                dispatch_async(dispatch_get_main_queue()) {
                    strongSelf.needSycnDownNoteNumber = count
                    strongSelf.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                }
            }
            }) { [weak self] () -> Void in
                if let strongSelf = self {
                    dispatch_async(dispatch_get_main_queue()) {
                        strongSelf.needSycnDownNoteNumber = 0
                        strongSelf.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                    }
                }
        }
        
        let option = ReadingQueryOption()
        option.syncStatus = [ReadingSyncStatus.NeedSyncDelete, ReadingSyncStatus.NeedSyncUpload]
        if let needSyncup = TReading.count(withOption: option) {
            needSycnUpNoteNumber = needSyncup
        } else {
            needSycnUpNoteNumber = 0
        }
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        //  configure cell
        
        let cellSection = indexPath.section
        let cellRow = indexPath.row
        
        if cellSection == 0 {
            if cellRow == 0 {
                if evernoteManager.isAuthenticated() {
                    cell.textLabel?.text = "退出 Evernote"
                } else {
                    cell.textLabel?.text = "登录并同步到 Evernote"
                }
            } else if cellRow == 1 {
                
                let onlySyncUnderWIFI = SECAppDelegate.SELF()!.onlySyncNoteUnderWIFI
                if onlySyncUnderWIFI {
                    cell.detailTextLabel?.text = "开启"
                } else {
                    cell.detailTextLabel?.text = "关闭"
                }
                
            } else if cellRow == 2 {
                
                var text = ""
                if needSycnDownNoteNumber > 0 {
                    text += "\(needSycnDownNoteNumber) 待下载"
                }
                if needSycnUpNoteNumber > 0 {
                    if text.characters.count > 0 {
                        text += ", "
                    }
                    text += "\(needSycnUpNoteNumber) 待上传"
                }
                
                cell.detailTextLabel?.text = text
            }
        } else if cellSection == 1 {
            if cellRow == 0 {
                
            } else if cellRow == 1 {
                
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 20
    }
 
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.1
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let cellSection = indexPath.section
        let cellRow = indexPath.row
        
        if cellSection == 0 {
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            if cellRow == 0 {
                clickEvernoteAuthenticateCell(cell)
            } else if cellRow == 1 {
                clickOnlySyncNoteUnderWIFICell(cell)
            } else if cellRow == 2 {
                clickManualSycnNoteCell(cell)
            }
        } else if cellSection == 1 {
            if cellRow == 0 {
                clickRateCell()
            } else if cellRow == 1 {
                clickContactAuthorCell()
            }
        }
    }
    
    private func doEvernoteAuthenticate() {
        
        evernoteManager.authenticate(withViewController: self, completion: { [weak self] (success) -> Void in
            if let strongSelf = self {
                dispatch_async(dispatch_get_main_queue(), {
                    if success {
                        strongSelf.tableView .reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                        strongSelf.evernoteManager.sync(withType: .UP_AND_DOWN, completion: { (successNumber) -> Void in
                            print("After login evernote, sync count:\(successNumber)")
                        })
                    } else {
                        let alert = UIAlertController(title: nil, message: "登录失败", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.Cancel, handler: nil))
                        strongSelf.presentViewController(alert, animated: true, completion: nil)
                    }
                })
            }
        })
    }
    
    private func clickEvernoteAuthenticateCell(cell: UITableViewCell) {
        
        if evernoteManager.isAuthenticated() {
            
            let alert = UIAlertController(title: nil, message: "确认退出 Evernote 账号吗？", preferredStyle: UIAlertControllerStyle.ActionSheet)
            alert.addAction(UIAlertAction(title: "退出", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                
                self.evernoteManager.unauthenticate()
                self.tableView .reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = cell;
                presenter.sourceRect = cell.bounds;
            }
            self.presentViewController(alert, animated: true, completion: nil)
            
        } else {
            doEvernoteAuthenticate()
        }
    }
    
    private func clickOnlySyncNoteUnderWIFICell(cell: UITableViewCell) {
        
        var alertMesaage: String?
        var actionTitle: String?
        
        let onlySyncNoteUnderWIFI = SECAppDelegate.SELF()!.onlySyncNoteUnderWIFI
        if onlySyncNoteUnderWIFI {
            alertMesaage = "需要关闭只在 WIFI 下同步吗？"
            actionTitle = "关闭"
        } else {
            alertMesaage = "需要开启只在 WIFI 下同步吗？"
            actionTitle = "开启"
        }
        
        let alert = UIAlertController(title: nil, message: alertMesaage, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            SECAppDelegate.SELF()!.onlySyncNoteUnderWIFI = !onlySyncNoteUnderWIFI
            self.tableView .reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = cell;
            presenter.sourceRect = cell.bounds;
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func clickManualSycnNoteCell(cell: UITableViewCell) {
        
        if evernoteManager.isAuthenticated() == false {
            doEvernoteAuthenticate()
            return
        }
        
        let alert = UIAlertController(title: nil, message: "确认现在同步吗？", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "立即同步", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            
            // TODO: 进行同步动画或提示
            self.evernoteManager.sync(withType: .UP_AND_DOWN, completion: { [weak self] (successNumber) -> Void in
                if let strongSelf = self {
                    dispatch_async(dispatch_get_main_queue()) {
                        strongSelf.loadAndShowSyncDownAndUpCount()
                    }
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = cell;
            presenter.sourceRect = cell.bounds;
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func clickRateCell() {
        
    }
    
    private func clickContactAuthorCell() {
        
    }

}
