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
            var images:       List<ImageList> = List<ImageList>()
            var developers:   List<Developer> = List<Developer>()
            var genres:       List<Genre>     = List<Genre>()
            var publishers:   List<Publisher> = List<Publisher>()
            var platforms:    List<Platform>  = List<Platform>()
    
    static var request:   DataRequest?
    
    required init(json: [String: Any]) {
        super.init(json: json)
        self.updateGameDetailsFromJson(json: json)
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
    
    func updateGameDetailsFromJson(json: [String: Any]) {
        self.update {
            self.deck         = json[GameFields.Deck.rawValue]                as? String ?? ""
            self.platforms    = json[GameFields.Platforms.rawValue]           as? List<Platform>  ?? List<Platform>()
            self.developers   = json[GameFields.Developers.rawValue]          as? List<Developer> ?? List<Developer>()
            self.publishers   = json[GameFields.Publishers.rawValue]          as? List<Publisher> ?? List<Publisher>()
            self.genres       = json[GameFields.Genres.rawValue]              as? List<Genre>     ?? List<Genre>()
            self.releaseDate  = json[GameFields.OriginalReleaseDate.rawValue] as? String ?? ""
            self.expectedDate = json[GameFields.ExpectedReleaseYear.rawValue] as? Int ?? 0
            
            // Get from database, or create new
            if let jsonPlatforms = json[GameFields.Platforms.rawValue] as? [[String: Any]] {
                for jsonPlatform in jsonPlatforms {
                    var platform = realm?.object(ofType: Platform.self, forPrimaryKey: (jsonPlatform[GenericFields.Id.rawValue] as? Int ?? 0))
                    if platform == nil {
                        platform = Platform(json: jsonPlatform)
                        realm?.add(platform!, update: true)
                    }
                    platform?.linkCount += 1
                    self.platforms.append(platform!)
                }
            }
            if let jsonDevelopers = json[GameFields.Developers.rawValue] as? [[String: Any]] {
                for jsonDeveloper in jsonDevelopers {
                    var developer = realm?.object(ofType: Developer.self, forPrimaryKey: (jsonDeveloper[GenericFields.Id.rawValue] as? Int ?? 0))
                    if developer == nil {
                        developer = Developer(json: jsonDeveloper)
                        realm?.add(developer!, update: true)
                    }
                    developer?.linkCount += 1
                    self.developers.append(developer!)
                }
            }
            if let jsonPublishers = json[GameFields.Publishers.rawValue] as? [[String: Any]] {
                for jsonPublisher in jsonPublishers {
                    var publisher = realm?.object(ofType: Publisher.self, forPrimaryKey: (jsonPublisher[GenericFields.Id.rawValue] as? Int ?? 0))
                    if publisher == nil {
                        publisher = Publisher(json: jsonPublisher)
                        realm?.add(publisher!, update: true)
                    }
                    publisher?.linkCount += 1
                    self.publishers.append(publisher!)
                }
            }
            if let jsonGenres = json[GameFields.Genres.rawValue] as? [[String: Any]] {
                for jsonGenre in jsonGenres {
                    var genre = realm?.object(ofType: Genre.self, forPrimaryKey: (jsonGenre[GenericFields.Id.rawValue] as? Int ?? 0))
                    if genre == nil {
                        genre = Genre(json: jsonGenre)
                        realm?.add(genre!, update: true)
                    }
                    genre?.linkCount += 1
                    self.genres.append(genre!)
                }
            }
            if let image = json[GameFields.Image.rawValue] as? [String: Any] {
                self.image = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) main")
                if self.image == nil {
                    self.image = ImageList(json: image)
                    self.image?.id = "\(self.idNumber) main"
                }
                self.imageUrl = self.image?.iconUrl
            }
            if let jsonImages = json[GameFields.Images.rawValue] as? [[String: Any]] {
                var i = 0
                
                for jsonImage in jsonImages {
                    var image = realm?.object(ofType: ImageList.self, forPrimaryKey: "\(self.idNumber) \(i)")
                    if image == nil {
                        image = ImageList(json: jsonImage)
                        image?.id = "\(self.idNumber) \(i)"
                    }
                    self.images.append(image!)
                    i += 1
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
            print(response.result.error!)
            return .failure(response.result.error!)
        }
        
        // make sure we got JSON and it's a dictionary
        guard let json = response.result.value as? [String: Any] else {
            print("didn't get gamess object as JSON from API")
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
                let game = GameField(json: jsonGame)
                allGames.append(game)
            }
        }
        results.results = allGames
        return .success(results)
    }
    
    private class func gameFromResponse(_ response: DataResponse<Any>) -> Result<GameField> {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            return .failure(response.result.error!)
        }
        
        // make sure we got JSON and it's a dictionary
        guard let json = response.result.value as? [String: Any] else {
            print("didn't get gamess object as JSON from API")
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
            game = GameField(json: jsonResults)
        } else {
            return .failure(BackendError.objectSerialization(reason: "could not find game"))
        }
        return .success(game!)
    }
    
    fileprivate class func getGames(atPath path: String, _ completionHandler: @escaping (Result<SearchResults>) -> Void) {
        // make sure it's HTTPS because sometimes the API gives us HTTP URLs

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
        if self.request != nil {
            self.request!.cancel()
        }
        self.request = Alamofire.request(url)
            .responseJSON { response in
                if let error = response.result.error {
                    completionHandler(.failure(error))
                    return
                }
                self.request = nil
                let gamesWrapperResult = GameField.gamesArrayFromResponse(response)
                completionHandler(gamesWrapperResult)
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
                    self.updateGameDetailsFromJson(json: jsonResults)
                    completionHandler(.success(BackendError.objectSerialization(reason: "success")))
                } else {
                    completionHandler(.failure(BackendError.objectSerialization(reason: "could not find game")))
                }
        }
    }
    
    class func getGames(withQuery query:String, _ completionHandler: @escaping (Result<SearchResults>) -> Void) {
        let queryUrl = SearchResults.endpointForSearch() + "&query=%22" + query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "%22&resources=game"
        getGames(atPath:queryUrl, completionHandler)
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
            let queryUrl = SearchResults.endpointForSearch() + "&query=%22" + query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "%22&resources=game&page=\(pageNum)"
            getGames(atPath:queryUrl, completionHandler)
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
        return newGameField
    }
    
    class func cancelCurrentRequest() {
        self.request?.cancel()
    }
    
    override func add() {
        // Update contained objects
        for platform in self.platforms {
            platform.update {
                platform.linkCount += 1
            }
            platform.add()
        }
        for developer in self.developers {
            developer.update {
                developer.linkCount += 1
            }
            developer.add()
        }
        for publisher in self.publishers {
            publisher.update {
                publisher.linkCount += 1
            }
            publisher.add()
        }
        for genre in self.genres {
            genre.update {
                genre.linkCount += 1
            }
            genre.add()
        }
        super.add()
    }
    
    override func delete() {
        for platform in self.platforms {
            platform.update {
                platform.linkCount -= 1
                if platform.linkCount <= 0 {
                    realm?.delete(platform)
                }
            }
        }
        for developer in self.developers {
            developer.update {
                developer.linkCount -= 1
                if developer.linkCount <= 0 {
                    realm?.delete(developer)
                }
            }
        }
        for publisher in self.publishers {
            publisher.update {
                publisher.linkCount -= 1
                if publisher.linkCount <= 0 {
                    realm?.delete(publisher)
                }
            }
        }
        for genre in self.genres {
            genre.update {
                genre.linkCount -= 1
                if genre.linkCount <= 0 {
                    realm?.delete(genre)
                }
            }
        }
        
        self.image?.delete()
        for image in self.images {
            image.delete()
        }
        super.delete()
    }
}

