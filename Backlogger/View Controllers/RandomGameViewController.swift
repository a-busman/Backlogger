//
//  RandomGameViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/2/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

protocol RandomGameViewControllerDelegate {
    func selectedGame(_ game: Game?, vc: RandomGameViewController)
}

class RandomGameViewController: UIViewController {
    
    @IBOutlet weak var rerollBlurView: UIVisualEffectView?
    @IBOutlet weak var filterBlurView: UIVisualEffectView?

    let rootGameView = UIView()
    let gameView = NowPlayingGameViewController()
    let gameBlurView = UIVisualEffectView()
    var backgroundView: RandomGameBackgroundViewController?
    
    var filters: FiltersTableViewController.FiltersCriteria?
    var games: Results<Game>!
    
    var delegate: RandomGameViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.filters = FiltersTableViewController.getFilters()
        self.updateFilters()
        if self.games.count > 0 {
            self.gameView.game = self.getRandomGame()
            self.gameView.addDetails(withRefresh: false)
            self.gameBlurView.isHidden = true
        } else if self.filters!.isEmpty {
            self.showNoGamesAlert()
            self.gameBlurView.isHidden = false
        } else {
            self.showFilterAlert()
            self.gameBlurView.isHidden = false
            NSLog("Filters don't match any games")
        }
        self.updateBackgroundGames()
        self.gameView.view.translatesAutoresizingMaskIntoConstraints = false
        self.rootGameView.translatesAutoresizingMaskIntoConstraints = false
        self.gameBlurView.translatesAutoresizingMaskIntoConstraints = false
        self.rootGameView.addSubview(self.gameView.view)
        self.rootGameView.addSubview(self.gameBlurView)
        self.view.insertSubview(self.rootGameView, belowSubview: self.filterBlurView!)
        self.gameBlurView.effect = UIBlurEffect(style: .light)
        self.gameBlurView.layer.cornerRadius = 10.0
        self.gameBlurView.clipsToBounds = true

