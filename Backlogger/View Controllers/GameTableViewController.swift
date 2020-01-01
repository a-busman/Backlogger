//
//  GameTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift
import Zephyr

class GameTableViewController: UIViewController {
    
    @IBOutlet weak var tableView:         UITableView?
    @IBOutlet weak var headerView:        UIView?
    @IBOutlet weak var platformImage:     UIImageView?
    @IBOutlet weak var titleLabel:        UILabel?
    @IBOutlet weak var shadowView:        UIView?
    @IBOutlet weak var loadingView:       UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var progressLabel:     UILabel?
    @IBOutlet weak var progressBar:       UIProgressView?
    
    @IBOutlet weak var shadowBottomLayoutConstraint:  NSLayoutConstraint?
    @IBOutlet weak var titleBottomLayoutConstraint:   NSLayoutConstraint?
    @IBOutlet weak var backgroundTopLayoutConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageTopLayoutConstraint:      NSLayoutConstraint?
    @IBOutlet weak var imageHeightLayoutConstraint:   NSLayoutConstraint?
    
    let shadowGradientLayer = CAGradientLayer()
    
    var games: LinkingObjects<Game>?
    var filteredGames: Results<Game>?
    
    var platform: Platform?
    var platformId: Int?
    
    var toastOverlay = ToastOverlayViewController()
    
    var steamVc: UINavigationController?
    
    var currentScrollPosition: CGFloat = 100.0

    fileprivate var didLayout = false
    
    fileprivate let titleBottomInitial:   CGFloat = -10.0
    fileprivate let shadowBottomInitial:  CGFloat = 0.0
    fileprivate let imageHeightInitial:   CGFloat = 165.0
    fileprivate let imageTopInitial:      CGFloat = 0.0
    fileprivate let backgroundTopInitial: CGFloat = 165.0
    
    fileprivate let headerMaxHeight:      CGFloat = 165.0
    fileprivate let headerMinHeight:      CGFloat = 80.0
    fileprivate let platformMaxMargin:    CGFloat = 20.0
    fileprivate let platformMinMargin:    CGFloat = 10.0
    fileprivate var startInset:           CGFloat = 0.0
    fileprivate var headerTravelDistance: CGFloat = 0.0
    
    fileprivate let tableReuseIdentifier = "table_cell"
    
    enum SortType: Int {
        case alphabetical = 0
        case dateAdded = 1
        case releaseYear = 2
        case percentComplete = 3
        case completed = 4
        case rating = 5
    }

