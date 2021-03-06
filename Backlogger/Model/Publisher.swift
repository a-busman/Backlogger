//
//  Publisher.swift
//  Backlogger
//
//  Created by Alex Busman on 3/20/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Publisher: Field {
    var linkingGameFields: Results<GameField>? {
        return realm?.objects(GameField.self).filter("%@ IN publishers", self)
    }
    
    override init(json: [String : Any]) {
        super.init(json: json)
    }
    
    required init() {
        super.init()
    }
    func deepCopy() -> Publisher {
        let newField = Publisher()
        newField.apiDetailUrl = self.apiDetailUrl
        newField.idNumber = self.idNumber
        newField.name = self.name
        newField.siteDetailUrl = self.siteDetailUrl
        
        return newField
    }
    
    override func deleteRetainCopy() -> Publisher {
        let newField = self.deepCopy()
        super.delete()
        return newField
    }
}