        // Do any additional setup after loading the view.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.rootGameView.bottomAnchor.constraint(equalTo: self.rerollBlurView!.topAnchor, constant: -10).isActive = true
        self.rootGameView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0).isActive = true
        self.rootGameView.heightAnchor.constraint(equalTo: self.rootGameView.widthAnchor, multiplier: 14/9).isActive = true
        self.rootGameView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
        self.rootGameView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30).isActive = true
        self.gameView.view.bottomAnchor.constraint(equalTo: self.rootGameView.bottomAnchor).isActive = true
        self.gameView.view.topAnchor.constraint(equalTo: self.rootGameView.topAnchor).isActive = true
        self.gameView.view.leadingAnchor.constraint(equalTo: self.rootGameView.leadingAnchor).isActive = true
        self.gameView.view.trailingAnchor.constraint(equalTo: self.rootGameView.trailingAnchor).isActive = true
        self.gameBlurView.bottomAnchor.constraint(equalTo: self.rootGameView.bottomAnchor, constant: -10).isActive = true
        self.gameBlurView.topAnchor.constraint(equalTo: self.rootGameView.topAnchor, constant: 10).isActive = true
        self.gameBlurView.leadingAnchor.constraint(equalTo: self.rootGameView.leadingAnchor, constant: 10).isActive = true
        self.gameBlurView.trailingAnchor.constraint(equalTo: self.rootGameView.trailingAnchor, constant: -10).isActive = true
        self.gameView.detailsPanRecognizer?.isEnabled = false
        self.gameView.hideTapRecognizer?.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let game = self.gameView.game {
            if game.progress == 0 && game.finished == false {
                self.gameView.gameDetailOverlayController.completionLabel?.text = "Not Started"
                self.gameView.gameDetailOverlayController.completionCheckImage?.image = UIImage(named: "check-empty")
            }
            self.gameView.gameDetailOverlayController.pullTabView?.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "random_filters" {
            if let navVc = segue.destination as? UINavigationController,
                let vc = navVc.topViewController as? FiltersTableViewController {
                vc.delegate = self
            }
        } else if segue.identifier == "embed_background" {
            self.backgroundView = segue.destination as? RandomGameBackgroundViewController
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            self.rerollTapped(UIGestureRecognizer())
        }
    }

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        self.delegate?.selectedGame(self.gameView.game, vc: self)
    }
    
    @IBAction func rerollTapped(_ sender: UIGestureRecognizer) {
        var generator: UIFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        (generator as! UIImpactFeedbackGenerator).impactOccurred()
        self.gameBlurView.alpha = 0.0
        self.gameBlurView.isHidden = false
        UIView.animate(withDuration: 0.25, animations: {
            self.gameBlurView.alpha = 1.0
            self.rootGameView.alpha = 0.0
            self.rootGameView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { _ in
            generator = UINotificationFeedbackGenerator()
            (generator as! UINotificationFeedbackGenerator).notificationOccurred(.success)
            if self.games.count > 0 {
                self.gameView.game = self.getRandomGame()
                self.gameView.addDetails(withRefresh: true)
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.gameBlurView.alpha = 0.0
                self.rootGameView.alpha = 1.0
                self.rootGameView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        })
    }

    func getRandomGame() -> Game? {
        if self.games.count > 0 {
            return self.games[Int.random(in: 0..<self.games.count)]
        }
        return nil
    }
    
    func updateFilters() {
        guard let filters = self.filters else { return }
        var predicates: [NSPredicate] = []
        
        if filters.complete != nil {
            if filters.complete! {
                predicates.append(NSPredicate(format: "finished = true"))
            } else {
                predicates.append(NSPredicate(format: "finished != true"))
            }
        }
        
        if filters.favorite != nil {
            if filters.favorite! {
                predicates.append(NSPredicate(format: "favourite = true"))
            } else {
                predicates.append(NSPredicate(format: "favourite != true"))
            }
        }
        
        if filters.progress != nil && filters.progressCriteria != nil {
            var compStr = ""
            if filters.progressCriteria == .less {
                compStr = "<"
            } else if filters.progressCriteria == .equal {
                compStr = "="
            } else if filters.progressCriteria == .greater {
                compStr = ">"
            }
            predicates.append(NSPredicate(format: "progress \(compStr) %i", filters.progress!))
        }
        
        if filters.rating != nil && filters.ratingCriteria != nil {
            var compStr = ""
            if filters.ratingCriteria == .less {
                compStr = "<"
            } else if filters.ratingCriteria == .equal {
                compStr = "="
            } else if filters.ratingCriteria == .greater {
                compStr = ">"
            }
            predicates.append(NSPredicate(format: "rating \(compStr) %i", filters.rating!))
        }
        
        if filters.platforms != nil {
            predicates.append(NSPredicate(format: "platform.idNumber IN %@", filters.platforms!))
        }
        
        if filters.genres != nil {
            predicates.append(NSPredicate(format: "ANY gameFields.genres.idNumber IN %@", filters.genres!))
        }
        
        let compoundPredicate: NSCompoundPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        autoreleasepool {
            if let realm = try? Realm() {
                if compoundPredicate.subpredicates.count > 0 {
                    self.games = realm.objects(Game.self).filter(compoundPredicate)
                } else {
                    self.games = realm.objects(Game.self)
                }
            }
        }
    }
    func showFilterAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "You have no games that match your filters!", preferredStyle: .alert)
        let repick = UIAlertAction(title: "Repick", style: .default, handler: { action in
            self.performSegue(withIdentifier: "random_filters", sender: self)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(repick)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showNoGamesAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "You have no games in your library!", preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .cancel, handler: { action in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(okay)
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateBackgroundGames() {
        autoreleasepool {
            if let realm = try? Realm() {
                if self.games != nil && self.games.count > 0 {
                    self.backgroundView?.games = realm.objects(GameField.self).filter("idNumber IN %@", Array(self.games).map{$0.gameFields?.idNumber})
                }
            }
        }
    }
}

extension RandomGameViewController: FiltersTableViewControllerDelegate {
    func didSelectFilters(_ criteria: FiltersTableViewController.FiltersCriteria?, vc: FiltersTableViewController) {
        vc.dismiss(animated: true, completion: nil)
        self.filters = criteria
        self.updateFilters()
        if self.games.count > 0 {
            self.gameView.game = self.getRandomGame()
            self.gameView.addDetails(withRefresh: true)
            if let game = self.gameView.game {
                if game.progress == 0 && game.finished == false {
                    self.gameView.gameDetailOverlayController.completionLabel?.text = "Not Started"
                    self.gameView.gameDetailOverlayController.completionCheckImage?.image = UIImage(named: "check-empty")
                }
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.gameBlurView.alpha = 0.0
            }, completion: { _ in
                self.gameBlurView.isHidden = true
            })
        } else {
            self.gameBlurView.alpha = 0.0
            self.gameBlurView.isHidden = false
            UIView.animate(withDuration: 0.25, animations: {
                self.gameBlurView.alpha = 1.0
            })
            self.showFilterAlert()
            NSLog("Filters don't match any games")
        }
        self.updateBackgroundGames()
    }
    
    func didDismiss() {
        NSLog("dismiss")
    }
}
