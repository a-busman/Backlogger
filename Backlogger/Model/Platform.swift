//
//  Platform.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import Realm

enum PlatformFields: String {
    case Abbreviation  = "abbreviation"
}

class Platform: Field {
    dynamic var abbreviation: String? = nil
    
    required init(json: [String : Any]) {
        self.abbreviation  = json[PlatformFields.Abbreviation.rawValue] as? String
        super.init(json: json)
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
    
    class func customIdBase() -> Int {
        return 100000
    }
    
    func deepCopy() -> Platform {
        let newPlatform = Platform()
        newPlatform.abbreviation = self.abbreviation
        newPlatform.idNumber = self.idNumber
        newPlatform.apiDetailUrl = self.apiDetailUrl
        newPlatform.siteDetailUrl = self.siteDetailUrl
        newPlatform.name = self.name
        newPlatform.linkCount = self.linkCount
        return newPlatform
    }
}
