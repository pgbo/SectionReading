//
//  SECAudioFileListViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/25.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation

class SECAudioFileListViewController: UITableViewController, AVAudioPlayerDelegate, SECAudioFileTableViewCellDelegate {

    private var audioStoreDirectory = SECHelper.readingRecordStoreDirectory()
    private var audioFileNameList: [String]?
    
    private var audioPlayer: AVAudioPlayer?
    
    // 正在播放的音频索引，为空表示没有正在播放的音频
    private var playingAudioIndex: NSNumber?
    
    private lazy var mEditBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "编辑", style: UIBarButtonItemStyle.Plain, target: self, action: "toggleEdit")
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
        self.tableView.allowsSelection = false
        self.tableView.allowsSelectionDuringEditing = true
        
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
    
    @objc private func toggleEdit() {
    
        if self.tableView.editing {
            self.tableView .setEditing(false, animated: true)
            mEditBarItem.title = "编辑"
        } else {
            self.tableView .setEditing(true, animated: true)
            mEditBarItem.title = "完成"
        }
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
        
        cell.delegate = self
        cell.isPlaying = false
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            deleteFile(atIndexPath: indexPath)
        }
    }
    
    private func deleteFile(atIndexPath indexPath: NSIndexPath) {
        
        let deletingFilePath = "\(audioStoreDirectory!)\(audioFileNameList![indexPath.row])"
        let option = ReadingQueryOption()
        option.localAudioFilePath = deletingFilePath
        option.syncStatus = [ReadingSyncStatus.NeedSyncUpload]
        let count = TReading.count(withOption: option)
        if count == nil || count == 0 {
            audioFileNameList?.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(deletingFilePath)
            } catch let error as NSError {
                print("error:\(error.localizedDescription)")
            }
        } else {
            let deleteAlert = UIAlertController(title: "重要提醒", message: "该音频文件关联了一些未同步的读书笔记，删除后关联的读书笔记将会丢失录音，确认删除吗？", preferredStyle: UIAlertControllerStyle.Alert)
            deleteAlert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            deleteAlert.addAction(UIAlertAction(title: "删除", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                self.audioFileNameList?.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(deletingFilePath)
                } catch let error as NSError {
                    print("error:\(error.localizedDescription)")
                }
            }))
            self.presentViewController(deleteAlert, animated: true, completion: nil)
        }
    }
    
    // MARK: - table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if tableView.editing == false {
            return
        }
        
        // 到发布页面
        let selectionFilePath = "\(audioStoreDirectory!)\(audioFileNameList![indexPath.row])"
        self.showViewController(SECEditNewReadingViewController.instanceFromSB(selectionFilePath), sender: nil)
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return UITableViewCellEditingStyle.Delete
    }
    
    // MARK: - SECAudioFileTableViewCellDelegate
    
    func clickPlayAudioButtonIn(cell: SECAudioFileTableViewCell) {
        
        let cellBounds = cell.bounds
        let cellCenter = cell.convertPoint(CGPointMake(CGRectGetMidX(cellBounds), CGRectGetMidY(cellBounds)), toView: self.tableView)
        let cellIndexPath = self.tableView.indexPathForRowAtPoint(cellCenter)
        if cellIndexPath == nil {
            return
        }
        
        if playingAudioIndex != nil {
            if cellIndexPath!.row == playingAudioIndex!.integerValue {
                if audioPlayer != nil {
                    if audioPlayer!.playing {
                        audioPlayer!.pause()
                        cell.isPlaying = false
                    } else {
                        audioPlayer!.play()
                        cell.isPlaying = true
                    }
                    return
                }
            }
        }
        
        audioPlayer?.stop()
        
        if playingAudioIndex != nil {
            let lastPlayCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: playingAudioIndex!.integerValue, inSection: 0)) as? SECAudioFileTableViewCell
            lastPlayCell?.isPlaying = false
            playingAudioIndex = nil
        }
        
        let playAudioFilePath = "\(audioStoreDirectory!)\(audioFileNameList![cellIndexPath!.row])"
        
        do {
            
            // 创建新的播放器
            try audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: playAudioFilePath))
            audioPlayer!.delegate = self
            
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
            
            cell.isPlaying = true
            playingAudioIndex = NSNumber(integer: cellIndexPath!.row)
            
        } catch let error as NSError {
            
            print("Fail to init AVAudioPlayer, error:\(error.localizedDescription)")
            
            let alert = UIAlertController(title: nil, message: "出故障了, 请联系 App 运营人员", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        
        if playingAudioIndex != nil {
            let lastPlayCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: playingAudioIndex!.integerValue, inSection: 0)) as? SECAudioFileTableViewCell
            lastPlayCell?.isPlaying = false
            playingAudioIndex = nil
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        
        if playingAudioIndex != nil {
            let lastPlayCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: playingAudioIndex!.integerValue, inSection: 0)) as? SECAudioFileTableViewCell
            lastPlayCell?.isPlaying = false
            playingAudioIndex = nil
        }
    }
}
