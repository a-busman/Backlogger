//
//  Genre.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Genre: Field {
    var linkingGameFields: Results<GameField>? {
        return realm?.objects(GameField.self).filter("%@ IN genres", self)
    }
    
    override init(json: [String : Any]) {
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
    
    func deepCopy() -> Genre {
        let newField = Genre()
        newField.apiDetailUrl = self.apiDetailUrl
        newField.idNumber = self.idNumber
        newField.name = self.name
        newField.siteDetailUrl = self.siteDetailUrl
        return newField
    }
    
    override func deleteRetainCopy() -> Genre {
        let newField = self.deepCopy()
        super.delete()
        return newField
    }
}
