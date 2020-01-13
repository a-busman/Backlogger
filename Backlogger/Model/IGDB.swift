//
//  IGDB.swift
//  Backlogger
//
//  Created by Alex Busman on 1/11/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import Foundation

var IGDB_API_KEY: String {
    var keys: NSDictionary!
    if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
        keys = NSDictionary(contentsOfFile: path)
    }
    if let dict = keys {
        let key = dict["IGDBApiKey"] as! String
        return key
    } else {
        return ""
    }
}

class IGDB {

}
