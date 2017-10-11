//
//  Game.swift
//  Backlogger
//
//  Created by Alex Busman on 2/13/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import UIKit.UIImage
import Alamofire
import RealmSwift
import Realm

enum GameFields: String {
    case Aliases                   = "aliases"
    case Characters                = "characters"
    case Concepts                  = "concepts"
    case DateAdded                 = "date_added"
    case DateLastUpdated           = "date_last_updated"
    case Deck                      = "deck"
    case Description               = "description"
    case Developers                = "developers"
    case ExpectedReleaseDay        = "expected_release_day"
    case ExpectedReleaseMonth      = "expected_release_month"
    case ExpectedReleaseQuarter    = "expected_release_quarter"
    case ExpectedReleaseYear       = "expected_release_year"
    case FirstAppearanceCharacters = "first_appearance_characters"
    case FirstAppearanceConcepts   = "first_appearance_concepts"
    case FirstAppearanceLocations  = "first_appearance_locations"
    case FirstAppearanceObjects    = "first_appearance_objects"
    case FirstAppearancePeople     = "first_appearance_people"
    case Franchises                = "franchises"
    case Genres                    = "genres"
    case Image                     = "image"
    case Images                    = "images"
    case KilledCharacters          = "killed_characters"
    case Locations                 = "locations"
    case NumberOfUserReviews       = "number_of_user_reviews"
    case Objects                   = "objects"
    case OriginalGameRating        = "original_game_rating"
    case OriginalReleaseDate       = "original_release_date"
    case People                    = "people"
    case Platforms                 = "platforms"
    case Publishers                = "publishers"
    case Releases                  = "releases"
    case Reviews                   = "reviews"
    case SimilarGames              = "similar_games"
    case Themes                    = "themes"
    case Videos                    = "videos"
}

enum BackendError: Error {
    case urlError(reason: String)
    case objectSerialization(reason: String)
}

class GameField: Field {
    dynamic var deck:         String?         = nil
    dynamic var releaseDate:  String?         = nil
    dynamic var expectedDate: Int             = 0
    dynamic var imageUrl:     String?         = nil
    dynamic var image:        ImageList?      = nil
    dynamic var hasDetails:   Bool            = false
    dynamic var numReviews:   Int             = 0
    dynamic var steamAppId:   Int             = 0
    dynamic var onlySteam:    Bool            = false
            var images:       List<ImageList> = List<ImageList>()
            var developers:   List<Developer> = List<Developer>()
            var genres:       List<Genre>     = List<Genre>()
            var publishers:   List<Publisher> = List<Publisher>()
            var platforms:    List<Platform>  = List<Platform>()
            var characters:   List<GameCharacter> = List<GameCharacter>()
    
    let ownedGames: LinkingObjects<Game> = LinkingObjects(fromType: Game.self, property: "gameFields")
    
    var libraryGames: Results<Game>? {
        return realm?.objects(Game.self).filter("inLibrary = true")
    }
    var wishlistGames: Results<Game>? {
        return realm?.objects(Game.self).filter("inWishlist = true")
    }
    
    static var request:   DataRequest?
    static var requestTimer: Timer?
    
