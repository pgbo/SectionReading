//
//  SECSettingViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECSettingViewController: UITableViewController {

    fileprivate var evernoteManager = SECAppDelegate.SELF()!.evernoteManager
    fileprivate var needSycnDownNoteNumber: Int = 0
    fileprivate var needSycnUpNoteNumber: Int = 0
    
    class func instanceFromSB() -> SECSettingViewController {
        return UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewController(withIdentifier: "SECSettingViewController") as! SECSettingViewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadAndShowSyncDownAndUpCount()
    }
    
    fileprivate func loadAndShowSyncDownAndUpCount() {
    
        evernoteManager?.getNeedSyncDownNoteCount(withSuccess: { [weak self] (count) -> Void in
            if let strongSelf = self {
                DispatchQueue.main.async {
                    strongSelf.needSycnDownNoteNumber = count
                    strongSelf.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: UITableViewRowAnimation.none)
                }
            }
            }) { [weak self] () -> Void in
                if let strongSelf = self {
                    DispatchQueue.main.async {
                        strongSelf.needSycnDownNoteNumber = 0
                        strongSelf.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: UITableViewRowAnimation.none)
                    }
                }
        }
        
        let option = ReadingQueryOption()
        option.syncStatus = [ReadingSyncStatus.needSyncDelete, ReadingSyncStatus.needSyncUpload]
        if let needSyncup = TReading.count(withOption: option) {
            needSycnUpNoteNumber = needSyncup
        } else {
            needSycnUpNoteNumber = 0
        }
        self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: UITableViewRowAnimation.none)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        //  configure cell
        
        let cellSection = (indexPath as NSIndexPath).section
        let cellRow = (indexPath as NSIndexPath).row
        
        if cellSection == 0 {
            if cellRow == 0 {
                if (evernoteManager?.isAuthenticated())! {
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 20
    }
 
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellSection = (indexPath as NSIndexPath).section
        let cellRow = (indexPath as NSIndexPath).row
        
        if cellSection == 0 {
            let cell = tableView.cellForRow(at: indexPath)!
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
    
    fileprivate func doEvernoteAuthenticate() {
        
        evernoteManager?.authenticate(withViewController: self, completion: { [weak self] (success) -> Void in
            if let strongSelf = self {
                DispatchQueue.main.async(execute: {
                    if success {
                        strongSelf.tableView .reloadRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.none)
                        strongSelf.evernoteManager?.sync(withType: .up_AND_DOWN, completion: { (successNumber) -> Void in
                            print("After login evernote, sync count:\(successNumber)")
                        })
                    } else {
                        let alert = UIAlertController(title: nil, message: "登录失败", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.cancel, handler: nil))
                        strongSelf.present(alert, animated: true, completion: nil)
                    }
                })
            }
        })
    }
    
    fileprivate func clickEvernoteAuthenticateCell(_ cell: UITableViewCell) {
        
        if (evernoteManager?.isAuthenticated())! {
            
            let alert = UIAlertController(title: nil, message: "确认退出 Evernote 账号吗？", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.addAction(UIAlertAction(title: "退出", style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
                
                self.evernoteManager?.unauthenticate()
                self.tableView .reloadRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.none)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = cell;
                presenter.sourceRect = cell.bounds;
            }
            self.present(alert, animated: true, completion: nil)
            
        } else {
            doEvernoteAuthenticate()
        }
    }
    
    fileprivate func clickOnlySyncNoteUnderWIFICell(_ cell: UITableViewCell) {
        
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
        
        let alert = UIAlertController(title: nil, message: alertMesaage, preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
            SECAppDelegate.SELF()!.onlySyncNoteUnderWIFI = !onlySyncNoteUnderWIFI
            self.tableView .reloadRows(at: [IndexPath(row: 1, section: 0)], with: UITableViewRowAnimation.none)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = cell;
            presenter.sourceRect = cell.bounds;
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func clickManualSycnNoteCell(_ cell: UITableViewCell) {
        
        if evernoteManager?.isAuthenticated() == false {
            doEvernoteAuthenticate()
            return
        }
        
        let alert = UIAlertController(title: nil, message: "确认现在同步吗？", preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "立即同步", style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
            
            // TODO: 进行同步动画或提示
            self.evernoteManager!.sync(withType: .up_AND_DOWN, completion: { [weak self] (successNumber) -> Void in
                if let strongSelf = self {
                    DispatchQueue.main.async {
                        strongSelf.loadAndShowSyncDownAndUpCount()
                    }
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = cell;
            presenter.sourceRect = cell.bounds;
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func clickRateCell() {
        
    }
    
    fileprivate func clickContactAuthorCell() {
        
    }

}
