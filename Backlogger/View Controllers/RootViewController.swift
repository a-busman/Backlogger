//
//  RootViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift
import WatchConnectivity

class RootViewController: UITabBarController {
    private let progressBar = UIProgressView()
    private var bottomAnchor = NSLayoutConstraint()
    
    private var _progress: Int = 0
    
    private let MINIMIZED_SIZE: CGFloat = 5
    
    var progress: Int {
        get {
            return self._progress
        }
        set(newValue) {
            if newValue >= 0 && newValue <= 100 {
                self._progress = newValue
                self.progressBar.setProgress(Float(newValue) / 100.0, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let session = WCSession.default
        session.delegate = self
        session.activate()
        self.progressBar.progressTintColor = UIColor(named: "App-blue")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.insertSubview(self.progressBar, belowSubview: self.tabBar)
        self.progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.bottomAnchor = self.progressBar.bottomAnchor.constraint(equalTo: self.tabBar.topAnchor)
        self.bottomAnchor.isActive = true
        self.progressBar.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.progressBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.progressBar.heightAnchor.constraint(equalToConstant: 4.0).isActive = true
        self.bottomAnchor.constant = self.MINIMIZED_SIZE
        if WCSession.default.isReachable {
            if let gamesToSend = self.getGamesForWatch() {
                WCSession.default.sendMessage(["gameList" : gamesToSend], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    func getGamesForWatch() -> [[String : Any]]? {
        if let realm = try? Realm() {
            let nowPlayingPlaylist = realm.objects(Playlist.self).filter("isNowPlaying = true")
            if nowPlayingPlaylist.count != 0 {
                let games = nowPlayingPlaylist[0].games
                var gamesToSend: [[String: Any]] = []
                
                for game in games {
                    var gameToSend: [String: Any] = [:]
                    gameToSend["name"] = game.gameFields?.name
                    gameToSend["progress"] = game.progress
                    gameToSend["rating"] = game.rating
                    gameToSend["complete"] = game.finished
                    gameToSend["image"] = game.gameFields?.image?.iconUrl
                    gameToSend["favorite"] = game.favourite
                    gameToSend["id"] = game.uuid
                    gamesToSend.append(gameToSend)
                }
                return gamesToSend
            }
        }
        return nil
    }
    
    func steamLoaderVisibility(_ visibile: Bool) {
        if visibile {
            self.bottomAnchor.constant = 0
        } else {
            self.bottomAnchor.constant = self.MINIMIZED_SIZE
        }
        UIView.animate(withDuration: 1.0, animations: {
            self.view.layoutSubviews()
        }, completion: { _ in
            if !visibile {
                self.progress = 0
            }
        })
    }
}

extension RootViewController: WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message.count == 1 {
            if message["randomGame"] != nil {
                replyHandler(["randomGame" : Game()])
            } else if message["updateList"] != nil {
                if let gamesToSend = self.getGamesForWatch() {
                    replyHandler(["gameList" : gamesToSend])
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if message["updateGame"] != nil {
            if let dictGame = message["updateGame"] as? [String : Any] {
                let game = WatchGame(dict: dictGame)
                autoreleasepool {
                    if let realm = try? Realm() {
                        let realmGame = realm.object(ofType: Game.self, forPrimaryKey: game.id)
                        realmGame?.update {
                            realmGame?.progress = game.progress
                            realmGame?.favourite = game.favorite
                            realmGame?.finished = game.complete
                            realmGame?.rating = game.rating
                        }
                    }
                }
                // Will be accessed from background thread, so we need to make sure UI updates happen on the main thread
                DispatchQueue.main.async {
                    for vc in self.viewControllers! {
                        if let navVc = vc as? UINavigationController, let npVc = navVc.viewControllers.first as? NowPlayingViewController {
                            npVc.refreshAll()
                            NSLog("Refreshing VCs")
                            break
                        }
                    }
                }
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            NSLog("\(error!.localizedDescription)")
        } else if activationState == .activated {
            NSLog("iOS app activated WatchConnectivity")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {

    }

    func sessionDidDeactivate(_ session: WCSession) {

    }
}
