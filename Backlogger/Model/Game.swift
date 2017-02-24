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

class Game: Field {
    var description:     String?
    var percentComplete: String?
    var platform:        String?
    var releaseDate:     String?
    var expectedDate:    Int?
    var imageUrl:        String?
    var image:           ImageList?
    var images:          [ImageList]?
    var developers:      [Company]?
    var genres:          [Genre]?
    var publishers:      [Publisher]?
    var platforms:       [Platform]?
    
    static var request:   DataRequest?
    
    required init(json: [String: Any]) {
        self.description  = json[GameFields.Deck.rawValue]                as? String ?? ""
        self.platforms    = json[GameFields.Platforms.rawValue]           as? [Platform]
        self.releaseDate  = json[GameFields.OriginalReleaseDate.rawValue] as? String ?? ""
        self.expectedDate = json[GameFields.ExpectedReleaseYear.rawValue] as? Int ?? 0
        self.platforms    = []
        self.developers   = []
        self.publishers   = []
        self.genres       = []
        self.images       = []
        if let jsonPlatforms = json[GameFields.Platforms.rawValue] as? [[String: Any]] {
            for jsonPlatform in jsonPlatforms {
                let platform = Platform(json: jsonPlatform)
                self.platforms?.append(platform)
            }
        }
        if let jsonDevelopers = json[GameFields.Developers.rawValue] as? [[String: Any]] {
            for jsonDeveloper in jsonDevelopers {
                let developer = Company(json: jsonDeveloper)
                self.developers?.append(developer)
            }
        }
        if let jsonPublishers = json[GameFields.Publishers.rawValue] as? [[String: Any]] {
            for jsonPublisher in jsonPublishers {
                let publisher = Publisher(json: jsonPublisher)
                self.publishers?.append(publisher)
            }
        }
        if let jsonGenres = json[GameFields.Genres.rawValue] as? [[String: Any]] {
            for jsonGenre in jsonGenres {
                let genre = Genre(json: jsonGenre)
                self.genres?.append(genre)
            }
        }
        if let image = json[GameFields.Image.rawValue] as? [String: Any] {
            self.image    = ImageList(json: image)
            self.imageUrl = self.image?.iconUrl
        }
        if let jsonImages = json[GameFields.Images.rawValue] as? [[String: Any]] {
            for jsonImage in jsonImages {
                let image = ImageList(json: jsonImage)
                self.images?.append(image)
            }
        }
        super.init(json: json)
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
        
        var allGames: [Game] = []
        if let results = json["results"] as? [[String: Any]] {
            for jsonGame in results {
                let game = Game(json: jsonGame)
                allGames.append(game)
            }
        }
        results.results = allGames
        return .success(results)
    }
    
    private class func gameFromResponse(_ response: DataResponse<Any>) -> Result<Game> {
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
        var game: Game?
        if let jsonResults = json["results"] as? [String: Any] {
            game = Game(json: jsonResults)
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
                let gamesWrapperResult = Game.gamesArrayFromResponse(response)
                completionHandler(gamesWrapperResult)
        }
    }
    
    class func buildDetailUrl(fromId id: Int) -> String {
        let url = Game.endpointForGame() + String(id) + "/"
        return url
    }
    
    class func getGameDetail(withUrl detailUrl: String?, _ completionHandler: @escaping (Result<Game>) -> Void) {
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
                let gameResult = Game.gameFromResponse(response)
                if let error = gameResult.error {
                    completionHandler(.failure(error))
                    return
                } else {
                    completionHandler(.success(gameResult.value!))
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
    
    class func cancelCurrentRequest() {
        self.request?.cancel()
    }
}
