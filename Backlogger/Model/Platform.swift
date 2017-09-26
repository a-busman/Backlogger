//
//  Platform.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import Alamofire

enum PlatformFields: String {
    case Abbreviation  = "abbreviation"
    case Company       = "company"
    case Image         = "image"
    case ReleaseDate   = "release_date"
}

class Platform: Field {
    dynamic var abbreviation: String?    = nil
    dynamic var company:      Company?   = nil
    dynamic var image:        ImageList? = nil
    dynamic var releaseDate:  String?    = nil
    dynamic var custom:       Bool       = false
    dynamic var hasDetails:   Bool       = false
    
    let ownedGames: LinkingObjects<Game> = LinkingObjects(fromType: Game.self, property: "platform")

    var linkedGameFields: Results<GameField>? {
        return realm?.objects(GameField.self).filter("%@ IN platforms", self)
    }
    
    var progress: Int {
        var progressSum = 0
        for game in self.ownedGames {
            progressSum += game.progress
        }
        if self.ownedGames.count > 0 {
            return progressSum / self.ownedGames.count
        } else {
            return 0
        }
    }
    
    var finished: Int {
        var finishedSum = 0
        for game in self.ownedGames {
            finishedSum += game.finished ? 1 : 0
        }
        return finishedSum
    }
    
    var rating: Int {
        var ratingSum = 0
        for game in self.ownedGames {
            ratingSum += game.rating
        }
        return ratingSum / self.ownedGames.count
    }
    
    override init(json: [String : Any]) {
        self.abbreviation  = json[PlatformFields.Abbreviation.rawValue] as? String
        super.init(json: json)
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
    
    class func customIdBase() -> Int {
        return 100000
    }
    
    func deepCopy() -> Platform {
        let newPlatform = Platform()
        newPlatform.abbreviation = self.abbreviation
        newPlatform.company = self.company?.deepCopy()
        newPlatform.idNumber = self.idNumber
        newPlatform.apiDetailUrl = self.apiDetailUrl
        newPlatform.siteDetailUrl = self.siteDetailUrl
        newPlatform.image = self.image?.deepCopy()
        newPlatform.releaseDate = self.releaseDate
        newPlatform.name = self.name
        return newPlatform
    }
    
    func syncWithRealm() {
        autoreleasepool {
            let realm = try? Realm()
            if let company = self.company {
                let companyId = company.idNumber
                let dbCompany = realm?.object(ofType: Company.self, forPrimaryKey: companyId)
                if dbCompany != nil {
                    self.company = dbCompany
                }
            }
        }
    }
    
    func updateDetailsFromJson(json: [String: Any], fromDb: Bool) {
        autoreleasepool {
            let realm = try? Realm()
            if let companyJson = json[PlatformFields.Company.rawValue] as? [String: Any] {
                if let dbCompany = realm?.object(ofType: Company.self, forPrimaryKey: Field.idNumber(fromJson: companyJson)) {
                    if self.company == nil || self.company?.idNumber != dbCompany.idNumber {
                        self.update {
                            self.company = dbCompany
                        }
                    }
                } else {
                    self.update {
                        self.company = Company(json: companyJson)
                    }
                    self.company?.add()
                }
            }
            if let imageJson = json[PlatformFields.Image.rawValue] as? [String: Any] {
                var imageObject = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) platform")
                if imageObject == nil {
                    imageObject = ImageList(json: imageJson)
                    imageObject?.id = "\(self.idNumber) platform"
                }
                self.update {
                    self.image = imageObject
                }
            }
            self.update {
                self.releaseDate = json[PlatformFields.ReleaseDate.rawValue] as? String
                self.hasDetails = true
            }
        }
    }
    
    func updateDetails(_ completionHandler: @escaping (Result<Any>) -> Void) {
        if let apiDetailUrl = self.apiDetailUrl {
            let url = apiDetailUrl + "?api_key=" + GAME_API_KEY + "&format=json&field_list=company,image,release_date"
            Alamofire.request(url)
                .responseJSON { response in
                    if let error = response.result.error {
                        completionHandler(.failure(error))
                        return
                    }
                    guard let json = response.result.value as? [String: Any] else {
                        completionHandler(.failure(BackendError.objectSerialization(reason:
                            "Did not get JSON dictionary in response")))
                        return
                    }
                    
                    let results = SearchResults()
                    results.error = json["error"] as? String
                    results.limit = json["limit"] as? Int
                    results.offset = json["offset"] as? Int
                    results.numberOfPageResults = json["number_of_page_results"] as? Int
                    results.numberOfTotalResults = json["number_of_total_results"] as? Int
                    results.statusCode = json["status_code"] as? Int
                    results.url = response.request?.mainDocumentURL?.absoluteString
                    if let jsonResults = json["results"] as? [String: Any] {
                        completionHandler(.success(jsonResults))
                    } else {
                        completionHandler(.failure(BackendError.objectSerialization(reason: "could not get platform details")))
                    }
            }
        } else {
            completionHandler(.failure(BackendError.objectSerialization(reason: "no api detail url")))
            return
        }
    }
    
    override func add() {
        autoreleasepool {
            let realm = try? Realm()
            if self.company != nil {
                if let dbCompany = realm?.object(ofType: Company.self, forPrimaryKey: (self.company?.idNumber)!) {
                    self.update {
                        self.company = dbCompany
                    }
                } else {
                    self.company?.add()
                }
                
            }
            if self.image != nil {
                if let dbImage = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) platform") {
                    self.update {
                        self.image = dbImage
                    }
                } else {
                    self.image?.add()
                }
            }
            super.add()
            if (self.company == nil || self.image == nil) {
                self.updateDetails { results in
                    if let error = results.error {
                        NSLog("\(error.localizedDescription)")
                    } else {
                        self.updateDetailsFromJson(json: results.value as! [String : Any], fromDb: true)
                    }
                    super.add()
                }
            }
        }
    }
    
    override func delete() {
        if let company = self.company {
            self.update {
                self.company = nil
            }
            if company.platforms.count == 0 {
                company.delete()
            }
        }
        if let image = self.image {
            image.delete()
        }
        super.delete()
    }

    override func deleteRetainCopy() -> Platform {
        let newPlatform = Platform()
        newPlatform.abbreviation = self.abbreviation
        newPlatform.idNumber = self.idNumber
        newPlatform.apiDetailUrl = self.apiDetailUrl
        newPlatform.siteDetailUrl = self.siteDetailUrl
        newPlatform.name = self.name
        newPlatform.image = self.image?.deleteRetainCopy()
        newPlatform.releaseDate = self.releaseDate
        newPlatform.hasDetails = self.hasDetails
        
        if let company = self.company {
            self.update {
                self.company = nil
            }
            if company.platforms.count == 0 {
                newPlatform.company = company.deleteRetainCopy()
            } else {
                newPlatform.company = company.deepCopy()
            }
        }
        super.delete()
        return newPlatform
    }
}
