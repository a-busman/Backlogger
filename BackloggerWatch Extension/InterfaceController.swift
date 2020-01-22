//
//  InterfaceController.swift
//  BackloggerWatch Extension
//
//  Created by Alex Busman on 1/19/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import WatchKit
import Foundation
import Kingfisher
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    private var games: [WatchGame] = []
    private var pickerItems: [WKPickerItem] = []
    private var currentItem: Int = 0
    private var isDisplaying: Bool = true
    private var pickerIsFocused: Bool = true
    @IBOutlet weak var picker: WKInterfacePicker?
    @IBOutlet weak var gameLabel: WKInterfaceLabel?
    @IBOutlet weak var backgroundLabel: WKInterfaceLabel?
    @IBOutlet weak var backgroundGroup: WKInterfaceGroup?
    @IBOutlet weak var gamesGroup: WKInterfaceGroup?
    
    private let noIphoneText = "Please open Backlogger on your iPhone."
    private let noGamesText  = "Add some games to your Now Playing screen on your iPhone!"
        
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let gamesFromStorage = UserDefaults.standard.array(forKey: "gameList")
        if gamesFromStorage == nil {
            self.gamesGroup?.setHidden(true)
            self.backgroundGroup?.setHidden(false)
            self.backgroundLabel?.setText(self.noIphoneText)
        } else {
            for game in gamesFromStorage! {
                if let dictGame = game as? [String : Any] {
                    let watchGame = WatchGame(dict: dictGame)
                    games.append(watchGame)
                }
            }
            
            if gamesFromStorage!.count == 0 {
                self.gamesGroup?.setHidden(true)
                self.backgroundGroup?.setHidden(false)
                self.backgroundLabel?.setText(self.noGamesText)
            } else {
                self.gamesGroup?.setHidden(false)
                self.backgroundGroup?.setHidden(true)
                self.updatePicker()
                self.picker?.setItems(self.pickerItems)
                self.gameLabel?.setText(self.games[0].name)
            }

        }
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        let session = WCSession.default
        session.delegate = self
        session.activate()
        self.updateList()
        self.picker?.focus()

    }
    
    override func didAppear() {
        super.didAppear()
        self.isDisplaying = true
        if !self.pickerIsFocused {
            self.picker?.focus()
        }
    }
    
    override func pickerDidFocus(_ picker: WKInterfacePicker) {
        self.pickerIsFocused = true
    }
    
    override func pickerDidResignFocus(_ picker: WKInterfacePicker) {
        self.pickerIsFocused = false
        if self.isDisplaying {
            picker.focus()
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func pickerDidChange(value: Int) {
        self.currentItem = value
        self.gameLabel?.setText(self.games[value].name ?? "")
    }
    
    func updatePicker() {
        self.pickerItems = []
        let currentItem = self.currentItem
        for game in self.games {
            let pickerItem = WKPickerItem()
            pickerItem.contentImage = WKImage(imageName: "info_image_placeholder")
            pickerItem.title = game.name
            self.pickerItems.append(pickerItem)
            if let url = URL(string: game.image ?? "") {
                let processor = RoundCornerImageProcessor(cornerRadius: 10)
                KingfisherManager.shared.retrieveImage(with: url, options: [.processor(processor)], progressBlock: nil, downloadTaskUpdated: nil) { result in
                    switch result {
                    case .success(let value):
                        pickerItem.contentImage = WKImage(image: value.image)
                        self.picker?.setItems(self.pickerItems)
                        self.picker?.setSelectedItemIndex(currentItem)
                    case .failure(let error):
                        NSLog(error.localizedDescription)
                    }
                }
            }
        }
        self.gameLabel?.setText(self.games[currentItem].name)
        self.picker?.focus()
    }

    func update(games gameList: [[String : Any]]) {
        UserDefaults.standard.set(gameList, forKey: "gameList")
        var watchGameList: [WatchGame] = []
        for game in gameList {
            let watchGame = WatchGame(dict: game)
            watchGameList.append(watchGame)
        }
        self.games = watchGameList
        for game in watchGameList {
            NSLog("Watch got game: \(game.name)")
        }
        if gameList.count == 0 {
            self.gamesGroup?.setHidden(true)
            self.backgroundGroup?.setHidden(false)
            self.backgroundLabel?.setText(self.noGamesText)
        } else {
            self.gamesGroup?.setHidden(false)
            self.backgroundGroup?.setHidden(true)
            self.updatePicker()
        }
    }
    
    @IBAction func gameTapped() {
        self.isDisplaying = false
        var context: [String : Any] = [:]
        context["game"] = self.games[currentItem]
        context["delegate"] = self
        pushController(withName: "game_interface", context: context)
    }
}

extension InterfaceController: GameInterfaceDelegate {
    func didChange(game: WatchGame) {
        self.games[currentItem] = game
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(["updateGame" : game.dict], replyHandler: nil, errorHandler: nil)
        }
        var dictGames: [[String : Any]] = []
        for game in self.games {
            dictGames.append(game.dict)
        }
        UserDefaults.standard.set(dictGames, forKey: "gameList")
    }
}

extension InterfaceController: WCSessionDelegate {
    func updateList() {
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(["updateList" : 0], replyHandler: { reply in
                if let gameList = reply["gameList"] as? [[String : Any]] {
                    self.update(games: gameList)
                }
            }, errorHandler: { error in
                NSLog(error.localizedDescription)
            })
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let gameList = message["gameList"] as? [[String : Any]] {
            self.update(games: gameList)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            self.updateList()
        } else if error != nil {
            NSLog(error!.localizedDescription)
        }
    }
}
