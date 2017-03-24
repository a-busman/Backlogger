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
}

class Platform: Field {
    dynamic var abbreviation: String?  = nil
    dynamic var company:      Company? = nil
    
    private var gettingCompany: Bool = false
    private var tempCompanyJson: [String : Any] = [:]
    
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
        return ["gettingCompany", "tempCompanyJson"]
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
    
    func updateCompanyDetails(_ completionHandler: @escaping (Result<Any>) -> Void) {
        self.gettingCompany = true
        if let apiDetailUrl = self.apiDetailUrl {
            let url = apiDetailUrl + "?api_key=" + GAME_API_KEY + "&format=json&field_list=company"
            Alamofire.request(url)
                .responseJSON { response in
                    self.gettingCompany = false
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
                        if let jsonCompany = jsonResults[PlatformFields.Company.rawValue] as? [String : Any] {
                            self.tempCompanyJson = jsonCompany
                            completionHandler(.success(BackendError.objectSerialization(reason: "success")))
                        } else {
                            completionHandler(.failure(BackendError.objectSerialization(reason: "Could not convert company")))
                        }
                    } else {
                        completionHandler(.failure(BackendError.objectSerialization(reason: "could not platform")))
                    }
            }
        } else {
            completionHandler(.failure(BackendError.objectSerialization(reason: "no api detail url")))
            return
        }
    }
    
    override func add() {
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
        if self.company == nil && !self.gettingCompany {
            self.updateCompanyDetails { results in
                if let error = results.error {
                    print(error.localizedDescription)
                } else {
                    if let dbCompany = realm?.object(ofType: Company.self, forPrimaryKey: Field.idNumber(fromJson: self.tempCompanyJson)) {
                        self.update {
                            self.company = dbCompany
                        }
                        self.company?.update {
                            self.company?.linkCount += 1
                        }
                    } else {
                        self.update {
                            self.company = Company(json: self.tempCompanyJson)
                        }
                        self.company?.update {
                            self.company?.linkCount = 1
                        }
                        self.company?.add()
                    }
                }
                super.add()
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