    var hideComplete: Bool?
    var sortType: SortType?
    var ascending: Bool?
    var showWishlist: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.headerTravelDistance = self.headerMaxHeight - self.headerMinHeight
        if let platform = self.platform {
            self.platformId = platform.idNumber
            self.titleLabel?.text = platform.name
            self.games = platform.ownedGames
            if platform.name!.count < 10 {
                self.title = platform.name
            } else {
                self.title = platform.abbreviation
            }

            if !platform.hasDetails && !platform.custom {
                platform.updateDetails { results in
                    if let error = results.error {
                        NSLog("\(error.localizedDescription)")
                        self.platformImage?.image = #imageLiteral(resourceName: "now_playing_placeholder")
                    } else {
                        if let superUrl = platform.image?.superUrl {
                            self.platformImage?.kf.setImage(with: URL(string: superUrl), placeholder: #imageLiteral(resourceName: "now_playing_placeholder"), completionHandler: {
                                result in
                                switch result {
                                case .success(let value):
                                    if value.cacheType == .none {
                                        UIView.transition(with: self.platformImage!,
                                                          duration:0.5,
                                                          options: .transitionCrossDissolve,
                                                          animations: { self.platformImage?.image = value.image },
                                                          completion: nil)
                                    } else {
                                        self.platformImage?.image = value.image
                                    }
                                case .failure(let error):
                                    NSLog("Error \(error)")
                                }
                            })
                        } else {
                            self.platformImage?.image = #imageLiteral(resourceName: "now_playing_placeholder")
                        }
                    }
                }
            } else {
                if platform.idNumber != Steam.steamPlatformIdNumber {
                    if let superUrl = platform.image?.superUrl {
                        self.platformImage?.kf.setImage(with: URL(string: superUrl), placeholder: #imageLiteral(resourceName: "now_playing_placeholder"), completionHandler: {
                            result in
                            switch result {
                            case .success(let value):
                                if value.cacheType == .none {
                                    UIView.transition(with: self.platformImage!,
                                                      duration:0.5,
                                                      options: .transitionCrossDissolve,
                                                      animations: { self.platformImage?.image = value.image },
                                                      completion: nil)
                                } else {
                                    self.platformImage?.image = value.image
                                }
                            case .failure(let error):
                                NSLog("Error \(error)")
                            }
                        })
                    } else {
                        self.platformImage?.image = #imageLiteral(resourceName: "now_playing_placeholder")
                    }
                } else {
                    self.platformImage?.image = #imageLiteral(resourceName: "steam_logo_large")
                }
            }
        } else {
            NSLog("No platform during load")
        }
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: tableReuseIdentifier)
        
        self.tableView?.addInteraction(UIContextMenuInteraction(delegate: self))
        self.toastOverlay.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(toastOverlay.view)
        toastOverlay.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        toastOverlay.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        toastOverlay.view.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshCells()
    }
    
    func refreshCells() {
        if Util.isICloudContainerAvailable {
            Zephyr.sync()
        }

        self.hideComplete = UserDefaults.standard.value(forKey: "hideComplete") as? Bool
        if self.hideComplete == nil {
            self.hideComplete = false
            UserDefaults.standard.set(false, forKey: "hideComplete")
        }
        
        let sort = UserDefaults.standard.value(forKey: "librarySortType")
        if sort == nil {
            self.sortType = .dateAdded
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
        } else {
            if let value = sort as? Int {
                self.sortType = SortType.init(rawValue: value)
            } else {
                self.sortType = .dateAdded
                UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            }
        }
        self.ascending = UserDefaults.standard.value(forKey: "libraryAscending") as? Bool
        if self.ascending == nil {
            self.ascending = true
            UserDefaults.standard.set(self.ascending, forKey: "libraryAscending")
        }
        
        self.showWishlist = UserDefaults.standard.value(forKey: "libraryShowWishlist") as? Bool
        if self.showWishlist == nil {
            self.showWishlist = false
            UserDefaults.standard.set(false, forKey: "libraryShowWishlist")
        }
        autoreleasepool {
            let realm = try? Realm()
            self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId)
        }
        if self.platform == nil {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
        self.filterGames()
        
        if self.currentScrollPosition < 90.0 {
            let remainingWidth = self.currentScrollPosition
            let newColor = UIColor(white: 1.0, alpha: (25.0 - remainingWidth) / 25.0)
            self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: newColor])
        } else if self.currentScrollPosition < 65.0 {
            self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])
        } else {
            self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.clear])
        }
        if self.filteredGames!.count < 1 {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.startInset = (self.navigationController?.navigationBar.bounds.height ?? 0.0) + self.backgroundTopInitial + (self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0)
        if !self.didLayout {
            self.shadowGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: (self.shadowView?.frame.height)!)
            let darkColor = UIColor(white: 0.0, alpha: 0.3).cgColor
            self.shadowGradientLayer.colors = [UIColor.clear.cgColor, darkColor]
            self.shadowGradientLayer.locations = [0.7, 1.0]
            self.tableView?.contentInset.top = self.backgroundTopInitial
            self.tableView?.contentInset.bottom = 0.0
            self.tableView?.verticalScrollIndicatorInsets.top = self.backgroundTopInitial
            self.tableView?.verticalScrollIndicatorInsets.bottom = 0.0
            self.tableView?.setContentOffset(CGPoint(x: 0.0, y: -self.startInset), animated: false)
            self.shadowView?.layer.addSublayer(self.shadowGradientLayer)
        }
        self.didLayout = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "library_show_details" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameDetailsViewController
                
                vc.gameField = self.filteredGames![i].gameFields
                vc.game = self.filteredGames![i]
                vc.state = .inLibrary
            }
        }
    }
    
    @IBAction func moreTapped(sender: UIBarButtonItem) {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let addAction = self.platform!.idNumber != Steam.steamPlatformIdNumber ?
        UIAlertAction(title: "Add Games", style: .default, handler: self.addGames) :
        UIAlertAction(title: "Sync with Steam", style: .default, handler: self.syncWithSteam)
        let sortAction = UIAlertAction(title: "Sort...", style: .default, handler: self.sortTapped)
        let wishlistString: String = self.showWishlist! ? "Hide Wishlist Games" : "Show Wishlist Games"
        let completeString: String = self.hideComplete! ? "Show Finished" : "Hide Finished"
        let showWishlistAction = UIAlertAction(title: wishlistString, style: .default, handler: self.showWishlist)

        let hideCompleteAction = UIAlertAction(title: completeString, style: .default, handler: self.hideTapped)
        
        actions.addAction(addAction)
        actions.addAction(sortAction)
        actions.addAction(showWishlistAction)
        actions.addAction(hideCompleteAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actions.popoverPresentationController?.barButtonItem = self.navigationController?.navigationBar.topItem?.rightBarButtonItem
        self.present(actions, animated: true, completion: nil)
    }
    
    func hideTapped(sender: UIAlertAction) {
        self.hideComplete = !self.hideComplete!
        UserDefaults.standard.set(self.hideComplete, forKey: "hideComplete")
        self.filterGames()
    }
    
    func showWishlist(sender: UIAlertAction) {
        self.showWishlist = !self.showWishlist!
        UserDefaults.standard.set(self.showWishlist, forKey: "libraryShowWishlist")
        self.filterGames()
    }
    
    private func filterGames() {
        var sortString: String
        switch self.sortType! {
        case .alphabetical:
            sortString = "gameFields.name"
            break
        case .dateAdded:
            sortString = "dateAdded"
            break
        case .releaseYear:
            sortString = "gameFields.releaseDate"
            break
        case .percentComplete:
            sortString = "progress"
            break
        case .completed:
            sortString = "finished"
            break
        case .rating:
            sortString = "rating"
        }
        self.games = self.platform?.ownedGames
        self.filteredGames = self.games?.sorted(byKeyPath: sortString, ascending: self.ascending!)
        
        if self.hideComplete! {
            self.filteredGames = self.filteredGames?.filter("finished = false")
        }
        
        if !self.showWishlist! {
            self.filteredGames = self.filteredGames?.filter("inLibrary = true")
        }
        
        self.tableView?.reloadData()
    }
    
    func sortTapped(sender: UIAlertAction) {
        let actions = UIAlertController(title: "Sort games", message: nil, preferredStyle: .actionSheet)

        let alphaAction = UIAlertAction(title: "Title", style: .default, handler: { _ in
            self.ascending = self.sortType == .alphabetical ? !self.ascending! : true
            self.sortType = .alphabetical
            self.sortGames(by: "gameFields.name")
        })
        let dateAction = UIAlertAction(title: "Recently Added", style: .default, handler: { _ in
            self.ascending = self.sortType == .dateAdded ? !self.ascending! : false
            self.sortType = .dateAdded
            self.sortGames(by: "dateAdded")
        })
        let releaseAction = UIAlertAction(title: "Release Date", style: .default, handler: { _ in
            self.ascending = self.sortType == .releaseYear ? !self.ascending! : true
            self.sortType = .releaseYear
            self.sortGames(by: "gameFields.releaseDate")
        })
        let percentAction = UIAlertAction(title: "Progress", style: .default, handler: { _ in
            self.ascending = self.sortType == .percentComplete ? !self.ascending! : true
            self.sortType = .percentComplete
            self.sortGames(by: "progress")
        })
        let completeAction = UIAlertAction(title: "Finished", style: .default, handler: { _ in
            self.ascending = self.sortType == .completed ? !self.ascending! : true
            self.sortType = .completed
            self.sortGames(by: "finished")
        })
        let ratingAction = UIAlertAction(title: "Rating", style: .default, handler: { _ in
            self.ascending = self.sortType == .rating ? !self.ascending! : false
            self.sortType = .rating
            self.sortGames(by: "rating")
        })
        
        alphaAction.setValue(false, forKey: "checked")
        dateAction.setValue(false, forKey: "checked")
        releaseAction.setValue(false, forKey: "checked")
        percentAction.setValue(false, forKey: "checked")
        completeAction.setValue(false, forKey: "checked")
        ratingAction.setValue(false, forKey: "checked")
        
        switch self.sortType! {
        case .alphabetical:
            alphaAction.setValue(true, forKey: "checked")
            break
        case .dateAdded:
            dateAction.setValue(true, forKey: "checked")
            break
        case .releaseYear:
            releaseAction.setValue(true, forKey: "checked")
            break
        case .percentComplete:
            percentAction.setValue(true, forKey: "checked")
            break
        case .completed:
            completeAction.setValue(true, forKey: "checked")
            break
        case .rating:
            ratingAction.setValue(true, forKey: "checked")
        }
        actions.addAction(alphaAction)
        actions.addAction(dateAction)
        actions.addAction(releaseAction)
        actions.addAction(percentAction)
        actions.addAction(completeAction)
        actions.addAction(ratingAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actions.popoverPresentationController?.barButtonItem = self.navigationController?.navigationBar.topItem?.rightBarButtonItem
        self.present(actions, animated: true, completion: nil)
    }
    
    private func sortGames(by sortString: String) {
        if self.filteredGames != nil {
            self.filteredGames = self.filteredGames!.sorted(byKeyPath: sortString, ascending: self.ascending!)
        }
        UserDefaults.standard.set(self.ascending!, forKey: "libraryAscending")
        UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
        self.tableView?.reloadData()
    }
    
    func syncWithSteam(sender: UIAlertAction) {
        if Util.isICloudContainerAvailable {
            Zephyr.sync(keys: ["steamId"])
        }
        let steamId = UserDefaults.standard.value(forKey: "steamId") as! String
        Steam.getUserGameList(with: steamId) { results in
            if let listError = results.error {
                NSLog(listError.localizedDescription)
            } else {
                var newGames: [SteamGame] = []
                for game in results.value! {
                    autoreleasepool {
                        let realm = try! Realm()
                        if realm.objects(Game.self).filter(NSPredicate(format: "gameFields.steamAppId = %d and platform.idNumber = %d", game.appId, Steam.steamPlatformIdNumber)).count == 0 {
                            newGames.append(game)
                        }
                    }
                }
                Steam.matchGiantBombGames(with: newGames, progressHandler: { progress, total in
                    self.progressBar?.setProgress(Float(progress) / Float(total), animated: true)
                    self.progressLabel?.text = "\(progress) / \(total)"
                }) { matched, unmatched in
                    if let gamesError = matched.error {
                        NSLog(gamesError.localizedDescription)
                    } else {
                        NSLog("Done")
                        self.loadingView?.isHidden = true
                        self.activityIndicator?.stopAnimating()
                        self.view.isUserInteractionEnabled = true
                        if matched.value!.count > 0 {
                            //dedupe
                            var dedupedList: [GameField] = []
                            for game in matched.value! {
                                var inNewList = false
                                for newGame in dedupedList {
                                    if game.idNumber == newGame.idNumber {
                                        inNewList = true
                                        break
                                    }
                                }
                                autoreleasepool {
                                    let realm = try! Realm()
                                    if let dbGameField = realm.object(ofType: GameField.self, forPrimaryKey: game.idNumber) {
                                        for dbGame in dbGameField.ownedGames {
                                            if dbGame.fromSteam {
                                                inNewList = true
                                            }
                                        }
                                    }
                                }
                                if !inNewList {
                                    dedupedList.append(game)
                                }
                            }
                            let vc = self.storyboard!.instantiateViewController(withIdentifier: "add_from_steam") as! UINavigationController
                            let rootView = vc.viewControllers.first! as! AddSteamGamesViewController
                            vc.navigationBar.tintColor = .white
                            rootView.delegate = self
                            rootView.gameFields = dedupedList
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        self.tableView?.reloadData()
        self.steamVc?.dismiss(animated: true, completion: nil)
        self.activityIndicator?.startAnimating()
        self.progressBar?.setProgress(0.0, animated: false)
        self.progressLabel?.text = ""
        self.loadingView?.isHidden = false
        self.view.isUserInteractionEnabled = false
    }
    
    func tappedDone(sender: UIBarButtonItem) {
        self.steamVc?.dismiss(animated: true, completion: nil)
        self.refreshCells()
    }
    
    func addGames(sender: UIAlertAction) {
        let vc: LibraryAddSearchViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "add_game") as! LibraryAddSearchViewController
        let navVc = UINavigationController(rootViewController: vc)
        navVc.navigationBar.barStyle = .black
        navVc.navigationBar.isTranslucent = true
        navVc.navigationBar.barTintColor = Util.appColor
        vc.delegate = self
        self.present(navVc, animated: true, completion: nil)
    }
    
    func addToUpNext(games: [Game], later: Bool) {
        if later {
            autoreleasepool {
                let realm = try! Realm()
                let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
                if upNextPlaylist != nil {
                    var currentGames = Array(upNextPlaylist!.games)
                    currentGames.append(contentsOf: games)
                    upNextPlaylist!.update {
                        upNextPlaylist?.games.removeAll()
                        upNextPlaylist?.games.append(objectsIn: currentGames)
                    }
                }
            }
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_queue_large"), title: "Added to Queue", description: nil)
        } else {
            autoreleasepool {
                let realm = try! Realm()
                let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
                if upNextPlaylist != nil {
                    var currentGames = games
                    currentGames += upNextPlaylist!.games
                    upNextPlaylist!.update {
                        upNextPlaylist?.games.removeAll()
                        upNextPlaylist?.games.append(objectsIn: currentGames)
                    }
                }
            }
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "play_next_large"), title: "Added to Queue", description: "We'll play this one next.")
        }
    }
}

extension GameTableViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let indexPath = self.tableView?.indexPathForRow(at: location),
            let gameFields = self.filteredGames![indexPath.row].gameFields else { return nil }
        let game = self.filteredGames![indexPath.row]
        let vc: GameDetailsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "game_details") as! GameDetailsViewController
        var gameField: GameField!
        
        autoreleasepool {
            let realm = try? Realm()
            gameField = realm?.object(ofType: GameField.self, forPrimaryKey: gameFields.idNumber)
        }
        if gameField == nil {
            gameField = gameFields
        }
        
        vc.game = game
        vc.state = .inLibrary
        vc.gameField = gameField
        

        vc.addRemoveClosure = { (action) -> Void in
            let game = self.filteredGames![indexPath.row]
            if game.inLibrary {
                let platformId = self.platform!.idNumber
                game.delete()
                autoreleasepool {
                    let realm = try? Realm()
                    self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId)
                }
                if self.platform != nil {
                    self.games = self.platform?.ownedGames
                    self.tableView?.reloadData()
                } else {
                    let _ = self.navigationController?.popViewController(animated: true)
                }
            } else {
                game.update {
                    game.inLibrary = true
                    game.inWishlist = false
                }
            }
            self.tableView?.reloadData()
        }
        vc.addToPlayLaterClosure = { (action) -> Void in
            self.addToUpNext(games: [game], later: true)
        }
        vc.addToPlaylistClosure = { (action) -> Void in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistNavigation") as! UINavigationController
            let playlistVc = vc.viewControllers.first as! PlaylistViewController
            playlistVc.addingGames = [game]
            playlistVc.isAddingGames = true
            playlistVc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
        vc.addToPlayNextClosure = { (action) -> Void in
            self.addToUpNext(games: [game], later: false)
        }
        vc.addToWishlistClosure = { (action) -> Void in
            let game = self.filteredGames![indexPath.row]
            game.delete()
            autoreleasepool {
                let realm = try? Realm()
                self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: self.platform!.idNumber)
            }
            if self.platform != nil {
                self.games = self.platform?.ownedGames
                self.tableView?.reloadData()
            } else {
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {() -> UIViewController? in
            return vc
        }, actionProvider: { suggestedActions in
            return vc.contextMenu
        })
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.preferredCommitStyle = .pop
        guard let vc = animator.previewViewController else { return }
        
        animator.addCompletion {
            self.show(vc, sender: self)
        }
        
    }
}

