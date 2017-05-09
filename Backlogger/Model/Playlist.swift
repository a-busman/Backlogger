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
    
    private(set) dynamic var uuid = NSUUID().uuidString

    dynamic var name:            String? = nil
    dynamic var imageUrl:        String? = nil
    dynamic var descriptionText: String? = nil
    
    var games: List<Game> = List<Game>()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    func set(image: UIImage) {
        let data = UIImagePNGRepresentation(image)
        let filename = randomString(length: 8) + ".png"
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = URL(fileURLWithPath: documentsPath + filename)
        do {
            try data?.write(to: writePath, options: .atomic)
        } catch {
            NSLog("Could not write image to \(writePath.absoluteString)")
            return
        }
        // Delete previous file
        if self.imageUrl != nil {
            try? FileManager.default.removeItem(atPath: self.imageUrl!)
        }
        self.imageUrl = writePath.absoluteString
    }
    
    func getImage() -> UIImage? {
        if let imageUrl = self.imageUrl {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: imageUrl)) {
                return UIImage(data: data)
            } else {
                NSLog("Could not read data from \(imageUrl)")
                return nil
            }
        } else {
            NSLog("No Image URL")
            return nil
        }
    }
    
    private func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
