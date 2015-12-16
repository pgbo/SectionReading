//
//  TReading+CoreDataProperties.swift
//  SectionReading
//
//  Created by guangbo on 15/12/15.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TReading {

    @NSManaged var fUploadingAudioFilePath: String?
    @NSManaged var fUploadedAudioUrl: String?
    @NSManaged var fGuid: String?
    @NSManaged var fCreateTimestamp: NSNumber?
    @NSManaged var fModifyTimestamp: NSNumber?
    @NSManaged var fContent: String?
    @NSManaged var fSyncStatus: NSNumber?
    @NSManaged var fStatus: String?

}