extension GameTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredGames?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        cell.row = indexPath.row
        cell.accessoryType = .disclosureIndicator
        let game = self.filteredGames![indexPath.row]
        var indent: CGFloat = 0.0
        
        if indexPath.row < self.filteredGames!.count - 1 {
            indent = 58.0
        }
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = UIEdgeInsets.init(top: 0, left: indent, bottom: 0, right: 0)
        }
        if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
            cell.layoutMargins = .zero
        }
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.preservesSuperviewLayoutMargins = false
        }
        
        cell.addButtonHidden = true
        
        cell.titleLabel?.text = game.gameFields?.name
        if let releaseDate = game.gameFields?.releaseDate,
            releaseDate != "" {
            let year = releaseDate[..<releaseDate.index(releaseDate.startIndex, offsetBy: 4)]
            cell.descriptionLabel?.text = String(year)
            cell.showDetails()
        } else if let releaseDate = game.gameFields?.expectedDate, releaseDate > 0 {
            cell.descriptionLabel?.text = "\(releaseDate)"
            cell.showDetails()
        } else {
            cell.descriptionLabel?.text = ""
            cell.hideDetails()
        }
        cell.rightLabel?.text = ""
        cell.percentView?.isHidden = false
        cell.progress = game.progress
        cell.complete = game.finished
        cell.isWishlist = game.inWishlist
        if let image = game.gameFields?.image, !image.iconUrl!.hasSuffix("gblogo.png") {
            cell.imageUrl = URL(string: image.iconUrl!)
        } else {
            cell.artView?.image = #imageLiteral(resourceName: "table_placeholder_light")
        }
        cell.cacheCompletionHandler = {
            result in
            switch result {
            case .success(let value):
                if let cellUrl = cell.imageUrl {
                    if value.source.url == cellUrl {
                        if value.cacheType == .none || value.cacheType == .disk {
                            UIView.transition(with: cell.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                cell.set(image: value.image)
                            }, completion: nil)
                        } else {
                            cell.set(image: value.image)
                        }
                    }
                }
            case .failure(let error):
                NSLog("Error: \(error)")
            }
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            let game = self.filteredGames![indexPath.row]
            game.delete()
            autoreleasepool {
                let realm = try? Realm()
                self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: self.platformId)
            }
            if self.platform?.ownedGames.count ?? 0 > 0 {
                var sortString: String
                switch self.sortType! {
                case .alphabetical:
                    sortString = "gameFields.name"
                    break
                case .dateAdded:
                    sortString = "dateAdded"
                    break
                case .releaseYear:
                    sortString = "gameFields.releaseDate"
                    break
                case .percentComplete:
                    sortString = "progress"
                    break
                case .completed:
                    sortString = "finished"
                    break
                case .rating:
                    sortString = "rating"
                }
                self.games = self.platform?.ownedGames
                self.filteredGames = self.games?.sorted(byKeyPath: sortString, ascending: self.ascending!)
                
                if self.hideComplete! {
                    self.filteredGames = self.filteredGames?.filter("finished = false")
                }
                
                if !self.showWishlist! {
                    self.filteredGames = self.filteredGames?.filter("inLibrary = true")
                }
                
                self.tableView?.deleteRows(at: [indexPath], with: .automatic)
            } else {
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView?.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "library_show_details", sender: tableView.cellForRow(at: indexPath))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.didLayout {
            let offset = scrollView.contentOffset.y * -1.0
            self.titleBottomLayoutConstraint?.constant = offset - self.startInset + self.titleBottomInitial
            self.shadowBottomLayoutConstraint?.constant = offset - self.startInset
            self.backgroundTopLayoutConstraint?.constant = offset - self.startInset + self.backgroundTopInitial
            if offset > self.startInset {
                self.imageHeightLayoutConstraint?.constant = offset - self.startInset + self.imageHeightInitial
                self.imageTopLayoutConstraint?.constant = 0.0
            } else {
                self.imageTopLayoutConstraint?.constant = (offset - self.startInset) / 5.0
                self.imageHeightLayoutConstraint?.constant = self.imageHeightInitial
            }
            self.currentScrollPosition = offset
            self.tableView?.verticalScrollIndicatorInsets.top =  self.startInset - ((self.navigationController?.navigationBar.bounds.height ?? 0.0) + (self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0))
            
            let labelNavHeight = (self.titleLabel?.bounds.height ?? 0) + (self.navigationController?.navigationBar.bounds.height ?? 0)
            if offset < (labelNavHeight + (self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0)) {
                if offset < 0.0 {
                    self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])
                } else {
                    let remainingWidth = offset - ((self.navigationController?.navigationBar.bounds.height ?? 0) + (self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0))
                    let newColor = UIColor(white: 1.0, alpha: ((self.titleLabel?.bounds.height ?? 0) - remainingWidth) / (self.titleLabel?.bounds.height ?? 1))
                    self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: newColor])
                }
            } else {
                self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.clear])
                if offset > self.startInset {
                    self.tableView?.verticalScrollIndicatorInsets.top = offset - ((self.navigationController?.navigationBar.bounds.height ?? 0.0) + (self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0))
                }
            }
        }
    }
}

