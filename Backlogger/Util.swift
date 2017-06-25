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
    
    class func removeSpecialCharsFromString(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    class func toRoman(number: Int) -> String {
        
        let romanValues = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        let arabicValues = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        
        var romanValue = ""
        var startingValue = number
        
        for (index, romanChar) in romanValues.enumerated() {
            let arabicValue = arabicValues[index]
            
            let div = startingValue / arabicValue
            
            if (div > 0)
            {
                for _ in 0..<div
                {
                    //println("Should add \(romanChar) to string")
                    romanValue += romanChar
                }
                
                startingValue -= arabicValue * div
            }
        }
        
        return romanValue
    }
}

extension UIImage {
    public func resize(to newSize: CGSize) -> UIImage {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        let imageRef = self.cgImage!
        
        UIGraphicsBeginImageContext(newSize)
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = .high
        
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context?.concatenate(flipVertical)
        context?.draw(imageRef, in: newRect)
        
        let newImageRef = context!.makeImage()
        let newImage = UIImage(cgImage: newImageRef!)
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension String {
    
    var count: Int {
        return self.characters.count
    }
    
    func index(_ i: Int) -> String.CharacterView.Index {
        if i >= 0 {
            return self.index(self.startIndex, offsetBy: i)
        } else {
            return self.index(self.endIndex, offsetBy: i)
        }
    }
    
    subscript(i: Int) -> Character? {
        if i >= count || i < -count {
            return nil
        }
        
        return self[index(i)]
    }
    
    subscript(r: Range<Int>) -> String {
        return self[index(r.lowerBound)..<index(r.upperBound)]
    }
    
    public func distance(between target: String) -> Int {
        if self == target {
            return 0
        }
        if self.count == 0 {
            return target.count
        }
        if target.count == 0 {
            return self.count
        }
        
        var da: [Character: Int] = [:]
        
        var d = Array(repeating: Array(repeating: 0, count: target.count + 2), count: self.count + 2)
        
        let maxdist = self.count + target.count
        d[0][0] = maxdist
        for i in 1...self.count + 1 {
            d[i][0] = maxdist
            d[i][1] = i - 1
        }
        for j in 1...target.count + 1 {
            d[0][j] = maxdist
            d[1][j] = j - 1
        }
        
        for i in 2...self.count + 1 {
            var db = 1
            
            for j in 2...target.count + 1 {
                let k = da[target[j - 2]!] ?? 1
                let l = db
                
                var cost = 1
                if self[i - 2] == target[j - 2] {
                    cost = 0
                    db = j
                }
                
                let substition = d[i - 1][j - 1] + cost
                let injection = d[i][j - 1] + 1
                let deletion = d[i - 1][j] + 1
                let selfIdx = i - k - 1
                let targetIdx = j - l - 1
                let transposition = d[k - 1][l - 1] + selfIdx + 1 + targetIdx
                
                d[i][j] = min(
                    substition,
                    injection,
                    deletion,
                    transposition
                )
            }
            
            da[self[i - 2]!] = i
        }
        
        return d[self.count + 1][target.count + 1]
    }
    
    public func removeSpecialEdition() -> String {
        let lowercase = self.lowercased()
        if lowercase.hasSuffix("goty edition") {
            return self[0..<self.count - "goty edition".count - 1]
        } else if lowercase.hasSuffix("game of the year edition") {
            return self[0..<self.count - "game of the year edition".count - 1]
        } else if lowercase.hasSuffix("enhanced edition") {
            return self[0..<self.count - "enhanced edition".count - 1]
        } else if lowercase.hasSuffix("steam edition") {
            return self[0..<self.count - "steam edition".count - 1]
        } else if lowercase.hasSuffix("hd") {
            return self[0..<self.count - "hd".count - 1]
        } else if lowercase.hasSuffix("goty") {
            return self[0..<self.count - "goty".count - 1]
        } else if lowercase.hasSuffix("the directors cut") {
            return self[0..<self.count - "the directors cut".count - 1]
        } else if lowercase.hasSuffix("(new steam version)") {
            return self[0..<self.count - "(new steam version".count - 1]
        } else if lowercase.hasSuffix("multiplayer") {
            return self[0..<self.count - "multiplayer".count - 1]
        } else if lowercase.hasSuffix("single player") {
            return self[0..<self.count - "single player".count - 1]
        } else if lowercase.hasSuffix("remastered") {
            return self[0..<self.count - "remastered".count - 1]
        } else if lowercase.hasSuffix("complete edition") {
            return self[0..<self.count - "complete edition".count - 1]
        } else if lowercase.hasSuffix("deluxe") {
            return self[0..<self.count - "deluxe".count - 1]
        } else if lowercase.hasSuffix("maximum edition") {
            return self[0..<self.count - "maximum edition".count - 1]
        } else {
            return self
        }
    }
}
