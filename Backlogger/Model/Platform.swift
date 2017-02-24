//
//  Platform.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation

enum PlatformFields: String {
    case Abbreviation  = "abbreviation"
}

class Platform: Field {
    var abbreviation:  String?
    
    required init(json: [String : Any]) {
        self.abbreviation  = json[PlatformFields.Abbreviation.rawValue] as? String
        super.init(json: json)
    }
}