extension GameTableViewController: PlaylistViewControllerDelegate {
    func chosePlaylist(vc: PlaylistViewController, playlist: Playlist, games: [Game], isNew: Bool) {
        if !isNew {
            playlist.update {
                playlist.games.append(objectsIn: games)
            }
        }
        
        vc.presentingViewController?.dismiss(animated: true, completion: {
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_playlist_large"), title: "Added to Playlist", description: "Added to \"\(playlist.name!)\".")
        })
        vc.navigationController?.dismiss(animated: true, completion: nil)
        self.refreshCells()
    }
}

extension GameTableViewController: AddSteamGamesViewControllerDelegate {
    func didSelectSteamGames(vc: AddSteamGamesViewController, games: [GameField]) {
        defer {
            self.refreshCells()
        }
        if games.count > 0 {
            var steamPlatform: Platform?
            autoreleasepool {
                let realm = try! Realm()
                if let plat = realm.object(ofType: Platform.self, forPrimaryKey: Steam.steamPlatformIdNumber) {
                    steamPlatform = plat
                } else {
                    var company: Company
                    if let comp = realm.object(ofType: Company.self, forPrimaryKey: 1374) {
                        company = comp
                    } else {
                        company = Company()
                        company.name = "Valve Corporation"
                        company.idNumber = 1374
                        company.apiDetailUrl = "https://www.giantbomb.com/api/company/3010-1374/"
                        company.siteDetailUrl = "https://www.giantbomb.com/valve-corporation/3010-1374/"
                        company.add()
                    }
                    steamPlatform = Platform()
                    steamPlatform?.idNumber = Steam.steamPlatformIdNumber
                    steamPlatform?.name = "Steam"
                    steamPlatform?.company = company
                    steamPlatform?.hasDetails = true
                    steamPlatform?.add()
                }
            }
            for game in games {
                let newGame = Game()
                newGame.inLibrary = true
                newGame.fromSteam = true
                newGame.add(game, steamPlatform)
            }
        }
        vc.dismiss(animated: true, completion: nil)
    }
    
    func didDismiss(vc: AddSteamGamesViewController) {
        vc.dismiss(animated: true, completion: nil)
        self.refreshCells()
    }
}

extension GameTableViewController: LibraryAddSearchViewControllerDelegate {
    func didDismiss() {
        self.refreshCells()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
