//
//  Util.swift
//  Backlogger
//
//  Created by Alex Busman on 5/19/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import UIKit

class Util {
    
    class var appColor: UIColor {
        return UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
    }
    
    class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class func getPlaylistImagesDirectory() -> URL {
        let documents = Util.getDocumentsDirectory()
        return documents.appendingPathComponent("images/playlists")
    }
}