    required init(json: [String: Any], fromDb: Bool) {
        super.init(json: json)
        self.updateGameDetailsFromJson(json: json, fromDb: fromDb)
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
    
    func updateGameDetailsFromJson(json: [String: Any], fromDb: Bool) {
        self.update {
            self.deck         = json[GameFields.Deck.rawValue]                as? String ?? ""
            self.releaseDate  = json[GameFields.OriginalReleaseDate.rawValue] as? String ?? ""
            self.expectedDate = json[GameFields.ExpectedReleaseYear.rawValue] as? Int ?? 0
            self.numReviews   = json[GameFields.NumberOfUserReviews.rawValue] as? Int ?? 0
        }
        if fromDb {
            autoreleasepool {
                let realm = try? Realm()
                // Get from database, or create new
                if let jsonPlatforms = json[GameFields.Platforms.rawValue] as? [[String: Any]] {
                    for jsonPlatform in jsonPlatforms {
                        let platformId = jsonPlatform[GenericFields.Id.rawValue] as? Int ?? 0
                        var platform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId)
                        var inPlatforms = false
                        
                        for p in self.platforms {
                            if p.idNumber == platformId {
                                inPlatforms = true
                                break
                            }
                        }
                        if platform == nil {
                            platform = Platform(json: jsonPlatform)
                            if self.ownedGames.count > 0 {
                                platform?.add()
                            }
                        }
                        if !inPlatforms {
                            self.update {
                                self.platforms.append(platform!)
                            }
                        }
                    }
                }
                if let jsonDevelopers = json[GameFields.Developers.rawValue] as? [[String: Any]] {
                    for jsonDeveloper in jsonDevelopers {
                        let developerId = jsonDeveloper[GenericFields.Id.rawValue] as? Int ?? 0
                        var developer = realm?.object(ofType: Developer.self, forPrimaryKey: developerId)
                        var inDevelopers = false
                        
                        for d in self.developers {
                            if d.idNumber == developerId {
                                inDevelopers = true
                                break
                            }
                        }
                        if developer == nil {
                            developer = Developer(json: jsonDeveloper)
                            if self.ownedGames.count > 0 {
                                developer?.add()
                            }
                        }
                        if !inDevelopers {
                            self.update {
                                self.hasDetails = true
                                self.developers.append(developer!)
                            }
                        }
                    }
                }
                if let jsonPublishers = json[GameFields.Publishers.rawValue] as? [[String: Any]] {
                    for jsonPublisher in jsonPublishers {
                        let publisherId = jsonPublisher[GenericFields.Id.rawValue] as? Int ?? 0
                        var publisher = realm?.object(ofType: Publisher.self, forPrimaryKey: publisherId)
                        var inPublishers = false
                        
                        for p in self.publishers {
                            if p.idNumber == publisherId {
                                inPublishers = true
                                break
                            }
                        }
                        if publisher == nil {
                            publisher = Publisher(json: jsonPublisher)
                            if self.ownedGames.count > 0 {
                                publisher?.add()
                            }
                        }
                        if !inPublishers {
                            self.update {
                                self.hasDetails = true
                                self.publishers.append(publisher!)
                            }
                        }
                    }
                }
                if let jsonGenres = json[GameFields.Genres.rawValue] as? [[String: Any]] {
                    for jsonGenre in jsonGenres {
                        let genreId = jsonGenre[GenericFields.Id.rawValue] as? Int ?? 0
                        var genre = realm?.object(ofType: Genre.self, forPrimaryKey: genreId)
                        var inGenres = false
                        
                        for g in self.genres {
                            if g.idNumber == genreId {
                                inGenres = true
                            }
                        }
                        if genre == nil {
                            genre = Genre(json: jsonGenre)
                            if self.ownedGames.count > 0 {
                                genre?.add()
                            }
                        }
                        if !inGenres {
                            self.update {
                                self.hasDetails = true
                                self.genres.append(genre!)
                            }
                        }
                    }
                }
                if let image = json[GameFields.Image.rawValue] as? [String: Any] {
                    var imageObject = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) main")
                    
                    if imageObject == nil {
                        imageObject = ImageList(json: image)
                        imageObject?.id = "\(self.idNumber) main"
                    }
                    self.update {
                        self.image = imageObject
                        self.imageUrl = self.image?.iconUrl
                    }
                }
                if let jsonImages = json[GameFields.Images.rawValue] as? [[String: Any]] {
                    for (i, jsonImage) in jsonImages.enumerated() {
                        var image = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) \(i)")
                        
                        if image == nil {
                            image = ImageList(json: jsonImage)
                            image?.id = "\(self.idNumber) \(i)"
                        }
                        var inImages = false
                        for i in self.images {
                            if i.id == image?.id {
                                inImages = true
                            }
                        }
                        if !inImages {
                            self.update {
                                self.hasDetails = true
                                self.images.append(image!)
                            }
                        }
                    }
                }
                if let jsonCharacters = json[GameFields.Characters.rawValue] as? [[String: Any]] {
                    for jsonCharacter in jsonCharacters {
                        let characterId = jsonCharacter[GenericFields.Id.rawValue] as? Int ?? 0
                        var character = realm?.object(ofType: GameCharacter.self, forPrimaryKey: characterId)
                        var inCharacters = false
                        
                        for c in self.characters {
                            if c.idNumber == characterId {
                                inCharacters = true
                            }
                        }
                        if character == nil {
                            character = GameCharacter(json: jsonCharacter)
                            if self.ownedGames.count > 0 {
                                character?.add()
                            }
                        }
                        if !inCharacters {
                            self.update {
                                self.hasDetails = true
                                self.characters.append(character!)
                            }
                        }
                    }
                }
            }
        } else {
            if let jsonPlatforms = json[GameFields.Platforms.rawValue] as? [[String: Any]] {
                for jsonPlatform in jsonPlatforms {
                    let platform = Platform(json: jsonPlatform)
                    self.platforms.append(platform)
                }
            }
            if let jsonDevelopers = json[GameFields.Developers.rawValue] as? [[String: Any]] {
                for jsonDeveloper in jsonDevelopers {
                    let developer = Developer(json: jsonDeveloper)
                    self.developers.append(developer)
                }
            }
            if let jsonPublishers = json[GameFields.Publishers.rawValue] as? [[String: Any]] {
                for jsonPublisher in jsonPublishers {
                    let publisher = Publisher(json: jsonPublisher)
                    self.publishers.append(publisher)
                }
            }
            if let jsonGenres = json[GameFields.Genres.rawValue] as? [[String: Any]] {
                for jsonGenre in jsonGenres {
                    let genre = Genre(json: jsonGenre)
                    self.genres.append(genre)
                }
            }
            if let image = json[GameFields.Image.rawValue] as? [String: Any] {
                let imageObject = ImageList(json: image)

                imageObject.id = "\(self.idNumber) main"
                self.image = imageObject
                self.imageUrl = self.image?.iconUrl
            }
            if let jsonCharacters = json[GameFields.Characters.rawValue] as? [[String: Any]] {
                for jsonCharacter in jsonCharacters {
                    let character = GameCharacter(json: jsonCharacter)
                    self.characters.append(character)
                }
            }
            if let jsonImages = json[GameFields.Images.rawValue] as? [[String: Any]] {
                for (i, jsonImage) in jsonImages.enumerated() {
                    let image = ImageList(json: jsonImage)
                    
                    image.id = "\(self.idNumber) \(i)"
                    self.hasDetails = true
                    self.images.append(image)
                }
            }
        }
    }
    
    class func endpointForGame() -> String {
        return "https://www.giantbomb.com/api/game/3030-"
    }
    
    private class func gamesArrayFromResponse(_ response: DataResponse<Any>) -> Result<SearchResults> {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            NSLog("\(response.result.error!)")
            return .failure(response.result.error!)
        }
        
        // make sure we got JSON and it's a dictionary
        guard let json = response.result.value as? [String: Any] else {
            NSLog("didn't get games object as JSON from API")
            return .failure(BackendError.objectSerialization(reason:
                "Did not get JSON dictionary in response"))
        }
        
        let results:SearchResults = SearchResults()
        results.error = json["error"] as? String
        results.limit = json["limit"] as? Int
        results.offset = json["offset"] as? Int
        results.numberOfPageResults = json["number_of_page_results"] as? Int
        results.numberOfTotalResults = json["number_of_total_results"] as? Int
        results.statusCode = json["status_code"] as? Int
        results.url = response.request?.mainDocumentURL?.absoluteString
        
        var allGames: [GameField] = []
        if let results = json["results"] as? [[String: Any]] {
            for jsonGame in results {
                let game = GameField(json: jsonGame, fromDb: false)
                allGames.append(game)
            }
        }
        results.results = allGames
        return .success(results)
    }
    
    private class func gameFromResponse(_ response: DataResponse<Any>) -> Result<GameField> {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            NSLog("\(response.result.error!)")
            return .failure(response.result.error!)
        }
        
        // make sure we got JSON and it's a dictionary
        guard let json = response.result.value as? [String: Any] else {
            NSLog("didn't get gamess object as JSON from API")
            return .failure(BackendError.objectSerialization(reason:
                "Did not get JSON dictionary in response"))
        }
        
        let results:SearchResults = SearchResults()
        results.error = json["error"] as? String
        results.limit = json["limit"] as? Int
        results.offset = json["offset"] as? Int
        results.numberOfPageResults = json["number_of_page_results"] as? Int
        results.numberOfTotalResults = json["number_of_total_results"] as? Int
        results.statusCode = json["status_code"] as? Int
        results.url = response.request?.mainDocumentURL?.absoluteString
        var game: GameField?
        if let jsonResults = json["results"] as? [String: Any] {
            game = GameField(json: jsonResults, fromDb: true)
        } else {
            return .failure(BackendError.objectSerialization(reason: "could not find game"))
        }
        return .success(game!)
    }
    
    fileprivate class func getGames(atPath path: String, allowsCancel: Bool, _ completionHandler: @escaping (Result<SearchResults>) -> Void) {
        // make sure it's HTTPS because sometimes the API gives us HTTP URLs
        
        let manager = Alamofire.SessionManager.default
        manager.session.configuration.timeoutIntervalForRequest = 10
        manager.session.configuration.timeoutIntervalForResource = 10

        guard var urlComponents = URLComponents(string: path) else {
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
        if self.request != nil && allowsCancel {
            self.request!.cancel()
        }
        //UIApplication.shared.isNetworkActivityIndicatorVisible = true
        if allowsCancel {
            self.requestTimer?.invalidate()
            self.requestTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                self.request = manager.request(url)
                    .responseJSON { response in
                        //UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        if let error = response.result.error {
                            completionHandler(.failure(error))
                            return
                        }
                        self.request = nil
                        let gamesWrapperResult = GameField.gamesArrayFromResponse(response)
                        completionHandler(gamesWrapperResult)
                }
            })
        } else {
            self.request = manager.request(url)
                .responseJSON { response in
                    //UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if let error = response.result.error {
                        completionHandler(.failure(error))
                        return
                    }
                    self.request = nil
                    let gamesWrapperResult = GameField.gamesArrayFromResponse(response)
                    completionHandler(gamesWrapperResult)
            }
        }
    }
    
    class func buildDetailUrl(fromId id: Int) -> String {
        let url = GameField.endpointForGame() + String(id) + "/"
        return url
    }
    
    class func getGameDetail(withUrl detailUrl: String?, _ completionHandler: @escaping (Result<GameField>) -> Void) {
        guard var detailedUrl = detailUrl else {
            let error = BackendError.objectSerialization(reason: "no detail url")
            completionHandler(.failure(error))
            return
        }
        detailedUrl += "?api_key=" + GAME_API_KEY + "&format=json"
        guard var urlComponents = URLComponents(string: detailedUrl) else {
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
        
        self.request = Alamofire.request(url)
            .responseJSON { response in
                if let error = response.result.error {
                    completionHandler(.failure(error))
                    return
                }
                let gameResult = GameField.gameFromResponse(response)
                if let error = gameResult.error {
                    completionHandler(.failure(error))
                    return
                } else {
                    completionHandler(.success(gameResult.value!))
                }
            }
        
    }
    
    func updateGameDetails(_ completionHandler: @escaping (Result<Any>) -> Void) {
        let idNumber = self.idNumber
        let url = GameField.buildDetailUrl(fromId: idNumber) + "?api_key=" + GAME_API_KEY + "&format=json"
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
                    self.updateGameDetailsFromJson(json: jsonResults, fromDb: true)
                    completionHandler(.success(BackendError.objectSerialization(reason: "success")))
                } else {
                    completionHandler(.failure(BackendError.objectSerialization(reason: "could not find game")))
                }
        }
    }
    
    class func getGames(from steamName: String, _ completionHandler: @escaping (Result<SearchResults>) -> Void) {
        let queryUrl = SearchResults.endpointForSearch() + ("name%%3A" + steamName.replacingOccurrences(of: "’", with: "\'")).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        getGames(atPath:queryUrl, allowsCancel: false, completionHandler)
    }
    
    class func getGames(withQuery query:String, _ completionHandler: @escaping (Result<SearchResults>) -> Void) {
        let queryUrl = SearchResults.endpointForGames() + ("&filter=name:" + query.replacingOccurrences(of: "’", with: "\'")).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        getGames(atPath:queryUrl, allowsCancel: true, completionHandler)
    }
    
    class func getGames(withPageNum pageNum: Int, query: String, prevResults: SearchResults?, _ completionHandler: @escaping (Result<SearchResults>) -> Void) {
        guard let limit = prevResults?.limit else {
            let error = BackendError.objectSerialization(reason: "Limit does not exist")
            completionHandler(.failure(error))
            return
        }
        guard let totalResults = prevResults?.numberOfTotalResults else {
            let error = BackendError.objectSerialization(reason: "Number of Total Results does not exist")
            completionHandler(.failure(error))
            return
        }
        if (pageNum - 1) * limit < totalResults {
            let queryUrl = SearchResults.endpointForGames() + ("&filter=name:" + query.replacingOccurrences(of: "’", with: "\'") + "&offset=\((pageNum - 1) * limit)").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            getGames(atPath:queryUrl, allowsCancel: true, completionHandler)
        } else {
            let error = BackendError.objectSerialization(reason: "Page index out of bounds")
            completionHandler(.failure(error))
            return
        }
    }
    
    func getImage(_ completionHandler: @escaping (Result<UIImage>) -> Void) {
        if self.image != nil {
            self.image?.getImage(field: .IconUrl, completionHandler)
        } else {
            completionHandler(.failure(BackendError.objectSerialization(reason: "No image object")))
        }
    }
    
    func getImage(withSize size: ImageFields, _ completionHandler: @escaping(Result<UIImage>) -> Void) {
        if self.image != nil {
            self.image?.getImage(field: size, completionHandler)
        } else {
            completionHandler(.failure(BackendError.objectSerialization(reason: "No image object")))
        }
    }
    
    func deepCopy() -> GameField {
        let newGameField = GameField()
        newGameField.deck = self.deck
        newGameField.releaseDate = self.releaseDate
        newGameField.expectedDate = self.expectedDate
        newGameField.imageUrl = self.imageUrl
        newGameField.image = self.image?.deepCopy()
        newGameField.name = self.name
        newGameField.idNumber = self.idNumber
        newGameField.apiDetailUrl = self.apiDetailUrl
        newGameField.siteDetailUrl = self.siteDetailUrl
        for image in self.images {
            newGameField.images.append(image.deepCopy())
        }
        for developer in self.developers {
            newGameField.developers.append(developer.deepCopy())
        }
        for genre in self.genres {
            newGameField.genres.append(genre.deepCopy())
        }
        for publisher in self.publishers {
            newGameField.publishers.append(publisher.deepCopy())
        }
        for platform in self.platforms {
            newGameField.platforms.append(platform.deepCopy())
        }
        for character in self.characters {
            newGameField.characters.append(character.deepCopy())
        }
        return newGameField
    }
    
    func syncWithRealm() {
        autoreleasepool {
            let realm = try? Realm()
            
            let imageId = self.image?.id
            let dbImage = realm?.object(ofType: ImageList.self, forPrimaryKey: imageId)
            if dbImage != nil {
                self.image = dbImage!
            }
            
            for (index, image) in self.images.enumerated() {
                let imagesId = image.id
                let dbImages = realm?.object(ofType: ImageList.self, forPrimaryKey: imagesId)
                if dbImages != nil {
                    self.images[index] = dbImages!
                }
            }
            for (index, developer) in self.developers.enumerated() {
                let developerId = developer.idNumber
                let dbDeveloper = realm?.object(ofType: Developer.self, forPrimaryKey: developerId)
                if dbDeveloper != nil {
                    self.developers[index] = dbDeveloper!
                }
            }
            for (index, genre) in self.genres.enumerated() {
                let genreId = genre.idNumber
                let dbGenre = realm?.object(ofType: Genre.self, forPrimaryKey: genreId)
                if dbGenre != nil {
                    self.genres[index] = dbGenre!
                }
            }
            for (index, publisher) in self.publishers.enumerated() {
                let publisherId = publisher.idNumber
                let dbPublisher = realm?.object(ofType: Publisher.self, forPrimaryKey: publisherId)
                if dbPublisher != nil {
                    self.publishers[index] = dbPublisher!
                }
            }
            for (index, platform) in self.platforms.enumerated() {
                let platformId = platform.idNumber
                let dbPlatform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId)
                if dbPlatform != nil {
                    self.platforms[index] = dbPlatform!
                } else {
                    self.platforms[index].syncWithRealm()
                }
            }
            for (index, character) in self.characters.enumerated() {
                let characterId = character.idNumber
                let dbCharacter = realm?.object(ofType: GameCharacter.self, forPrimaryKey: characterId)
                if dbCharacter != nil {
                    self.characters[index] = dbCharacter!
                } else {
                    self.characters[index].syncWithRealm()
                }
            }
        }
    }
    
    class func cancelCurrentRequest() {
        self.request?.cancel()
    }
    
    override func add() {
        autoreleasepool {
            let realm = try? Realm()
            // Update contained objects
            for (index, platform) in self.platforms.enumerated() {
                if let dbPlatform = realm?.object(ofType: Platform.self, forPrimaryKey: platform.idNumber) {
                    self.update {
                        self.platforms[index] = dbPlatform
                    }
                } else {
                    platform.add()
                }
            }
            for (index, developer) in self.developers.enumerated() {
                if let dbDeveloper = realm?.object(ofType: Developer.self, forPrimaryKey: developer.idNumber) {
                    self.update {
                        self.developers[index] = dbDeveloper
                    }
                } else {
                    developer.add()
                }
            }
            for (index, publisher) in self.publishers.enumerated() {
                if let dbPublisher = realm?.object(ofType: Publisher.self, forPrimaryKey: publisher.idNumber) {
                    self.update {
                        self.publishers[index] = dbPublisher
                    }
                } else {
                    publisher.add()
                }
            }
            for (index, genre) in self.genres.enumerated() {
                if let dbGenre = realm?.object(ofType: Genre.self, forPrimaryKey: genre.idNumber) {
                    self.update {
                        self.genres[index] = dbGenre
                    }
                } else {
                    genre.add()
                }
            }
            for (index, character) in self.characters.enumerated() {
                if let dbCharacter = realm?.object(ofType: GameCharacter.self, forPrimaryKey: character.idNumber) {
                    self.update {
                        self.characters[index] = dbCharacter
                    }
                } else {
                    character.add()
                }
            }
        }
        super.add()
    }
    
    override func delete() {
        while self.platforms.count > 0 {
            var platform: Platform!
            self.update {
                platform = self.platforms.remove(at: 0)
            }
            if (platform.linkedGameFields == nil || platform.linkedGameFields!.count == 0) && platform.ownedGames.count == 0 {
                platform.delete()
            }
        }
        while self.developers.count > 0 {
            var developer: Developer!
            self.update {
                developer = self.developers.remove(at: 0)
            }
            if developer.linkingGameFields == nil || developer.linkingGameFields!.count == 0 {
                developer.delete()
            }
        }
        while self.publishers.count > 0 {
            var publisher: Publisher!
            self.update {
                publisher = self.publishers.remove(at: 0)
            }
            if publisher.linkingGameFields == nil || publisher.linkingGameFields!.count == 0 {
                publisher.delete()
            }
        }
        while self.genres.count > 0 {
            var genre: Genre!
            self.update {
                genre = self.genres.remove(at: 0)
            }
            if genre.linkingGameFields == nil || genre.linkingGameFields!.count == 0 {
                genre.delete()
            }
        }
        while self.characters.count > 0 {
            var character: GameCharacter!
            self.update {
                character = self.characters.remove(at: 0)
            }
            if character.linkedGameFields == nil || character.linkedGameFields!.count == 0 {
                character.delete()
            }
        }
        
        self.image?.delete()
        for image in self.images {
            image.delete()
        }
        super.delete()
    }
    
    override func deleteRetainCopy() -> GameField {
        let newGameField = GameField()
        newGameField.deck = self.deck
        newGameField.releaseDate = self.releaseDate
        newGameField.expectedDate = self.expectedDate
        newGameField.imageUrl = self.imageUrl
        newGameField.image = self.image?.deepCopy()
        newGameField.name = self.name
        newGameField.idNumber = self.idNumber
        newGameField.apiDetailUrl = self.apiDetailUrl
        newGameField.siteDetailUrl = self.siteDetailUrl
        newGameField.numReviews = self.numReviews
        newGameField.steamAppId = self.steamAppId
        newGameField.onlySteam = self.onlySteam
        
        self.image?.delete()
        
        while self.platforms.count > 0 {
            var platform: Platform!
            self.update {
                platform = self.platforms.remove(at: 0)
            }
            if (platform.linkedGameFields == nil || platform.linkedGameFields!.count == 0) && platform.ownedGames.count == 0 {
                newGameField.platforms.append(platform.deleteRetainCopy())
            } else {
                newGameField.platforms.append(platform.deepCopy())
            }
        }
        
        while self.developers.count > 0 {
            var developer: Developer!
            self.update {
                developer = self.developers.remove(at: 0)
            }
            if developer.linkingGameFields == nil || developer.linkingGameFields!.count == 0 {
                newGameField.developers.append(developer.deleteRetainCopy())
            } else {
                newGameField.developers.append(developer.deepCopy())
            }
        }
        
        while self.publishers.count > 0 {
            var publisher: Publisher!
            self.update {
                publisher = self.publishers.remove(at: 0)
            }
            if publisher.linkingGameFields == nil || publisher.linkingGameFields!.count == 0 {
                newGameField.publishers.append(publisher.deleteRetainCopy())
            } else {
                newGameField.publishers.append(publisher.deepCopy())
            }
        }
        
        while self.genres.count > 0 {
            var genre: Genre!
            self.update {
                genre = self.genres.remove(at: 0)
            }
            if genre.linkingGameFields == nil || genre.linkingGameFields!.count == 0 {
                newGameField.genres.append(genre.deleteRetainCopy())
            } else {
                newGameField.genres.append(genre.deepCopy())
            }
        }
        
        while self.characters.count > 0 {
            var character: GameCharacter!
            self.update {
                character = self.characters.remove(at: 0)
            }
            if character.linkedGameFields == nil || character.linkedGameFields!.count == 0 {
                newGameField.characters.append(character.deleteRetainCopy())
            } else {
                newGameField.characters.append(character.deepCopy())
            }
        }
        for image in self.images {
            newGameField.images.append(image.deleteRetainCopy())
        }
        super.delete()
        return newGameField
    }
}

