//
//  Steam.swift
//  Backlogger
//
//  Created by Alex Busman on 6/22/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import Alamofire
import FirebaseAnalytics

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

// Steam : GB
fileprivate let gameMappings: [Int: Int] = [
    3300:22608,     // Bejeweled 2 Deluxe
    228200:18930,   // Company of heroes
    4560:18930,     // Company of heroes - Legacy Edition
    21090:4800,     // F.E.A.R.
    423230:52304,   // Furi
    797410:68769,   // Headsnatchers
    207080:-1,      // Indie Game: The Movie
    3320:19696,     // Insaniquarium! Deluxe
    205950:20096,   // Jet Set/Grind Radio
    912290:44021,   // Miscreated: Experimental Server
    491950:56603,   // Orwell
    3480:21963,     // Peggle Deluxe
    104600:-1,      // Portal 2 - The Final Hours
    204340:5036,    // Serious Sam 2
    564310:-1,      // Serious Sam: Fusion 2017
    314790:44717,   // Silence
    13250:17646,    // Unreal Gold
    3330:17012      // Zuma Deluxe
]

class Steam {
    
    static var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    static let steamPlatformIdNumber = Platform.customIdBase() - 1
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
    
    class func matchGameFromList(_ steamGame: SteamGame, _ completionHandler: @escaping (GameField?) -> Void) {
        guard let mappedId = gameMappings[steamGame.appId] else { completionHandler(nil); return }
        if mappedId == -1 {
            let gameField = GameField()
            gameField.idNumber = -1
            completionHandler(gameField)
        } else {
            GameField.getGameDetail(withId: mappedId) { result in
                if let error = result.error {
                    NSLog(error.localizedDescription)
                }
                completionHandler(result.value)
            }
        }
    }
    
    class func matchGiantBombGames(with gameList: [SteamGame], progressHandler: @escaping (Int, Int) -> Void, _ completionHandler: @escaping (_ matched: Result<[GameField]>, _ unmatched: Result<[SteamGame]>) -> Void) {
        var gameFields: [GameField] = []
        var unmatchedSteamGames: [SteamGame] = []
        var gameCount = 0
        var i = 0
        let totalGames = gameList.count
        let queue = DispatchQueue(label: "game.count.queue")
        
