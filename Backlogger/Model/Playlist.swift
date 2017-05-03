//
//  Playlist.swift
//  Backlogger
//
//  Created by Alex Busman on 5/2/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class Playlist: Object {
    var games: List<Game> = List<Game>()
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}
