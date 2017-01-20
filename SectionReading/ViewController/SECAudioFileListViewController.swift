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

    fileprivate var audioStoreDirectory = SECHelper.readingRecordStoreDirectory()
    fileprivate var audioFileNameList: [String]?
    
    fileprivate var audioPlayer: AVAudioPlayer?
    
    // 正在播放的音频索引，为空表示没有正在播放的音频
    fileprivate var playingAudioIndex: NSNumber?
    
    fileprivate lazy var mEditBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "编辑", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SECAudioFileListViewController.toggleEdit))
        return item
    }()
    
    class func instanceFromSB() -> SECAudioFileListViewController {
        
        return UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewController(withIdentifier: "SECAudioFileListViewController") as! SECAudioFileListViewController
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: UITableViewStyle.grouped)
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
                audioFileNameList = try FileManager.default.contentsOfDirectory(atPath: audioStoreDirectory!)
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
    
    @objc fileprivate func toggleEdit() {
    
        if self.tableView.isEditing {
            self.tableView .setEditing(false, animated: true)
            mEditBarItem.title = "编辑"
        } else {
            self.tableView .setEditing(true, animated: true)
            mEditBarItem.title = "完成"
        }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return audioFileNameList != nil ?audioFileNameList!.count :0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SECAudioFileTableViewCell", for: indexPath) as! SECAudioFileTableViewCell
        
        let row = (indexPath as NSIndexPath).row
        
        cell.configure(withAudioFilePath: "\(audioStoreDirectory!)\(audioFileNameList![row])")
        
        cell.delegate = self
        
        if playingAudioIndex != nil && playingAudioIndex!.intValue == row {
            cell.isPlaying = true
        } else {
            cell.isPlaying = false
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            toDeleteFile(atIndexPath: indexPath)
        }
    }
    
    fileprivate func toDeleteFile(atIndexPath indexPath: IndexPath) {
        
        let deletingFilePath = "\(audioStoreDirectory!)\(audioFileNameList![(indexPath as NSIndexPath).row])"
        let option = ReadingQueryOption()
        option.localAudioFilePath = deletingFilePath
        option.syncStatus = [ReadingSyncStatus.needSyncUpload]
        let count = TReading.count(withOption: option)
        if count == nil || count == 0 {
            
            tableViewDidDeleteAudioFile(atIndexPath: indexPath)
            deleteAudioFileAtPath(deletingFilePath)
            
        } else {
            let deleteAlert = UIAlertController(title: "重要提醒", message: "该音频文件关联了一些未同步的读书笔记，删除后关联的读书笔记将会丢失录音，确认删除吗？", preferredStyle: UIAlertControllerStyle.alert)
            deleteAlert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
            deleteAlert.addAction(UIAlertAction(title: "删除", style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
                TReading.filterByOption(option, completion: { (results) -> Void in
                    if results == nil {
                        return
                    }
                    for reading in results! {
                        reading.fLocalAudioFilePath = nil
                        reading.fModifyTimestamp = NSNumber(value: Int(Date().timeIntervalSince1970) as Int)
                    }
                    
                    self.tableViewDidDeleteAudioFile(atIndexPath: indexPath)
                    self.deleteAudioFileAtPath(deletingFilePath)
                })
                
                
                self.audioFileNameList?.remove(at: (indexPath as NSIndexPath).row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                do {
                    try FileManager.default.removeItem(atPath: deletingFilePath)
                } catch let error as NSError {
                    print("error:\(error.localizedDescription)")
                }
            }))
            self.present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    fileprivate func tableViewDidDeleteAudioFile(atIndexPath indexPath: IndexPath) {
        
        let deletingRow = (indexPath as NSIndexPath).row
        if playingAudioIndex != nil {
            let playingIndex = playingAudioIndex!.intValue
            if playingIndex == deletingRow {
                playingAudioIndex = nil
            } else if playingIndex > deletingRow {
                playingAudioIndex = NSNumber(value: playingIndex - 1 as Int)
            }
        }
        
        audioFileNameList?.remove(at: deletingRow)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    fileprivate func deleteAudioFileAtPath(_ filePath: String) {

        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch let error as NSError {
            print("error:\(error.localizedDescription)")
        }
    }
    
    // MARK: - table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView.isEditing == false {
            return
        }
        
        // 到发布页面
        let selectionFilePath = "\(audioStoreDirectory!)\(audioFileNameList![(indexPath as NSIndexPath).row])"
        self.show(SECEditNewReadingViewController.instanceFromSB(selectionFilePath), sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return UITableViewCellEditingStyle.delete
    }
    
    // MARK: - SECAudioFileTableViewCellDelegate
    
    func clickPlayAudioButtonIn(_ cell: SECAudioFileTableViewCell) {
        
        let cellBounds = cell.bounds
        let cellCenter = cell.convert(CGPoint(x: cellBounds.midX, y: cellBounds.midY), to: self.tableView)
        let cellIndexPath = self.tableView.indexPathForRow(at: cellCenter)
        if cellIndexPath == nil {
            return
        }
        
        if playingAudioIndex != nil {
            if (cellIndexPath! as NSIndexPath).row == playingAudioIndex!.intValue {
                if audioPlayer != nil {
                    if audioPlayer!.isPlaying {
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
            let lastPlayCell = tableView.cellForRow(at: IndexPath(row: playingAudioIndex!.intValue, section: 0)) as? SECAudioFileTableViewCell
            lastPlayCell?.isPlaying = false
            playingAudioIndex = nil
        }
        
        let playAudioFilePath = "\(audioStoreDirectory!)\(audioFileNameList![(cellIndexPath! as NSIndexPath).row])"
        
        do {
            
            // 创建新的播放器
            try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: playAudioFilePath))
            audioPlayer!.delegate = self
            
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
            
            cell.isPlaying = true
            playingAudioIndex = NSNumber(value: (cellIndexPath! as NSIndexPath).row as Int)
            
        } catch let error as NSError {
            
            print("Fail to init AVAudioPlayer, error:\(error.localizedDescription)")
            
            let alert = UIAlertController(title: nil, message: "出故障了, 请联系 App 运营人员", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "知道了", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
        if playingAudioIndex != nil {
            let lastPlayCell = tableView.cellForRow(at: IndexPath(row: playingAudioIndex!.intValue, section: 0)) as? SECAudioFileTableViewCell
            lastPlayCell?.isPlaying = false
            playingAudioIndex = nil
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        if playingAudioIndex != nil {
            let lastPlayCell = tableView.cellForRow(at: IndexPath(row: playingAudioIndex!.intValue, section: 0)) as? SECAudioFileTableViewCell
            lastPlayCell?.isPlaying = false
            playingAudioIndex = nil
        }
    }
}
