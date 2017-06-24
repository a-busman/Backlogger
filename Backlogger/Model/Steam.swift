//
//  Steam.swift
//  Backlogger
//
//  Created by Alex Busman on 6/22/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import Alamofire

var STEAM_API_KEY: String {
    var keys: NSDictionary!
    if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
        keys = NSDictionary(contentsOfFile: path)
    }
    if let dict = keys {
        let key = dict["SteamWebApiKey"] as! String
        return key
    } else {
        return ""
    }
}

enum SteamResponseFields: String {
    case Success  = "success"
    case Data     = "data"
    case Response = "response"
}

enum SteamFields: String {
    case Name         = "name"
    case `Type`       = "type"
    case HeaderImage  = "header_image"
    case AppId        = "appid"
    case SteamAppId   = "steam_appid"
    case AboutTheGame = "about_the_game"
    case Developers   = "developers"
    case Publishers   = "publishers"
    case Platforms    = "platforms"
    case Genres       = "genres"
    case Screenshots  = "screenshots"
    case ReleaseDate  = "release_date"
    case ImageIconUrl = "image_icon_url"
    case ImageLogoUrl = "image_logo_url"
    case Players      = "players"
}

enum SteamUserFields: String {
    case SteamId     = "steamid"
    case PersonaName = "personaname"
}

enum SteamUserGamesFields: String {
    case GameCount = "game_count"
    case Games     = "games"
}

class SteamGame {
    var appId:   Int = 0
    var name:    String = ""
    var desc:    String = ""
    var iconUrl: String = ""
    var logoUrl: String = ""
}

class SteamGameResults {
    var games: [SteamGame] = []
    var gameCount: Int = 0
}

class Steam {
    class func generateUserSummaryUrl(with steamId: String) -> URL? {
        return URL(string: "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=" + STEAM_API_KEY + "&steamids=" + steamId)
    }
    
    class func generateUserUrl(with username: String) -> URL? {
        return URL(string: "https://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=" + STEAM_API_KEY + "&vanityurl=" + username)
    }
    
    class func generateUserGameListUrl(with steamId: String) -> URL? {
        return URL(string: "https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=" + STEAM_API_KEY + "&steamid=" + steamId + "&format=json&include_appinfo=1")
    }
    
    class func generateImageUrl(with image: String, appId: Int) -> URL? {
        return URL(string: "https://media.steampowered.com/steamcommunity/public/images/apps/\(appId)/" + image + ".jpg")
    }
    
    class func username(from response: DataResponse<Any>) -> Result<String> {
        guard response.result.error == nil else {
            NSLog("\(response.result.error!)")
            return .failure(response.result.error!)
        }
        
        guard let json = response.result.value as? [String: Any] else {
            NSLog("didn't get user object as JSON from API")
            return .failure(BackendError.objectSerialization(reason:
                "Did not get JSON dictionary in response"))
        }
        
        guard let resp = json[SteamResponseFields.Response.rawValue] as? [String: Any] else {
            NSLog("Could not convert response to JSON")
            return .failure(BackendError.objectSerialization(reason: "Could not convert response to JSON"))
        }
        
        guard let players = resp[SteamFields.Players.rawValue] as? [[String: Any]] else {
            NSLog("Could not convert players to JSON")
            return .failure(BackendError.objectSerialization(reason: "Could not convert players to JSON"))
        }
        
        guard let player = players.first else {
            NSLog("Could not get first player")
            return .failure(BackendError.objectSerialization(reason: "Could not get first player"))
        }
        
        if let username = player[SteamUserFields.PersonaName.rawValue] as? String {
            return .success(username)
        } else {
            NSLog("Could not get persona name")
            return .failure(BackendError.objectSerialization(reason: "Could not get persona name"))
        }
    }
    
    class func steamId(from response: DataResponse<Any>) -> Result<String> {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            NSLog("\(response.result.error!)")
            return .failure(response.result.error!)
        }
        guard let json = response.result.value as? [String: Any] else {
            NSLog("didn't get user object as JSON from API")
            return .failure(BackendError.objectSerialization(reason:
                "Did not get JSON dictionary in response"))
        }
        
