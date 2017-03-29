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
}

class Platform: Field {
    dynamic var abbreviation: String?    = nil
    dynamic var company:      Company?   = nil
    dynamic var image:        ImageList? = nil
    dynamic var custom:       Bool       = false
    
    let ownedGames: LinkingObjects<Game> = LinkingObjects(fromType: Game.self, property: "platform")
    
    private var gettingDetails: Bool = false
    private var tempJson: [String : Any] = [:]
    
    required init(json: [String : Any]) {
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
    
    override static func ignoredProperties() -> [String] {
        return ["gettingDetails", "tempJson"]
    }
    
    func deepCopy() -> Platform {
        let newPlatform = Platform()
        newPlatform.abbreviation = self.abbreviation
        newPlatform.company = self.company?.deepCopy()
        newPlatform.idNumber = self.idNumber
        newPlatform.apiDetailUrl = self.apiDetailUrl
        newPlatform.siteDetailUrl = self.siteDetailUrl
        newPlatform.name = self.name
        newPlatform.linkCount = self.linkCount
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
                } else {
                    self.company?.linkCount = 0
                }
            }
        }
    }
    
    func updateDetails(_ completionHandler: @escaping (Result<Any>) -> Void) {
        self.gettingDetails = true
        if let apiDetailUrl = self.apiDetailUrl {
            let url = apiDetailUrl + "?api_key=" + GAME_API_KEY + "&format=json&field_list=company,image"
            Alamofire.request(url)
                .responseJSON { response in
                    self.gettingDetails = false
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
                        self.tempJson = jsonResults
                        completionHandler(.success(BackendError.objectSerialization(reason: "success")))
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
                    self.company?.update {
                        self.company?.linkCount += 1
                    }
                } else {
                    self.company?.linkCount = 1
                    self.company?.add()
                }
                super.add()
            }
            if self.image != nil {
                if let dbImage = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) platform") {
                    self.update {
                        self.image = dbImage
                    }
                }
                super.add()
            }
            if (self.company == nil || self.image == nil) && !self.gettingDetails {
                self.updateDetails { results in
                    if let error = results.error {
                        print(error.localizedDescription)
                    } else {
                        if let companyJson = self.tempJson[PlatformFields.Company.rawValue] as? [String: Any] {
                            if let dbCompany = realm?.object(ofType: Company.self, forPrimaryKey: Field.idNumber(fromJson: companyJson)) {
                                if self.company == nil || self.company?.idNumber != dbCompany.idNumber {
                                    self.update {
                                        self.company = dbCompany
                                    }
                                    self.company?.update {
                                        self.company?.linkCount += 1
                                    }
                                }
                            } else {
                                self.update {
                                    self.company = Company(json: companyJson)
                                }
                                self.company?.update {
                                    self.company?.linkCount = 1
                                }
                                self.company?.add()
                            }
                        }
                        if let imageJson = self.tempJson[PlatformFields.Image.rawValue] as? [String: Any] {
                            var imageObject = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) platform")
                            if imageObject == nil {
                                imageObject = ImageList(json: imageJson)
                                imageObject?.id = "\(self.idNumber) platform"
                            }
                            self.update {
                                self.image = imageObject
                            }
                        }
                    }
                    super.add()
                }
            }
        }
    }
    
    override func delete() {
        if let company = self.company {
            company.update {
                company.linkCount -= 1
            }
            if company.linkCount <= 0 {
                company.delete()
            }
        }
        if let image = self.image {
            image.delete()
        }
        super.delete()
    }
    
    func deleteRetainCopy() -> Platform {
        let newPlatform = Platform()
        newPlatform.abbreviation = self.abbreviation
        newPlatform.idNumber = self.idNumber
        newPlatform.apiDetailUrl = self.apiDetailUrl
        newPlatform.siteDetailUrl = self.siteDetailUrl
        newPlatform.name = self.name
        newPlatform.linkCount = self.linkCount
        
        if let company = self.company {
            company.update {
                company.linkCount -= 1
            }
            if company.linkCount <= 0 {
                newPlatform.company = company.deepCopy()
                company.delete()
            } else {
                newPlatform.company = company
            }
        }
        super.delete()
        return newPlatform
    }
}
