//
//  Console.swift
//  Backlogger
//
//  Created by Alex Busman on 2/13/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import UIKit.UIImage

class Console {
    var title:       String = ""
    var company:     String = ""
    var releaseDate: String = ""
    var gameCount:   String = ""
    var image:       UIImage = UIImage()
    
    init() {
        
    }
    
    init(title: String, company: String, releaseDate: String, gameCount: String, image: UIImage) {
        self.title = title
        self.company = company
        self.releaseDate = releaseDate
        self.gameCount = gameCount
        self.image = image
    }
}
