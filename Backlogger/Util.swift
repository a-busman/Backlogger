//
//  Util.swift
//  Backlogger
//
//  Created by Alex Busman on 5/19/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration
import GoogleMobileAds

class Util {
#if DEBUG
    private static let AD_UNIT_ID = "ca-app-pub-3940256099942544/6300978111"
#else
    private static let AD_UNIT_ID = "ca-app-pub-1890106170781921/7267833277"
#endif
    
    class func getNewBannerAd<T: UIViewController & GADBannerViewDelegate>(for vc: T) -> GADBannerView {
        let bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.rootViewController = vc
        bannerView.adUnitID = AD_UNIT_ID
        bannerView.delegate = vc
        bannerView.load(GADRequest())
        
        return bannerView
    }
    
    class func showBannerAd(in view: UIView, banner: GADBannerView) {
        if banner.superview == nil {
            banner.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(banner)
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        }
    }
    
    class var appColor: UIColor {
        return UIColor(red: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
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
            Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_")
        return String(text.filter {okayChars.contains($0) })
    }
    
    class var isICloudContainerAvailable: Bool {
        get {
            if let _ = FileManager.default.ubiquityIdentityToken {
                return true
            } else {
                return false
            }
        }
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
                    romanValue += romanChar
                }
                
                startingValue -= arabicValue * div
            }
        }
        
        return romanValue
    }
    
    class func isInternetAvailable() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
}

