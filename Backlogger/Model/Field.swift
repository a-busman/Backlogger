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

enum GenericFields: String {
    case ApiDetailUrl  = "api_detail_url"
    case Id            = "id"
    case Name          = "name"
    case SiteDetailUrl = "site_detail_url"
}

class Field: Object {
    dynamic var apiDetailUrl:  String? = nil
    dynamic var idNumber:      Int     = 0
    dynamic var name:          String? = nil
    dynamic var siteDetailUrl: String? = nil
    
    dynamic var linkCount: Int = 0
    
    required init(json: [String : Any]) {
        super.init()
        self.apiDetailUrl  = json[GenericFields.ApiDetailUrl.rawValue]  as? String
        self.idNumber      = json[GenericFields.Id.rawValue]            as? Int ?? 0
        self.name          = json[GenericFields.Name.rawValue]          as? String
        self.siteDetailUrl = json[GenericFields.SiteDetailUrl.rawValue] as? String
    }
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    override static func primaryKey() -> String? {
        return "idNumber"
    }
    
    class func idNumber(fromJson json: [String : Any]) -> Int {
        return json[GenericFields.Id.rawValue] as? Int ?? 0
    }
}

extension Object {
    func add() {
        let realm = try? Realm()
        try! realm?.write {
            realm?.add(self, update: true)
        }
    }
    func update(updateBlock: () -> ()) {
        let realm = try? Realm()
        try! realm?.write(updateBlock)
    }
    
    func delete() {
        let realm = try? Realm()
        try! realm?.write {
            realm?.delete(self)
        }
    }
}
