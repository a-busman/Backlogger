//
//  SearchResults.swift
//  Backlogger
//
//  Created by Alex Busman on 2/16/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation

let GAME_API_KEY = "YOUR_API_KEY"

class SearchResults {
    var error: String?
    var limit: Int?
    var offset: Int?
    var numberOfPageResults: Int?
    var numberOfTotalResults: Int?
    var statusCode: Int?
    var results: [Game]?
    var url: String?
    
    class func endpointForSearch() -> String {
        return "https://www.giantbomb.com/api/search/?api_key=" + GAME_API_KEY + "&format=json"
    }
}
