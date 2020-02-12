//
//  WatchGame.swift
//  Backlogger
//
//  Created by Alex Busman on 1/19/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import Foundation
import UIKit

struct WatchGame {
    var name:     String = ""
    var rating:   Int    = 0
    var progress: Int    = 0
    var complete: Bool   = false
    var image:    String = ""
    var favorite: Bool   = false
    var id:       String = ""
    
    var dict: [String : Any] {
        get {
            var localDict: [String : Any] = [:]
            localDict["name"]     = self.name
            localDict["rating"]   = self.rating
            localDict["progress"] = self.progress
            localDict["complete"] = self.complete
            localDict["image"]    = self.image
            localDict["favorite"] = self.favorite
            localDict["id"]       = self.id
            return localDict
        }
    }
    
    init() {
        
    }
    
    init(dict: [String : Any]) {
        self.name     = dict["name"]     as? String ?? ""
        self.rating   = dict["rating"]   as? Int    ?? 0
        self.progress = dict["progress"] as? Int    ?? 0
        self.complete = dict["complete"] as? Bool   ?? false
        self.image    = dict["image"]    as? String ?? ""
        self.favorite = dict["favorite"] as? Bool   ?? false
        self.id       = dict["id"]       as? String ?? ""
    }
}
