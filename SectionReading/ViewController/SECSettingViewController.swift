//
//  SECSettingViewController.swift
//  SectionReading
//
//  Created by guangbo on 15/12/3.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class SECSettingViewController: UITableViewController {

    override init(style: UITableViewStyle) {
        super.init(style: UITableViewStyle.Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.title = "设置"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        // TODO: configure cell
        let cellSection = indexPath.section
        let cellRow = indexPath.row
        
        if cellSection == 0 {
            if cellRow == 0 {
            
            } else if cellRow == 1 {
            
            } else if cellRow == 2 {
            
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

}