extension String {
    func index(_ i: Int) -> String.Index {
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
        return String(self[index(r.lowerBound)..<index(r.upperBound)])
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
                
                d[i][j] = Swift.min(
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

public enum Model : String {
    case simulator         = "simulator/sandbox",
    iPod1                  = "iPod 1",
    iPod2                  = "iPod 2",
    iPod3                  = "iPod 3",
    iPod4                  = "iPod 4",
    iPod5                  = "iPod 5",
    iPod6                  = "iPod 6",
    iPod7                  = "iPod 7",
    iPad2                  = "iPad 2",
    iPad3                  = "iPad 3",
    iPad4                  = "iPad 4",
    iPad6                  = "iPad 6",
    iPad6_cell             = "iPad 6 cellular",
    iPhone4                = "iPhone 4",
    iPhone4S               = "iPhone 4S",
    iPhone5                = "iPhone 5",
    iPhone5S               = "iPhone 5S",
    iPhone5C               = "iPhone 5C",
    iPadMini1              = "iPad Mini 1",
    iPadMini2              = "iPad Mini 2",
    iPadMini3              = "iPad Mini 3",
    iPadMini4              = "iPad Mini 4",
    iPadMini4_cell         = "iPad Mini 4 cellular",
    iPadMini5              = "iPad Mini 5",
    iPadMini5_cell         = "iPad Mini 5 cellular",
    iPadAir1               = "iPad Air 1",
    iPadAir2               = "iPad Air 2",
    iPadAir3               = "iPad Air 3",
    iPadAir3_cell          = "iPad Air 3 cellular",
    iPadPro9_7             = "iPad Pro 9.7\"",
    iPadPro9_7_cell        = "iPad Pro 9.7\" cellular",
    iPadPro12_9            = "iPad Pro 12.9\"",
    iPadPro12_9_cell       = "iPad Pro 12.9\" cellular",
    iPadPro12_9_2          = "iPad Pro 12.9\" 2",
    iPadPro12_9_2_cell     = "iPad Pro 12.9\" 2 cellular",
    iPadPro12_9_3          = "iPad Pro 12.9\" 3",
    iPadPro12_9_3_1TB      = "iPad Pro 12.9\" 3 1TB",
    iPadPro12_9_3_cell     = "iPad Pro 12.9\" 3 cellular",
    iPadPro12_9_3_1TB_cell = "iPad Pro 12.9\" 3 1TB cellular",
    iPadPro10_5            = "iPad Pro 10.5\"",
    iPadPro10_5_cell       = "iPad Pro 10.5\" cellular",
    iPadPro11              = "iPad Pro 11\"",
    iPadPro11_1TB          = "iPad Pro 11\" 1TB",
    iPadPro11_cell         = "iPad Pro 11\" cellular",
    iPadPro11_1TB_cell     = "iPad Pro 11\" 1TB cellular",
    iPhone6                = "iPhone 6",
    iPhone6plus            = "iPhone 6 Plus",
    iPhone6S               = "iPhone 6S",
    iPhone6Splus           = "iPhone 6S Plus",
    iPhoneSE               = "iPhone SE",
    iPhone7                = "iPhone 7",
    iPhone7plus            = "iPhone 7 Plus",
    iPhone8                = "iPhone 8",
    iPhone8plus            = "iPhone 8 Plus",
    iPhoneX                = "iPhone X",
    iPhoneXS               = "iPhone XS",
    iPhoneXSMax            = "iPhone XS Max",
    iPhoneXR               = "iPhone XR",
    unrecognized           = "?unrecognized?"
}

public extension UIDevice {
    var type: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
                
            }
        }
        let modelMap : [ String : Model ] = [
            "i386"       : .simulator,
            "x86_64"     : .simulator,
            "iPod1,1"    : .iPod1,
            "iPod2,1"    : .iPod2,
            "iPod3,1"    : .iPod3,
            "iPod4,1"    : .iPod4,
            "iPod5,1"    : .iPod5,
            "iPod7,1"    : .iPod6,
            "iPod9,1"    : .iPod7,
            "iPad2,1"    : .iPad2,
            "iPad2,2"    : .iPad2,
            "iPad2,3"    : .iPad2,
            "iPad2,4"    : .iPad2,
            "iPad2,5"    : .iPadMini1,
            "iPad2,6"    : .iPadMini1,
            "iPad2,7"    : .iPadMini1,
            "iPhone3,1"  : .iPhone4,
            "iPhone3,2"  : .iPhone4,
            "iPhone3,3"  : .iPhone4,
            "iPhone4,1"  : .iPhone4S,
            "iPhone5,1"  : .iPhone5,
            "iPhone5,2"  : .iPhone5,
            "iPhone5,3"  : .iPhone5C,
            "iPhone5,4"  : .iPhone5C,
            "iPad3,1"    : .iPad3,
            "iPad3,2"    : .iPad3,
            "iPad3,3"    : .iPad3,
            "iPad3,4"    : .iPad4,
            "iPad3,5"    : .iPad4,
            "iPad3,6"    : .iPad4,
            "iPhone6,1"  : .iPhone5S,
            "iPhone6,2"  : .iPhone5S,
            "iPad4,1"    : .iPadAir1,
            "iPad4,4"    : .iPadMini2,
            "iPad4,5"    : .iPadMini2,
            "iPad4,6"    : .iPadMini2,
            "iPad4,7"    : .iPadMini3,
            "iPad4,8"    : .iPadMini3,
            "iPad4,9"    : .iPadMini3,
            "iPad5,1"    : .iPadMini4,
            "iPad5,2"    : .iPadMini4_cell,
            "iPad5,3"    : .iPadAir2,
            "iPad6,3"    : .iPadPro9_7,
            "iPad6,11"   : .iPadPro9_7,
            "iPad6,4"    : .iPadPro9_7_cell,
            "iPad6,12"   : .iPadPro9_7_cell,
            "iPad6,7"    : .iPadPro12_9,
            "iPad6,8"    : .iPadPro12_9_cell,
            "iPad7,1"    : .iPadPro12_9_2,
            "iPad7,2"    : .iPadPro12_9_2_cell,
            "iPad7,3"    : .iPadPro10_5,
            "iPad7,4"    : .iPadPro10_5_cell,
            "iPad7,5"    : .iPad6,
            "iPad7,6"    : .iPad6_cell,
            "iPad8,1"    : .iPadPro11,
            "iPad8,2"    : .iPadPro11_1TB,
            "iPad8,3"    : .iPadPro11_cell,
            "iPad8,4"    : .iPadPro11_1TB_cell,
            "iPad8,5"    : .iPadPro12_9_3,
            "iPad8,6"    : .iPadPro12_9_3_1TB,
            "iPad8,7"    : .iPadPro12_9_3_cell,
            "iPad8,8"    : .iPadPro12_9_3_1TB_cell,
            "iPad11,1"   : .iPadMini5,
            "iPad11,2"   : .iPadMini5_cell,
            "iPad11,3"   : .iPadAir3,
            "iPad11,4"   : .iPadAir3_cell,
            "iPhone7,1"  : .iPhone6plus,
            "iPhone7,2"  : .iPhone6,
            "iPhone8,1"  : .iPhone6S,
            "iPhone8,2"  : .iPhone6Splus,
            "iPhone8,4"  : .iPhoneSE,
            "iPhone9,1"  : .iPhone7,
            "iPhone9,2"  : .iPhone7plus,
            "iPhone9,3"  : .iPhone7,
            "iPhone9,4"  : .iPhone7plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,2" : .iPhone8plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,4" : .iPhone8,
            "iPhone10,5" : .iPhone8plus,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSMax,
            "iPhone11,6" : .iPhoneXSMax,
            "iPhone11,8" : .iPhoneXR
        ]
        
        if let model = modelMap[String.init(validatingUTF8: modelCode!)!] {
            return model
        }
        return Model.unrecognized
    }
}