        let timerBlock: (Timer) -> Void = { timer in
            let currentGame = gameList[i]
                
            var gameName = currentGame.name.trimmingCharacters(in: .whitespacesAndNewlines).removeSpecialEdition()
            
            // for some reason, resident evil games have biohazard written after them (the japanese name)
            if gameName.lowercased().contains("biohazard") && gameName.lowercased().contains("resident") {
                
                let index = gameName.lowercased().index(gameName.lowercased().range(of: "biohazard")!.lowerBound, offsetBy: -2)
                gameName = String(gameName[gameName.startIndex..<index])
            }
            gameName = gameName.trimmingCharacters(in: .whitespacesAndNewlines)

            let resultsHandler = { (results: Result<SearchResults>) -> Void in
                if let error = results.error {
                    NSLog("Error searching for \(gameName)")
                    unmatchedSteamGames.append(currentGame)
                    queue.sync {
                        gameCount += 1
                        progressHandler(gameCount, totalGames)
                        if gameCount == totalGames {
                            completionHandler(.success(gameFields), .success(unmatchedSteamGames))
                        }
                    }
                    completionHandler(.failure(error), .failure(error))
                } else {
                    let searchResults = results.value!
                    var gameField: GameField?
                    var pcGameResults: [GameField] = []
                    let gameNameComponents = gameName.lowercased().components(separatedBy: " ")
                    
                    // Find games with PC as platform
                    for game in searchResults.results as! [GameField] {
                        for platform in game.platforms {
                            if platform.idNumber == 94 {
                                var amountOfComponentsIncluded = 0
                                var versionNumberMatches = true
                                var versionInSteam = false
                                var versionInGB = false
                                
                                let gbNameComponents = game.name!.lowercased().components(separatedBy: " ")
                                // make sure at least 1 word is in the game
                                for component in gameNameComponents {
                                    var strippedComponent = component
                                    if component.last == ":" {
                                        strippedComponent = component[0..<component.count - 1]
                                    }
                                    if game.name!.lowercased().contains(strippedComponent) {
                                        amountOfComponentsIncluded += 1
                                    }
                                    let version = Int(strippedComponent)
                                    if version != nil {
                                        versionInSteam = true
                                        if !game.name!.lowercased().contains(strippedComponent) && !game.name!.lowercased().contains(Util.toRoman(number: version!).lowercased()) {
                                            versionNumberMatches = false
                                        }
                                    }
                                }
                                
                                for component in gbNameComponents {
                                    var strippedComponent = component
                                    if component.last == ":" {
                                        strippedComponent = component[0..<component.count - 1]
                                    }
                                    if let _ = Int(strippedComponent) {
                                        versionInGB = true
                                    }
                                }
                                
                                if amountOfComponentsIncluded > 0 && versionNumberMatches && versionInSteam == versionInGB {
                                    pcGameResults.append(game)
                                }
                            }
                        }
                    }
                    var matches: [Int: [GameField]] = [:]
                    // Determine distances of each game to search request
                    for game in pcGameResults {
                        if game.name!.lowercased() == gameName.lowercased() {
                            if matches[0] == nil {
                                matches[0] = []
                            }
                            matches[0]?.append(game)
                            continue
                        }
                        let newDistance = game.name!.lowercased().distance(between: gameName.lowercased())
                        if matches[newDistance] == nil {
                            matches[newDistance] = []
                        }
                        matches[newDistance]?.append(game)
                    }
                    var lowestDistance = 999
                    // Find lowest distance matches
                    for (distance, _) in matches {
                        if distance < lowestDistance {
                            lowestDistance = distance
                        }
                    }
                    var latestReleaseYear = 0
                    if lowestDistance != 999 {
                        if matches[lowestDistance]!.count > 0 {
                            gameField = matches[lowestDistance]?.first
                        }
                        // Find most recent release year
                        for game in matches[lowestDistance]! {
                            var gameYear = 0
                            
                            if let releaseDate = game.releaseDate {
                                if releaseDate.count >= 4 {
                                    let releaseYear = releaseDate[0..<4]
                                    gameYear = Int(releaseYear)!
                                }
                            }
                            if gameYear > latestReleaseYear {
                                latestReleaseYear = gameYear
                                gameField = game
                            }
                        }
                    }
                    if gameField != nil {
                        gameFields.append(gameField!)
                        gameField!.steamAppId = currentGame.appId
                        NSLog("\(currentGame.name) -> \(gameField!.name!)")
                        Analytics.logEvent(AnalyticsEventSearch, parameters: [ "translation" : "\(currentGame.name.prefix(40)):\(currentGame.appId) -> \(gameField!.name!.prefix(40)):\(gameField!.idNumber)"])
                    } else {
                        unmatchedSteamGames.append(currentGame)
                        NSLog("Could not find match for \(currentGame.name.prefix(60)):\(currentGame.appId)")
                        Analytics.logEvent(AnalyticsEventSearch, parameters: ["no_match" : currentGame.name])
                        
                    }
                    queue.sync {
                        gameCount += 1
                        progressHandler(gameCount, totalGames)
                        if gameCount == totalGames {
                            completionHandler(.success(gameFields), .success(unmatchedSteamGames))
                        }
                    }
                }
            }
            matchGameFromList(currentGame) { gameResult in
                guard let game = gameResult else { GameField.getGames(from: gameName, resultsHandler); return }
                if game.idNumber != -1 {
                    game.steamAppId = currentGame.appId
                    gameFields.append(game)
                } else {
                    unmatchedSteamGames.append(currentGame)
                }
                queue.sync {
                    gameCount += 1
                    progressHandler(gameCount, totalGames)
                    if gameCount == totalGames {
                        completionHandler(.success(gameFields), .success(unmatchedSteamGames))
                    }
                }
            }
            i += 1
            if i >= totalGames {
                timer.invalidate()
                endBackgroundTask()
            }
        }
        registerBackgroundTask()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: timerBlock)
    }
    
    class func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            endBackgroundTask()
        }
    }
    
    class func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
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
