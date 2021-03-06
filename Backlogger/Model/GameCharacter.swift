//
//  GameCharacter.swift
//  Backlogger
//
//  Created by Alex Busman on 6/26/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import Alamofire

class GameCharacter: Field {
    @objc dynamic var image: ImageList? = nil
    @objc dynamic var hasImage: Bool = false
    
    static var loadingQueue: DispatchQueue = DispatchQueue(label: "character.load.queue")
    
    var linkedGameFields: Results<GameField>? {
        return realm?.objects(GameField.self).filter("%@ IN characters", self)
    }
    
    override init(json: [String : Any]) {
        super.init(json: json)
    }
    
    required init() {
        super.init()
    }
    
    func updateDetailsFromJson(json: [String: Any], fromDb: Bool) {
        autoreleasepool {
            let realm = try? Realm()
            if let imageJson = json[GameFields.Image.rawValue] as? [String: Any] {
                if !self.isInvalidated {
                    var imageObject = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) character")
                    if imageObject == nil {
                        imageObject = ImageList(json: imageJson)
                        imageObject?.id = "\(self.idNumber) character"
                    }
                    self.update {
                        self.image = imageObject
                        self.hasImage = true
                    }
                }
            }
        }
    }
    
    func updateDetails(id: Int, _ completionHandler: @escaping (Result<Any>) -> Void) {
        autoreleasepool{
            let realm = try! Realm()
            var character: GameCharacter? = realm.object(ofType: GameCharacter.self, forPrimaryKey: id)
            if character == nil {
                character = self
            }
            if !character!.isInvalidated,
                let apiDetailUrl = character?.apiDetailUrl {
                let url = apiDetailUrl + "?api_key=" + GAME_API_KEY + "&format=json&fields_list=image"
                GameCharacter.loadingQueue.sync {
                    sleep(1)
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
                }
            } else {
                completionHandler(.failure(BackendError.objectSerialization(reason: "no api detail url")))
                return
            }
        }
    }
    
    func syncWithRealm() {
        autoreleasepool {
            let realm = try? Realm()
            let imageId = self.image?.id
            let dbImage = realm?.object(ofType: ImageList.self, forPrimaryKey: imageId)
            if dbImage != nil {
                self.image = dbImage!
                self.hasImage = true
            }
        }
    }
    
    override func add() {
        autoreleasepool {
            let realm = try? Realm()
            if self.image != nil {
                if let dbImage = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) character") {
                    self.update {
                        self.image = dbImage
                    }
                } else {
                    self.image?.add()
                }
                self.hasImage = true
            }
            super.add()
        }
    }
    
    func deepCopy() -> GameCharacter {
        let newField = GameCharacter()
        newField.apiDetailUrl = self.apiDetailUrl
        newField.idNumber = self.idNumber
        newField.name = self.name
        newField.siteDetailUrl = self.siteDetailUrl
        newField.image = self.image?.deepCopy()
        newField.hasImage = self.hasImage
        return newField
    }
    
    override func deleteRetainCopy() -> GameCharacter {
        let newField = self.deepCopy()
        super.delete()
        return newField
    }
}
