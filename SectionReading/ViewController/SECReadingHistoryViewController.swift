//
//  SECReadingHistoryViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit
import AVFoundation
import UITableView_FDTemplateLayoutCell
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


/**
 *  读书纪录列表页面
 *  先展示本地数据、然后接收印象笔记同步下载通知并更新数据
 */
class SECReadingHistoryViewController: UITableViewController, SECReadingHistoryTableViewCellDelegate, AVAudioPlayerDelegate {

    fileprivate var readings: [TReading]?
    
    fileprivate lazy var mNewRecordBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "新建", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SECReadingHistoryViewController.toAddNewRecord))
        return item
    }()
    
    fileprivate lazy var mSettingBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "设置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SECReadingHistoryViewController.toSetting))
        return item
    }()
    
    fileprivate lazy var mEvernoteManager: SECEvernoteManager = {
        return (UIApplication.shared.delegate as! SECAppDelegate).evernoteManager
    }()
    
    fileprivate var audioPlayer: AVAudioPlayer?
    
    // 正在播放的音频索引，为空表示没有正在播放的音频
    fileprivate var playingAudioIndex: NSNumber?
    fileprivate var willPlayAudioIndex: NSNumber?
    
    class func instanceFromSB() -> SECReadingHistoryViewController {
        return UIStoryboard(name: "SECStoryboard", bundle: nil).instantiateViewController(withIdentifier: "SECReadingHistoryViewController") as! SECReadingHistoryViewController
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(SECReadingHistoryViewController.recvEvernoteManagerSycnDownStateDidChangeNote(_:)), name: NSNotification.Name(rawValue: SECEvernoteManagerSycnDownStateDidChangeNotification), object: nil)
        
        self.navigationItem.title = "读书记录"
        self.navigationItem.leftBarButtonItem = self.mNewRecordBarItem
        self.navigationItem.rightBarButtonItem = self.mSettingBarItem
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(SECReadingHistoryViewController.refresh), for: UIControlEvents.valueChanged)
        
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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: SECEvernoteManagerSycnDownStateDidChangeNotification), object: nil)
    }
    
    @objc fileprivate func refresh() {
    
        TReading.filterByOption(nil, completion: { [weak self] (results) -> Void in
            if let strongSelf = self {
                strongSelf.refreshControl?.endRefreshing()
                
                print("Reading count: \(results != nil ?results!.count :0)")
                strongSelf.readings = results
                strongSelf.tableView.reloadData()
            }
            })
    }
    
    @objc fileprivate func recvEvernoteManagerSycnDownStateDidChangeNote(_ note: Notification) {
        
        print("recv SECEvernoteManagerSycnDownStateDidChangeNotification.")
        
        DispatchQueue.main.async {
            
            if self.navigationController?.topViewController != self {
                let currentSyncDownState = (note as NSNotification).userInfo?[SECEvernoteManagerNotificationSycnDownStateItem] as? Bool
                let syncDownNumber = (note as NSNotification).userInfo?[SECEvernoteManagerNotificationSuccessSycnDownNoteCountItem] as? Int
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc fileprivate func toAddNewRecord() {
        
        let nav = UINavigationController(rootViewController: SECNewReadingViewController.instanceFromSB())
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc fileprivate func toSetting() {
       
        self.navigationController?.show(SECSettingViewController.instanceFromSB(), sender: nil)
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return readings != nil ?readings!.count :0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "SECReadingHistoryTableViewCell", for: indexPath) as! SECReadingHistoryTableViewCell
        cell.delegate = self
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    fileprivate func configureCell(_ cell: SECReadingHistoryTableViewCell, atIndexPath indexPath: IndexPath) {
    
        let reading = readings![(indexPath as NSIndexPath).row]
        cell.configure(withReading: reading)
    }
    
    // MARK: -  UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return tableView.fd_heightForCell(withIdentifier: "SECReadingHistoryTableViewCell", cacheBy: indexPath, configuration: { (cell) -> Void in
            self.configureCell(cell as! SECReadingHistoryTableViewCell, atIndexPath: indexPath)
        })
    }
    
    // MARK: - SECReadingHistoryTableViewCellDelegate
    
    func clickEditButtonIn(_ cell: SECReadingHistoryTableViewCell) {
        
        print("clickEditButtonIn.")
        // TODO: 到编辑页面
    }
    
    func clickTrashButtonIn(_ cell: SECReadingHistoryTableViewCell) {
        
        print("clickTrashButtonIn.")
        let indexPath = indexPathOfCell(cell)
        if indexPath != nil {
            if let reading = readings?[(indexPath! as NSIndexPath).row] {
                
                self.readings?.remove(at: (indexPath! as NSIndexPath).row)
                self.tableView.deleteRows(at: [IndexPath(row: (indexPath! as NSIndexPath).row, section: 0)], with: UITableViewRowAnimation.fade)
                
                if reading.fEvernoteGuid != nil {
                    mEvernoteManager.deleteNote(withGuid: reading.fEvernoteGuid!, completion: { (success) -> Void in
                        if success {
                            let deleteOption = ReadingQueryOption()
                            deleteOption.localId = reading.fLocalId;
                            TReading.deleteByOption(deleteOption)
                        }
                    })
                }
            }
        }
    }
    
    func clickShareButtonIn(_ cell: SECReadingHistoryTableViewCell) {
        
        print("clickShareButtonIn.")
        let indexPath = indexPathOfCell(cell)
        if indexPath != nil {
            if let reading = readings?[(indexPath! as NSIndexPath).row] {
                self.navigationController?.show(SECShareReadingViewController.instanceFromSB(withShareReadingLocalId: reading.fLocalId!), sender: nil)
            }
        }
    }
    
    func clickPlayAudioButtonIn(_ cell: SECReadingHistoryTableViewCell) {
    
        print("clickPlayAudioButtonIn.")
        let cellIndexPath = indexPathOfCell(cell)
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
        
        let reading = self.readings![(cellIndexPath! as NSIndexPath).row]
        let playAudioFilePath = reading.fLocalAudioFilePath
        if playAudioFilePath != nil {
            
            self.willPlayAudioIndex = NSNumber(value: (cellIndexPath! as NSIndexPath).row as Int)
            self.playReadingAudio(cellIndexPath!, withAudioFilePath: playAudioFilePath!)
            
        } else {
            // download from evernote
            let audioResorceGuid = reading.fUploadedAudioGuid
            if audioResorceGuid == nil {
                return
            }
            if self.mEvernoteManager.isAuthenticated() == false {
               return
            }
            
            self.willPlayAudioIndex = NSNumber(value: (cellIndexPath! as NSIndexPath).row as Int)
            self.mEvernoteManager.getResource(withResourceGuid: audioResorceGuid!, completion: { [weak self] (data) -> Void in
                if let strongSelf = self {
                    if data == nil {
                        return
                    }
                    if strongSelf.willPlayAudioIndex == nil {
                        return
                    }
                    if strongSelf.willPlayAudioIndex!.intValue == (cellIndexPath! as NSIndexPath).row {
                        // 保存到本地
                        let readingRecordDir = SECHelper.readingRecordStoreDirectory()
                        let newAudioFilePath = (readingRecordDir)! + "\(UUID().uuidString).caf"
                        if (FileManager.default.createFile(atPath: newAudioFilePath, contents: data as Data?, attributes: nil)) {
                            // 更新本地记录
                            let updateOption = ReadingQueryOption()
                            updateOption.localId = reading.fLocalId
                            TReading.update(withFilterOption: updateOption, updateBlock: { (readingtoUpdate) -> Void in
                                readingtoUpdate.fLocalAudioFilePath = newAudioFilePath
                            })
                            // 播放
                            strongSelf.playReadingAudio(cellIndexPath!, withAudioFilePath: newAudioFilePath)
                        }
                    }
                }
            })
        }
    }
    
    fileprivate func playReadingAudio(_ atIndexPath: IndexPath, withAudioFilePath audioFilePath: String) {
        
        if playingAudioIndex != nil {
            if (atIndexPath as NSIndexPath).row == playingAudioIndex!.intValue {
                return
            }
        }
        
        audioPlayer?.stop()
        
        if playingAudioIndex != nil {
            let lastPlayCell = tableView.cellForRow(at: IndexPath(row: playingAudioIndex!.intValue, section: 0)) as? SECAudioFileTableViewCell
            lastPlayCell?.isPlaying = false
            playingAudioIndex = nil
        }
        
        do {
            
            // 创建新的播放器
            try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioFilePath))
            audioPlayer!.delegate = self
            
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
            
            (self.tableView.cellForRow(at: atIndexPath) as? SECAudioFileTableViewCell)?.isPlaying = true
            playingAudioIndex = NSNumber(value: (atIndexPath as NSIndexPath).row as Int)
            
        } catch let error as NSError {
            
            print("Fail to init AVAudioPlayer, error:\(error.localizedDescription)")
        }
    }
    
    fileprivate func indexPathOfCell(_ cell: UITableViewCell) -> IndexPath? {
        
        let cellBounds = cell.bounds
        let cellCenter = cell.convert(CGPoint(x: cellBounds.midX, y: cellBounds.midY), to:self.tableView)
        return self.tableView.indexPathForRow(at: cellCenter)
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
