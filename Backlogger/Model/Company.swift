//
//  Company.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class Company: Field {
    let platforms: LinkingObjects<Platform> = LinkingObjects(fromType: Platform.self, property: "company")
    
    override init(json: [String : Any]) {
        super.init(json: json)
    }
    
    required init() {
        super.init()
    }
    
    func deepCopy() -> Company {
        let newField = Company()
        newField.apiDetailUrl = self.apiDetailUrl
        newField.idNumber = self.idNumber
        newField.name = self.name
        newField.siteDetailUrl = self.siteDetailUrl
        
        return newField
    }
    
    override func deleteRetainCopy() -> Company {
        let newField = self.deepCopy()
        super.delete()
        return newField
    }
}