class Game: Object {
    private(set) dynamic var uuid = NSUUID().uuidString

    dynamic var gameFields: GameField? = nil
    dynamic var platform:   Platform?  = nil
    dynamic var inLibrary:  Bool       = false
    dynamic var nowPlaying: Bool       = false
    dynamic var favourite:  Bool       = false
    dynamic var rating:     Int        = 0
    dynamic var progress:   Int        = 0
    dynamic var finished:   Bool       = false
    dynamic var notes:      String?    = nil
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    func add(_ gameField: GameField?, _ platform: Platform?) {
        let realm = try? Realm()
        try! realm?.write {
            gameField?.linkCount += 1
            platform?.linkCount  += 1
            self.gameFields = gameField
            self.platform   = platform
            realm?.add(self, update: true)
            // these get reset to nil after adding, so we have to readd them.
            self.gameFields = gameField
            self.platform   = platform
        }
    }
    
    override func delete() {
        self.gameFields?.update {
            self.gameFields?.linkCount -= 1
        }
        if self.gameFields?.linkCount == 0 {
            self.gameFields?.delete()
        }
        self.platform?.update {
            self.platform?.linkCount -= 1
        }
        if self.platform?.linkCount == 0 {
            self.platform?.delete()
        }
        super.delete()
    }
}
