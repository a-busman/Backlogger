//
//  ImageList.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import RealmSwift
import Realm

enum ImageFields: String {
    case IconUrl   = "icon_url"
    case MediumUrl = "medium_url"
    case ScreenUrl = "screen_url"
    case SmallUrl  = "small_url"
    case SuperUrl  = "super_url"
    case ThumbUrl  = "thumb_url"
    case TinyUrl   = "tiny_url"
    case Tags       = "tags"
}

class ImageList: BLObject {
    @objc dynamic var iconUrl:   String? = nil
    @objc dynamic var mediumUrl: String? = nil
    @objc dynamic var screenUrl: String? = nil
    @objc dynamic var smallUrl:  String? = nil
    @objc dynamic var superUrl:  String? = nil
    @objc dynamic var thumbUrl:  String? = nil
    @objc dynamic var tinyUrl:   String? = nil
    @objc dynamic var tags:      String? = nil
    @objc dynamic var id:        String? = nil
    
    required init(json: [String : Any]) {
        super.init()
        self.iconUrl   = json[ImageFields.IconUrl.rawValue]   as? String
        self.mediumUrl = json[ImageFields.MediumUrl.rawValue] as? String
        self.screenUrl = json[ImageFields.ScreenUrl.rawValue] as? String
        self.smallUrl  = json[ImageFields.SmallUrl.rawValue]  as? String
        self.superUrl  = json[ImageFields.SuperUrl.rawValue]  as? String
        self.thumbUrl  = json[ImageFields.ThumbUrl.rawValue]  as? String
        self.tinyUrl   = json[ImageFields.TinyUrl.rawValue]   as? String
        self.tags      = json[ImageFields.Tags.rawValue]      as? String
    }
    
    required init() {
        super.init()
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func deepCopy() -> ImageList {
        let newImageList = ImageList()
        newImageList.iconUrl = self.iconUrl
        newImageList.mediumUrl = self.mediumUrl
        newImageList.screenUrl = self.screenUrl
        newImageList.smallUrl = self.smallUrl
        newImageList.superUrl = self.superUrl
        newImageList.thumbUrl = self.thumbUrl
        newImageList.tinyUrl = self.tinyUrl
        newImageList.tags = self.tags
        newImageList.id = self.id
        return newImageList
    }
    
    func deleteRetainCopy() -> ImageList {
        let newImageList = self.deepCopy()
        self.delete()
        return newImageList
    }
    
    private func getChild(from field: ImageFields) -> String? {
        switch field {
        case .IconUrl:
            return self.iconUrl
        case .MediumUrl:
            return self.mediumUrl
        case .ScreenUrl:
            return self.screenUrl
        case .SmallUrl:
            return self.smallUrl
        case .SuperUrl:
            return self.superUrl
        case .ThumbUrl:
            return self.thumbUrl
        case .TinyUrl:
            return self.tinyUrl
        case .Tags:
            return self.tags
        }
    }
    
    static let defaultImageList: [String] = [
        "3026329-gb_default-16_9.png",
        "gblogo.png",
        "question_mark.jpg"
    ]
    
    func isDefaultPlaceholder(field: ImageFields) -> Bool {
        guard let child = self.getChild(from: field) else { return true }
        for url in ImageList.defaultImageList {
            if child.contains(url) {
                return true
            }
        }
        return false
    }
    
    class func isDefaultPlaceholder(url: URL) -> Bool {
        for dUrl in defaultImageList {
            if url.absoluteString.contains(dUrl) {
                return true
            }
        }
        return false
    }

    func getImage(field: ImageFields, _ completionHandler: @escaping (Result<UIImage>) -> Void) {
        var imageUrl: String
        switch field {
        case .IconUrl:
            imageUrl = self.iconUrl!
        case .MediumUrl:
            imageUrl = self.mediumUrl!
        case .ScreenUrl:
            imageUrl = self.screenUrl!
        case .SmallUrl:
            imageUrl = self.smallUrl!
        case .SuperUrl:
            imageUrl = self.superUrl!
        case .ThumbUrl:
            imageUrl = self.thumbUrl!
        case .TinyUrl:
            imageUrl = self.tinyUrl!
        case .Tags:
            completionHandler(.failure(BackendError.objectSerialization(reason: "Cannot get tag as a URL")))
            return
        }
        guard var urlComponents = URLComponents(string: imageUrl) else {
            let error = BackendError.urlError(reason: "Tried to load an invalid URL")
            completionHandler(.failure(error))
            return
        }
        urlComponents.scheme = "https"
        
        guard let url = try? urlComponents.asURL() else {
            let error = BackendError.urlError(reason: "Tried to load an invalid URL")
            completionHandler(.failure(error))
            return
        }

        Alamofire.request(url)
            .response { response in
                guard let imageData = response.data else {
                    
                    NSLog("Could not get image from image URL returned in search results")
                    completionHandler(.failure(BackendError.objectSerialization(reason:
                        "Could not get image from image URL returned in search results")))
                    return
                }
                if let image = UIImage(data: imageData) {
                    completionHandler(.success(image))
                } else {
                    NSLog("Couldn't convert to UIImage")
                    NSLog("URL: \((response.request?.url?.absoluteString)!)")
                    completionHandler(.failure(BackendError.objectSerialization(reason: "Could not convert data to UIImage")))
                }
        }
    }
}