class Game: Object {
    private(set) dynamic var uuid      = NSUUID().uuidString
    private(set) dynamic var dateAdded = Date()

    dynamic var gameFields: GameField? = nil
    dynamic var platform:   Platform?  = nil
    dynamic var inLibrary:  Bool       = false
    dynamic var inWishlist: Bool       = false
    dynamic var nowPlaying: Bool       = false
    dynamic var favourite:  Bool       = false
    dynamic var rating:     Int        = 0
    dynamic var progress:   Int        = 0
    dynamic var finished:   Bool       = false
    dynamic var notes:      String?    = nil
    dynamic var fromSteam:  Bool       = false
    
    var linkedPlaylists: Results<Playlist>? {
        return realm?.objects(Playlist.self).filter("%@ IN games", self)
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    func add(_ gameField: GameField?, _ platform: Platform?) {
        autoreleasepool {
            let realm = try? Realm()

            var dbGameField = realm?.object(ofType: GameField.self, forPrimaryKey: (gameField?.idNumber)!)
            if dbGameField == nil {
                gameField?.add()
                dbGameField = gameField
            }
            var dbPlatform = realm?.object(ofType: Platform.self, forPrimaryKey: (platform?.idNumber)!)
            if dbPlatform == nil {
                platform?.add()
                dbPlatform = platform
            }
            self.gameFields = dbGameField
            self.platform   = dbPlatform
            super.add()
            self.update {
                self.gameFields = dbGameField
                self.platform = dbPlatform
            }
        }
    }
    
    override func delete() {
        let platformId = self.platform!.idNumber
        let gameId = self.gameFields!.idNumber
        super.delete()
        autoreleasepool {
            let realm = try? Realm()
            if let dbPlatform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId) {
                if dbPlatform.ownedGames.count == 0 && (dbPlatform.linkedGameFields == nil || dbPlatform.linkedGameFields!.count == 0) {
                    dbPlatform.delete()
                }
            }
            if let dbGameField = realm?.object(ofType: GameField.self, forPrimaryKey: gameId) {
                if dbGameField.ownedGames.count == 0 {
                    dbGameField.delete()
                }
            }
        }
        // Remove from all linked playlists.
        
        if self.linkedPlaylists != nil {
            for playlist in self.linkedPlaylists! {
                var games: [Game] = []
                for game in playlist.games {
                    if game.uuid != self.uuid {
                        games.append(game)
                    }
                }
                playlist.update {
                    playlist.games.removeAll()
                    playlist.games.append(contentsOf: games)
                }
            }
        }
    }
    
    func deleteWithGameFieldCopy() -> GameField {
        let gameField = self.gameFields!
        let platformId = self.platform!.idNumber
        self.update {
            self.gameFields = nil
            self.platform = nil
        }
        
        var newGameField: GameField!
        if gameField.ownedGames.count == 0 {
            newGameField = gameField.deleteRetainCopy() // This takes care of deleting the platform
        } else {
            newGameField = gameField.deepCopy()
        }
        autoreleasepool {
            let realm = try? Realm()
            // If it's a custom platform, delete it.
            if let dbPlatform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId) {
                if dbPlatform.ownedGames.count == 0 {
                    dbPlatform.delete()
                }
            }
        }
        super.delete()
        return newGameField
    }
}
