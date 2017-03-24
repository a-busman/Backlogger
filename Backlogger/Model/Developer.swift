//
//  Developer.swift
//  Backlogger
//
//  Created by Alex Busman on 3/20/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import Realm

class Developer: Field {
    required init(json: [String : Any]) {
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
    
    func deepCopy() -> Developer {
        let newField = Developer()
        newField.apiDetailUrl = self.apiDetailUrl
        newField.idNumber = self.idNumber
        newField.name = self.name
        newField.siteDetailUrl = self.siteDetailUrl
        newField.linkCount = self.linkCount
        
        return newField
    }
}
