//
//  Field.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import IceCream

enum GenericFields: String {
    case ApiDetailUrl  = "api_detail_url"
    case Id            = "id"
    case Name          = "name"
    case SiteDetailUrl = "site_detail_url"
}

class BLObject: Object {
    func add() {
        autoreleasepool {
            let realm = try? Realm()
            try! realm?.write {
                realm?.add(self, update: .modified)
            }
        }
    }
    func update(updateBlock: () -> ()) {
        autoreleasepool {
            let realm = try? Realm()
            try! realm?.write(updateBlock)
        }
    }
    
    func delete() {
        autoreleasepool {
            let realm = try? Realm()
            try! realm?.write {
                realm?.delete(self)
            }
        }
    }
    func migrateToCloudKit() -> Bool {
        fatalError("Must override migrateToCloudKit")
    }
}

class Field: BLObject {
    @objc dynamic var apiDetailUrl:  String? = nil
    @objc dynamic var idNumber:      Int     = 0
    @objc dynamic var name:          String? = nil
    @objc dynamic var siteDetailUrl: String? = nil
        
    init(json: [String : Any]) {
        super.init()
        self.apiDetailUrl  = json[GenericFields.ApiDetailUrl.rawValue]  as? String
        self.idNumber      = json[GenericFields.Id.rawValue]            as? Int ?? 0
        self.name          = json[GenericFields.Name.rawValue]          as? String
        self.siteDetailUrl = json[GenericFields.SiteDetailUrl.rawValue] as? String
    }
    
    required init() {
        super.init()
    }
    
    override static func primaryKey() -> String? {
        return "idNumber"
    }
    
    class func idNumber(fromJson json: [String : Any]) -> Int {
        return json[GenericFields.Id.rawValue] as? Int ?? 0
    }
    
    func deleteRetainCopy() -> Field {
        fatalError("Must override deleteRetainCopy")
    }
    
    override func add() {
        super.add()
    }
    
    override func update(updateBlock: () -> ()) {
        super.update(updateBlock: updateBlock)
    }
    
    override func delete() {
        super.delete()
    }
    
    override func migrateToCloudKit() -> Bool {
        return super.migrateToCloudKit()
    }
}
