//
//  SearchResults.swift
//  Backlogger
//
//  Created by Alex Busman on 2/16/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation

var GAME_API_KEY: String {
    var keys: NSDictionary!
    if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
        keys = NSDictionary(contentsOfFile: path)
    }
    if let dict = keys {
        let key = dict["GiantBombApiKey"] as! String
        return key
    } else {
        return ""
    }
}

class SearchResults {
    var error: String?
    var limit: Int?
    var offset: Int?
    var numberOfPageResults: Int?
    var numberOfTotalResults: Int?
    var statusCode: Int?
    var results: [Field]?
    var url: String?
    
    class func endpointForSearch() -> String {
        return "https://www.giantbomb.com/api/search/?api_key=" + GAME_API_KEY + "&format=json"
    }
}
