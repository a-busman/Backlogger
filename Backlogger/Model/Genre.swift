//
//  Genre.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation

class Genre: Field {
    required init(json: [String : Any]) {
        super.init(json: json)
    }
}
