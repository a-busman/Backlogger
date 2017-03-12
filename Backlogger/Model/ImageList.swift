//
//  ImageList.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import Alamofire

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

class ImageList {
    var iconUrl:   String?
    var mediumUrl: String?
    var screenUrl: String?
    var smallUrl:  String?
    var superUrl:  String?
    var thumbUrl:  String?
    var tinyUrl:   String?
    var tags:       String?
    
    required init(json: [String : Any]) {
        self.iconUrl   = json[ImageFields.IconUrl.rawValue]   as? String
        self.mediumUrl = json[ImageFields.MediumUrl.rawValue] as? String
        self.screenUrl = json[ImageFields.ScreenUrl.rawValue] as? String
        self.smallUrl  = json[ImageFields.SmallUrl.rawValue]  as? String
        self.superUrl  = json[ImageFields.SuperUrl.rawValue]  as? String
        self.thumbUrl  = json[ImageFields.ThumbUrl.rawValue]  as? String
        self.tinyUrl   = json[ImageFields.TinyUrl.rawValue]   as? String
        self.tags      = json[ImageFields.Tags.rawValue]      as? String
        
        self.removeSlashesFromUrls()
    }
    
    private func removeSlashesFromUrls() {
        /*self.iconUrl = self.iconUrl?.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.mediumUrl = self.mediumUrl?.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.screenUrl = self.screenUrl?.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.smallUrl = self.smallUrl?.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.superUrl = self.superUrl?.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.thumbUrl = self.thumbUrl?.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.tinyUrl = self.tinyUrl?.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)*/

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
                    
                    print("Could not get image from image URL returned in search results")
                    completionHandler(.failure(BackendError.objectSerialization(reason:
                        "Could not get image from image URL returned in search results")))
                    return
                }
                if let image = UIImage(data: imageData) {
                    completionHandler(.success(image))
                } else {
                    print("Couldn't convert to UIImage")
                    print("URL: \(response.request?.url?.absoluteString)")
                    completionHandler(.failure(BackendError.objectSerialization(reason: "Could not convert data to UIImage")))
                }
        }
    }
}
