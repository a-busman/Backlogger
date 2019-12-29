//
//  Migrator.swift
//  Backlogger
//
//  Created by Alex Busman on 12/29/19.
//  Copyright © 2019 Alex Busman. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import CloudKit

class Migrator {
    class func hasCloudKit() -> Bool {
        return false
    }
    
    class func hasRealm() -> Bool {
        return false
    }
    
    class func migrate() -> Bool {
        return false
    }
}
