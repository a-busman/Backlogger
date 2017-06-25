//
//  GameTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class GameTableViewController: UIViewController, GameDetailsViewControllerDelegate, UIViewControllerPreviewingDelegate, PlaylistViewControllerDelegate, AddSteamGamesViewControllerDelegate {
    
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
    
    var games: Results<Game>?
    
    var platform: Platform?
    var platformId: Int?
    
    var currentlySelectedRow = 0
    
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
    fileprivate let startInset:           CGFloat = 229.0
    fileprivate var headerTravelDistance: CGFloat = 0.0
    fileprivate var insetToHeader:        CGFloat = 0.0
    
    fileprivate let tableReuseIdentifier = "table_cell"
    
    enum SortType: Int {
        case alphabetical = 0
        case dateAdded = 1
        case releaseYear = 2
        case percentComplete = 3
        case completed = 4
    }

    
    var sortType: SortType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.headerTravelDistance = self.headerMaxHeight - self.headerMinHeight
        self.insetToHeader = startInset - headerMaxHeight
        if let platform = self.platform {
            self.platformId = platform.idNumber
            self.titleLabel?.text = platform.name
            self.games = platform.ownedGames.filter("platform.name = \"\(platform.name!)\"")
            if platform.name!.characters.count < 10 {
                self.title = platform.name
            } else {
                self.title = platform.abbreviation
            }
//            if let releaseDate = platform.releaseDate {
//                let index = releaseDate.index(releaseDate.startIndex, offsetBy: 4)
//                self.yearLabel?.text = "\(platform.company?.name ?? "") • \(releaseDate.substring(to: index))"
//            } else {
//                self.yearLabel?.text = "\(platform.company?.name ?? "")"
//            }
            if !platform.hasDetails && !platform.custom {
                platform.updateDetails { results in
                    if let error = results.error {
                        NSLog("\(error.localizedDescription)")
                        self.platformImage?.image = #imageLiteral(resourceName: "now_playing_placeholder")
                    } else {
                        if let superUrl = platform.image?.superUrl {
                            self.platformImage?.kf.setImage(with: URL(string: superUrl), placeholder: #imageLiteral(resourceName: "now_playing_placeholder"), completionHandler: {
                                (image, error, cacheType, imageUrl) in
                                if image != nil {
                                    if cacheType == .none {
                                        UIView.transition(with: self.platformImage!,
                                                          duration:0.5,
                                                          options: .transitionCrossDissolve,
                                                          animations: { self.platformImage?.image = image },
                                                          completion: nil)
                                    } else {
                                        self.platformImage?.image = image
                                    }
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
                            (image, error, cacheType, imageUrl) in
                            if image != nil {
                                if cacheType == .none {
                                    UIView.transition(with: self.platformImage!,
                                                      duration:0.5,
                                                      options: .transitionCrossDissolve,
                                                      animations: { self.platformImage?.image = image },
                                                      completion: nil)
                                } else {
                                    self.platformImage?.image = image
                                }
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
        
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                self.registerForPreviewing(with: self, sourceView: self.tableView!)
            }
        }
        self.toastOverlay.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(toastOverlay.view)
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerX,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerY,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 300.0
            ).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let sort = UserDefaults.standard.value(forKey: "librarySortType")
        if sort == nil {
            self.sortType = .dateAdded
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
        } else {
            self.sortType = SortType.init(rawValue: sort as! Int)
        }
        autoreleasepool {
            let realm = try? Realm()
            self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId)
        }
        if self.platform == nil {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
        var sortString: String
        var ascending: Bool
        switch self.sortType! {
        case .alphabetical:
            sortString = "gameFields.name"
            ascending = true
            break
        case .dateAdded:
            sortString = "dateAdded"
            ascending = false
            break
        case .releaseYear:
            sortString = "gameFields.releaseDate"
            ascending = true
            break
        case .percentComplete:
            sortString = "progress"
            ascending = true
            break
        case .completed:
            sortString = "finished"
            ascending = true
        }
        self.games = self.platform?.ownedGames.sorted(byKeyPath: sortString, ascending: ascending)
        self.tableView?.reloadData()
        
        
        if self.currentScrollPosition < 90.0 {
            let remainingWidth = self.currentScrollPosition - 65.0
            let newColor = UIColor(white: 1.0, alpha: (25.0 - remainingWidth) / 25.0)
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: newColor]
        } else if self.currentScrollPosition < 65.0 {
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        } else {
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.clear]
        }
        if self.games!.count < 1 {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !self.didLayout {
            self.shadowGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: (self.shadowView?.frame.width)!, height: (self.shadowView?.frame.height)!)
            let darkColor = UIColor(white: 0.0, alpha: 0.3).cgColor
            self.shadowGradientLayer.colors = [UIColor.clear.cgColor, darkColor]
            self.shadowGradientLayer.locations = [0.7, 1.0]
            self.tableView?.contentInset.top = self.startInset
            self.tableView?.contentInset.bottom = 49.0
            self.tableView?.scrollIndicatorInsets.top = self.startInset
            self.tableView?.scrollIndicatorInsets.bottom = 50.0
            self.tableView?.setContentOffset(CGPoint(x: 0.0, y: -self.startInset), animated: false)
            self.shadowView?.layer.addSublayer(shadowGradientLayer)
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
                
                self.currentlySelectedRow = i
                
                vc.gameField = self.games![i].gameFields
                vc.game = self.games![i]
                vc.state = .inLibrary
                vc.delegate = self
            }
        }
    }
    func gamesCreated(gameField: GameField) {
        /*if games.count == 1 {
            self.games[self.currentlySelectedRow] = games.first!
        } else {
            self.games.remove(at: self.currentlySelectedRow)
        }*/
    }
    
    @IBAction func moreTapped(sender: UIBarButtonItem) {
        
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let addAction = self.platform!.idNumber != Steam.steamPlatformIdNumber ?
        UIAlertAction(title: "Add Games", style: .default, handler: self.addGames) :
        UIAlertAction(title: "Sync with Steam", style: .default, handler: self.syncWithSteam)
        let sortAction = UIAlertAction(title: "Sort...", style: .default, handler: self.sortTapped)
        
        actions.addAction(addAction)
        actions.addAction(sortAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)
    }
    
    func sortTapped(sender: UIAlertAction) {
        let actions = UIAlertController(title: "Sort games", message: nil, preferredStyle: .actionSheet)

        let alphaAction = UIAlertAction(title: "Title", style: .default, handler: { _ in
            self.sortType = .alphabetical
            if self.games != nil {
                self.games = self.games!.sorted(byKeyPath: "gameFields.name", ascending: true)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let dateAction = UIAlertAction(title: "Recently Added", style: .default, handler: { _ in
            self.sortType = .dateAdded
            if self.games != nil {
                self.games = self.games!.sorted(byKeyPath: "dateAdded", ascending: true)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let releaseAction = UIAlertAction(title: "Release Date", style: .default, handler: { _ in
            self.sortType = .releaseYear
            if self.games != nil {
                self.games = self.games!.sorted(byKeyPath: "gameFields.releaseDate", ascending: true)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let percentAction = UIAlertAction(title: "Progress", style: .default, handler: { _ in
            self.sortType = .percentComplete
            if self.games != nil {
                self.games = self.games!.sorted(byKeyPath: "progress", ascending: true)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let completeAction = UIAlertAction(title: "Finished", style: .default, handler: { _ in
            self.sortType = .completed
            if self.games != nil {
                self.games = self.games!.sorted(byKeyPath: "finished", ascending: true)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        
        switch self.sortType! {
        case .alphabetical:
            alphaAction.setValue(true, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            releaseAction.setValue(false, forKey: "checked")
            percentAction.setValue(false, forKey: "checked")
            completeAction.setValue(false, forKey: "checked")
            break
        case .dateAdded:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(true, forKey: "checked")
            releaseAction.setValue(false, forKey: "checked")
            percentAction.setValue(false, forKey: "checked")
            completeAction.setValue(false, forKey: "checked")
            break
        case .releaseYear:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            releaseAction.setValue(true, forKey: "checked")
            percentAction.setValue(false, forKey: "checked")
            completeAction.setValue(false, forKey: "checked")
            break
        case .percentComplete:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            releaseAction.setValue(false, forKey: "checked")
            percentAction.setValue(true, forKey: "checked")
            completeAction.setValue(false, forKey: "checked")
            break
        case .completed:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            releaseAction.setValue(false, forKey: "checked")
            percentAction.setValue(false, forKey: "checked")
            completeAction.setValue(true, forKey: "checked")
            break
        }
        actions.addAction(alphaAction)
        actions.addAction(dateAction)
        actions.addAction(releaseAction)
        actions.addAction(percentAction)
        actions.addAction(completeAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)
    }
    
    func syncWithSteam(sender: UIAlertAction) {
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
                        UIApplication.shared.endIgnoringInteractionEvents()
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
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func tappedDone(sender: UIBarButtonItem) {
        self.steamVc?.dismiss(animated: true, completion: nil)
    }
    
    func addGames(sender: UIAlertAction) {
        let vc: LibraryAddSearchViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "add_game") as! LibraryAddSearchViewController
        let navVc = UINavigationController(rootViewController: vc)
        navVc.navigationBar.barStyle = .black
        navVc.navigationBar.isTranslucent = true
        navVc.navigationBar.barTintColor = Util.appColor
        self.present(navVc, animated: true, completion: nil)
    }
    
    func didSelectSteamGames(vc: AddSteamGamesViewController, games: [GameField]) {
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
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView?.indexPathForRow(at: location),
            let cell = self.tableView?.cellForRow(at: indexPath),
            let gameFields = self.games![indexPath.row].gameFields else { return nil }
        let game = self.games![indexPath.row]
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
        vc.delegate = self
        vc.gameField = gameField
        
        previewingContext.sourceRect = cell.frame
        
        vc.addRemoveClosure = { (action, vc) -> Void in
            let game = self.games![indexPath.row]
            game.delete()
            autoreleasepool {
                let realm = try? Realm()
                self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: self.platform!.idNumber)
            }
            if self.platform != nil {
                self.games = self.platform?.ownedGames.filter("platform.name = \"\(self.platform!.name!)\"")
                self.tableView?.reloadData()
            } else {
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
        vc.addToPlayLaterClosure = { (action, vc) -> Void in
            self.addToUpNext(games: [game], later: true)
        }
        vc.addToPlaylistClosure = { (action, vc) -> Void in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistNavigation") as! UINavigationController
            let playlistVc = vc.viewControllers.first as! PlaylistViewController
            playlistVc.addingGames = [game]
            playlistVc.isAddingGames = true
            playlistVc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
        vc.addToPlayNextClosure = { (action, vc) -> Void in
            self.addToUpNext(games: [game], later: false)
        }
        return vc
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
                        upNextPlaylist?.games.append(contentsOf: currentGames)
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
                        upNextPlaylist?.games.append(contentsOf: currentGames)
                    }
                }
            }
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "play_next_large"), title: "Added to Queue", description: "We'll play this one next.")
        }
    }
    
    func chosePlaylist(vc: PlaylistViewController, playlist: Playlist, games: [Game], isNew: Bool) {
        if !isNew {
            playlist.update {
                playlist.games.append(contentsOf: games)
            }
        }
        vc.presentingViewController?.dismiss(animated: true, completion: {
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_playlist_large"), title: "Added to Playlist", description: "Added to \"\(playlist.name!)\".")
        })
        vc.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
}

extension GameTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        cell.row = indexPath.row
        cell.accessoryType = .disclosureIndicator
        let game = self.games![indexPath.row]
        var indent: CGFloat = 0.0
        
        if indexPath.row < self.games!.count - 1 {
            indent = 58.0
        }
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = UIEdgeInsetsMake(0, indent, 0, 0)
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
            let year = releaseDate.substring(to: releaseDate.index(releaseDate.startIndex, offsetBy: 4))
            cell.descriptionLabel?.text = year
            cell.showDetails()
        } else {
            cell.descriptionLabel?.text = ""
            cell.hideDetails()
        }
        cell.rightLabel?.text = "\(game.progress)%"
        if let image = game.gameFields?.image {
            cell.imageUrl = URL(string: image.iconUrl!)
        }
        cell.cacheCompletionHandler = {
            (image, error, cacheType, imageUrl) in
            if let cellUrl = cell.imageUrl {
                if imageUrl == cellUrl {
                    if image != nil {
                        if cacheType == .none {
                            UIView.transition(with: cell.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                cell.set(image: image!)
                            }, completion: nil)
                        } else {
                            cell.set(image: image!)
                        }
                    }
                }
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let game = games![indexPath.row]
            game.delete()
            autoreleasepool {
                let realm = try? Realm()
                self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: self.platformId)
            }
            if self.platform != nil {
                var sortString: String
                var ascending: Bool
                switch self.sortType! {
                case .alphabetical:
                    sortString = "gameFields.name"
                    ascending = true
                    break
                case .dateAdded:
                    sortString = "dateAdded"
                    ascending = false
                    break
                case .releaseYear:
                    sortString = "gameFields.releaseDate"
                    ascending = true
                    break
                case .percentComplete:
                    sortString = "progress"
                    ascending = true
                    break
                case .completed:
                    sortString = "finished"
                    ascending = true
                }
                self.games = self.platform?.ownedGames.sorted(byKeyPath: sortString, ascending: ascending)
                self.tableView?.deleteRows(at: [indexPath], with: .automatic)
                //self.tableView?.reloadData()
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
            if offset < 90.0 {
                if offset < 65.0 {
                    self.tableView?.scrollIndicatorInsets.top = 65.0
                    self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
                } else {
                    self.tableView?.scrollIndicatorInsets.top = offset
                    let remainingWidth = offset - 65.0
                    let newColor = UIColor(white: 1.0, alpha: (25.0 - remainingWidth) / 25.0)
                    self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: newColor]
                }
            } else {
                self.tableView?.scrollIndicatorInsets.top = offset
                self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.clear]
            }
        }
    }
}