        guard let resp = json[SteamResponseFields.Response.rawValue] as? [String: Any] else {
            NSLog("Could not convert response to JSON")
            return .failure(BackendError.objectSerialization(reason: "Could not convert response to JSON"))
        }
        
        if let steamId = resp[SteamUserFields.SteamId.rawValue] as? String {
            return .success(steamId)
        } else {
            NSLog("Could not convert steamid to string")
            return .failure(BackendError.objectSerialization(reason: "Could not convert steamid to string"))
        }
    }
    
    class func gameResults(from response: DataResponse<Any>) -> Result<[SteamGame]> {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            NSLog("\(response.result.error!)")
            return .failure(response.result.error!)
        }
        guard let json = response.result.value as? [String: Any] else {
            NSLog("didn't get user object as JSON from API")
            return .failure(BackendError.objectSerialization(reason:
                "Did not get JSON dictionary in response"))
        }
        
        guard let resp = json[SteamResponseFields.Response.rawValue] as? [String: Any] else {
            NSLog("Could not convert response to JSON")
            return .failure(BackendError.objectSerialization(reason: "Could not convert response to JSON"))
        }
        
        let steamResults = SteamGameResults()
        
        guard let gameCount = resp[SteamUserGamesFields.GameCount.rawValue] as? Int else {
            NSLog("Could not convert game_count to int")
            return .failure(BackendError.objectSerialization(reason: "Could not convert game_count to int"))
        }
        steamResults.gameCount = gameCount
        
        var allGames: [SteamGame] = []
        
        if gameCount == 0 {
            return .success(allGames)
        }
        
        guard let games = resp[SteamUserGamesFields.Games.rawValue] as? [[String: Any]] else {
            NSLog("Could not convert games to [[String: Any]]")
            return .failure(BackendError.objectSerialization(reason: "Could not convert games to [[String: Any]]"))
        }
        
        for game in games {
            let newGame = SteamGame()
            newGame.appId = game[SteamFields.AppId.rawValue] as? Int ?? 0
            newGame.name = Util.removeSpecialCharsFromString(text: (game[SteamFields.Name.rawValue] as? String ?? ""))
            newGame.iconUrl = game[SteamFields.ImageIconUrl.rawValue] as? String ?? ""
            newGame.logoUrl = game[SteamFields.ImageLogoUrl.rawValue] as? String ?? ""
            allGames.append(newGame)
        }
        return .success(allGames)
    }
    
    class func getUserName(with steamId: String, _ completionHandler: @escaping (Result<String>) -> Void) {
        guard let url = generateUserSummaryUrl(with: steamId) else {
            completionHandler(.failure(BackendError.urlError(reason: "Could not convert steamId to url")))
            return
        }

        //UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let _ = Alamofire.request(url)
            .responseJSON { response in
                //UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let error = response.result.error {
                    completionHandler(.failure(error))
                    return
                }
                let username = Steam.username(from: response)
                completionHandler(username)
        }
    }
    
    class func getUserId(with username: String, _ completionHandler: @escaping (Result<String>) -> Void) {
        guard let url = generateUserUrl(with: username) else {
            completionHandler(.failure(BackendError.urlError(reason: "Could not convert username to url")))
            return
        }
        //UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let _ = Alamofire.request(url)
            .responseJSON { response in
                //UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let error = response.result.error {
                    completionHandler(.failure(error))
                    return
                }
                let steamId = Steam.steamId(from: response)
                completionHandler(steamId)
        }
    }
    
    class func getUserGameList(with steamId: String, _ completionHandler: @escaping(Result<[SteamGame]>) -> Void) {
        guard let url = generateUserGameListUrl(with: steamId) else {
            completionHandler(.failure(BackendError.urlError(reason: "Could not convert username to url")))
            return
        }

        //UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let _ = Alamofire.request(url)
            .responseJSON { response in
                //UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let error = response.result.error {
                    completionHandler(.failure(error))
                    return
                }
                let results = Steam.gameResults(from: response)
                completionHandler(results)
        }
    }
}
