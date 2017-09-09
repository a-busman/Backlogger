//
//  LibraryAddSearchViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/15/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class LibraryAddSearchViewController: UIViewController {
    
    @IBOutlet weak var tableView:          UITableView?
    @IBOutlet weak var searchTintView:     UIView?
    @IBOutlet weak var searchBackground:   UIImageView?
    @IBOutlet weak var searchLabel:        UILabel?
    @IBOutlet weak var activityIndicator:  UIActivityIndicatorView?
    @IBOutlet weak var activityBackground: UIView?
    @IBOutlet weak var searchBar:          UISearchBar?
    
    @IBOutlet weak var bottomActivity: UIActivityIndicatorView?
    @IBOutlet weak var gameCountLabel: UILabel?
    
    var gameFields: [GameField] = []
    var gameFieldIds: [Int] = []
    var searchResults: SearchResults?
    var isLoadingGames = false
    var currentPage = 0
    var query: String?
    
    var toastOverlay = ToastOverlayViewController()
    
    var platformDict: [Int : Platform] = [:]
    
    var currentlySelectedRow = 0
    
    private var viewAlreadyLoaded = false
    
    var nextOffset = 0
    
    let tableReuseIdentifier = "table_cell"
    
    var isAddingToPlaylist  = false
    var isAddingToPlayNext  = false
    var isAddingToPlayLater = false
    var isAddingToWishlist  = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        self.searchBar?.tintColor = Util.appColor

        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.tableReuseIdentifier)
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
        
        if !Util.isInternetAvailable() {
            self.searchLabel?.text = "No Network Connection."
            self.searchBackground?.isHidden = true
            self.tableView?.tableHeaderView = UIView(frame: .zero)
            self.tableView?.alwaysBounceVertical = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !self.viewAlreadyLoaded && Util.isInternetAvailable() {
            self.searchBar?.becomeFirstResponder()
            self.viewAlreadyLoaded = true
        }
    }
    
    func loadFirstGame(withQuery query: String) {
        self.isLoadingGames = true
        self.currentPage = 0
        GameField.getGames(withQuery: query, { result in
            self.isLoadingGames = false
            if let error = result.error {
                if error.localizedDescription != "cancelled" {
                    let alert = UIAlertController(title: "Error", message: "Could not load first game :( \(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                } else {
                    return
                }
            }
            let searchResults = result.value
            self.addGames(fromSearchResults: searchResults)
            /*var lowestNumReviews: Int = self.gameFields.first!.numReviews
            var offset = 0
            for (i, gameField) in self.gameFields.enumerated() {
                if gameField.numReviews < lowestNumReviews {
                    lowestNumReviews = gameField.numReviews
                    offset = i
                }
            }
            self.nextOffset = offset*/
            self.currentPage = 1
            self.activityIndicator?.stopAnimating()
            self.activityBackground?.isHidden = true
            self.tableView?.reloadData()
        })
    }
    
    func loadMoreGames(withQuery query: String) {
        self.isLoadingGames = true
        if let results = self.searchResults,
            let totalGamesCount = results.numberOfTotalResults,
            self.gameFields.count < totalGamesCount,
            (self.currentPage) * results.limit! < totalGamesCount {
            // there are more games out there!
            self.currentPage += 1
            GameField.getGames(withPageNum: currentPage, query: query, prevResults: results, { result in
                self.isLoadingGames = false
                if let error = result.error {
                    if error.localizedDescription != "cancelled" {
                        let alert = UIAlertController(title: "Error", message: "Could not load more games :( \(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    } else {
                        return
                    }
                }
                let searchResults = result.value
                self.addGames(fromSearchResults: searchResults)
                self.activityIndicator?.stopAnimating()
                self.activityBackground?.isHidden = true
                self.tableView?.reloadData()
            })
        }
    }
    
    func addGames(fromSearchResults searchResults: SearchResults?) {
        self.searchResults = searchResults
        
        for gameField in self.searchResults?.results as! [GameField] {
            autoreleasepool {
                let realm = try? Realm()
                if let dbGameField = realm?.object(ofType: GameField.self, forPrimaryKey: gameField.idNumber) {
                    self.gameFields.append(dbGameField.deepCopy())
                    self.gameFieldIds.append(dbGameField.idNumber)
                } else {
                    self.gameFields.append(gameField)
                    self.gameFieldIds.append(gameField.idNumber)
                }
            }
        }
    }
    
    
    @IBAction func dismissView() {
        if self.searchBar != nil {
            if (self.searchBar?.isFirstResponder)! {
                self.searchBar?.resignFirstResponder()
            }
        }
        self.dismiss(animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add_show_details" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameDetailsViewController
                var gameField: GameField!
                self.currentlySelectedRow = i
                
                self.searchBar?.resignFirstResponder()
                autoreleasepool {
                    let realm = try? Realm()
                    gameField = realm?.object(ofType: GameField.self, forPrimaryKey: self.gameFieldIds[i])
                }
                if gameField == nil {
                    gameField = self.gameFields[i]
                }
                vc.gameField = gameField
                vc.gameFieldId = gameField.idNumber
                vc.delegate = self
            }
        }
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
            self.isAddingToPlayLater = false
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
            self.isAddingToPlayNext = false
        }
    }
}

extension LibraryAddSearchViewController: PlaylistViewControllerDelegate {
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
}

extension LibraryAddSearchViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView?.indexPathForRow(at: location),
            let cell = self.tableView?.cellForRow(at: indexPath) else { return nil }
        
        let i = indexPath.row
        let vc: GameDetailsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "game_details") as! GameDetailsViewController
        var gameField: GameField!
        
        self.searchBar?.resignFirstResponder()
        autoreleasepool {
            let realm = try? Realm()
            gameField = realm?.object(ofType: GameField.self, forPrimaryKey: self.gameFields[i].idNumber)
        }
        if gameField == nil {
            gameField = self.gameFields[i]
        }
        vc.gameField = gameField
        var inLibrary = false
        for game in gameField.ownedGames {
            if game.inLibrary {
                inLibrary = true
            }
        }
        vc.state = inLibrary ? .partialAddToLibrary : .addToLibrary

        vc.delegate = self
        
        vc.addRemoveClosure = { (action, vc) -> Void in
            self.addTapped(i)
        }
        vc.addToPlayLaterClosure = { (action, vc) -> Void in
            self.isAddingToPlayLater = true
            self.addTapped(i)
        }
        vc.addToPlaylistClosure = { (action, vc) -> Void in
            self.isAddingToPlaylist = true
            self.addTapped(i)
        }
        vc.addToPlayNextClosure = { (action, vc) -> Void in
            self.isAddingToPlayNext = true
            self.addTapped(i)
        }
        vc.addToWishlistClosure = { (action, vc) -> Void in
            self.isAddingToWishlist = true
            self.addTapped(i)
        }
        previewingContext.sourceRect = cell.frame
        
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
    }
}

extension LibraryAddSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.gameFields.count == 0 {
            self.gameCountLabel?.isHidden = true
        }
        return self.gameFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.tableReuseIdentifier, for: indexPath) as! TableViewCell
        cell.addButtonHidden = false
        cell.delegate = self
        cell.row = indexPath.row

        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = UIEdgeInsetsMake(0, 58.0, 0, 0)
        }
        if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
            cell.layoutMargins = .zero
        }
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.preservesSuperviewLayoutMargins = false
        }
        
        if self.gameFields.count >= indexPath.row {

            let gameToShow = self.gameFields[indexPath.row]
            
            cell.rightLabel?.text = ""
            cell.percentView?.isHidden = true
            var inLibrary = false
            
            // Check if game is in library
            autoreleasepool {
                let realm = try! Realm()
                if let _ = realm.object(ofType: GameField.self, forPrimaryKey: gameToShow.idNumber) {
                    inLibrary = true
                }
            }
            if inLibrary {
                cell.libraryState = .addPartial
            }
            if let name = gameToShow.name {
                cell.titleLabel?.text = name
            } else {
                cell.titleLabel?.text = ""
            }
            var platformString = ""
            let platforms = gameToShow.platforms
            if platforms.count > 0 {
                if platforms.count > 1 {
                    for platform in platforms[0..<platforms.endIndex - 1] {
                        if platform.name!.characters.count < 10 {
                            platformString += platform.name! + " • "
                        } else {
                            platformString += platform.abbreviation! + " • "
                        }
                    }
                }
                if platforms[platforms.endIndex - 1].name!.characters.count < 10 {
                    platformString += platforms[platforms.endIndex - 1].name!
                } else {
                    platformString += platforms[platforms.endIndex - 1].abbreviation!
                }
            }
            if platformString == "" {
                cell.hideDetails()
            } else {
                cell.showDetails()
            }
            cell.descriptionLabel?.text = platformString
            
            // See if we need to load more games
            let rowsToLoadFromBottom = 5;
            let rowsLoaded = gameFields.count
            if (!self.isLoadingGames && (indexPath.row >= (rowsLoaded - rowsToLoadFromBottom))) {
                let totalRows = self.searchResults?.numberOfTotalResults ?? 0
                let remainingGamesToLoad = totalRows - rowsLoaded;
                if (remainingGamesToLoad > 0) {
                    if !self.bottomActivity!.isAnimating {
                        self.bottomActivity?.startAnimating()
                    }
                    if !self.gameCountLabel!.isHidden {
                        self.gameCountLabel?.isHidden = true
                    }
                    self.loadMoreGames(withQuery: self.query!)
                } else {
                    if self.gameCountLabel!.isHidden {
                        self.gameCountLabel?.text = "\(totalRows) games found."
                        self.gameCountLabel?.isHidden = false
                    }
                    if self.bottomActivity!.isAnimating {
                        self.bottomActivity?.stopAnimating()
                    }
                }
            }

            if let image = gameToShow.image {
                cell.imageUrl = URL(string: image.iconUrl!)
            } else {
                cell.imageUrl = nil
            }
            cell.cacheCompletionHandler = {
                (image, error, cacheType, imageUrl) in
                if let cellUrl = cell.imageUrl {
                    if imageUrl == cellUrl {
                        if image != nil {
                            if cacheType == .none || cacheType == .disk {
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
        }
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar?.resignFirstResponder()
        self.searchBar?.setShowsCancelButton(false, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.searchBar?.resignFirstResponder()
        self.tableView?.deselectRow(at: indexPath, animated: true)
        self.searchBar?.setShowsCancelButton(false, animated: true)
        self.performSegue(withIdentifier: "add_show_details", sender: tableView.cellForRow(at: indexPath))
    }
}

extension LibraryAddSearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.searchTintView?.alpha = 0.2
        },
                       completion: nil)
        
    }
    
    private func performSearch() {
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.searchTintView?.alpha = 0.0
        },
                       completion: nil)
        self.gameFields.removeAll()
        self.searchLabel?.isHidden = true
        self.searchBackground?.isHidden = true
        self.activityIndicator?.startAnimating()
        self.activityBackground?.isHidden = false
        self.gameCountLabel?.isHidden = true
        self.bottomActivity?.isHidden = true
        self.tableView?.reloadData()
        self.loadFirstGame(withQuery: self.query!)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        if self.query != searchBar.text && Util.isInternetAvailable() {
            self.query = searchBar.text
            self.performSearch()
        }
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.searchTintView?.alpha = 0.0
        },
                       completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.query = searchText
        if !(self.query?.isEmpty)! && Util.isInternetAvailable() {
            self.performSearch()
        } else {
            self.gameFields.removeAll()
            self.searchLabel?.isHidden = false
            self.searchBackground?.isHidden = false
            self.activityIndicator?.stopAnimating()
            self.activityBackground?.isHidden = true
            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                            self.searchTintView?.alpha = 0.2
            },
                           completion: nil)
            GameField.cancelCurrentRequest()
            self.tableView?.reloadData()
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.searchTintView?.alpha = 0.0
        },
                       completion: nil)
    }
}

extension LibraryAddSearchViewController: TableViewCellDelegate {
    func addTapped(_ row: Int) {
        self.currentlySelectedRow = row
        let consoleSelection = ConsoleSelectionTableViewController(style: .grouped)
        self.searchBar?.resignFirstResponder()
        consoleSelection.delegate = self
        consoleSelection.gameField = self.gameFields[row]
        if self.isAddingToPlaylist || self.isAddingToPlayNext || self.isAddingToPlayLater {
            consoleSelection.playlist = true
        }
        self.navigationController?.pushViewController(consoleSelection, animated: true)
    }
}

extension LibraryAddSearchViewController: ConsoleSelectionTableViewControllerDelegate {
    func didSelectConsoles(_ consoles: [Platform]) {
        let selectedRow = self.currentlySelectedRow
        var gameList: [Game] = []
        if !self.isAddingToPlaylist && !self.isAddingToPlayNext && !self.isAddingToPlayLater {
            autoreleasepool {
                let realm = try! Realm()
                if let dbGameField = realm.object(ofType: GameField.self, forPrimaryKey: self.gameFields[selectedRow].idNumber) {
                    gameList = Array(dbGameField.ownedGames)
                }
            }
            var newGameList: [Game] = []
            var currentPlatformList: [Platform] = [Platform]()
            var gameField: GameField = self.gameFields[selectedRow].deepCopy()
            var shouldDelete = true
            let cell = self.tableView?.cellForRow(at: IndexPath(row: selectedRow, section: 0)) as! TableViewCell
            if consoles.count > 0 {
                for (index, game) in gameList.enumerated() {
                    if !consoles.contains(game.platform!) && game.inLibrary {
                        if index == (gameList.count - 1) && shouldDelete {
                            gameField = game.deleteWithGameFieldCopy()
                        } else {
                            game.delete()
                        }
                    } else {
                        shouldDelete = false
                        newGameList.append(game)
                        currentPlatformList.append(game.platform!)
                    }
                }
                for platform in consoles[0..<consoles.endIndex] {
                    if !currentPlatformList.contains(platform) {
                        let newGameToSave = Game()
                        if self.isAddingToWishlist {
                            newGameToSave.inWishlist = true
                            newGameToSave.inLibrary = false
                        } else {
                            newGameToSave.inWishlist = false
                            newGameToSave.inLibrary = true
                        }
                        newGameToSave.add(gameField, platform)
                        newGameList.append(newGameToSave)
                    } else {
                        for game in newGameList {
                            if game.platform!.name! == platform.name! {
                                game.update {
                                    if self.isAddingToWishlist {
                                        game.inWishlist = true
                                        game.inLibrary = false
                                    } else {
                                        game.inWishlist = false
                                        game.inLibrary = true
                                    }
                                }
                            }
                        }
                    }
                }
                cell.libraryState = .addPartial
            } else {
                for (index, game) in gameList.enumerated() {
                    if index == (gameList.count - 1) {
                        gameField = game.deleteWithGameFieldCopy()
                    } else {
                        game.delete()
                    }
                }
                cell.libraryState = .add
            }
        } else {
            if consoles.count > 0 {
                var currentPlatformList: [Int] = []
                var platformsToAdd: [Platform] = []
                var consoleIds: [Int] = []
                let idNumber = self.gameFields[selectedRow].idNumber
                
                var gameField: GameField?
                autoreleasepool {
                    let realm = try? Realm()
                    gameField = realm?.object(ofType: GameField.self, forPrimaryKey: idNumber)
                }
                if gameField == nil {
                    gameField = self.gameFields[selectedRow].deepCopy()
                }
                for game in (gameField?.ownedGames)! {
                    if consoles.contains(game.platform!) {
                        currentPlatformList.append(game.platform!.idNumber)
                    }
                }
                for console in consoles {
                    if !currentPlatformList.contains(console.idNumber) {
                        platformsToAdd.append(console)
                    }
                    consoleIds.append(console.idNumber)
                }
                for platform in platformsToAdd {
                    let newGameToSave = Game()
                    if self.isAddingToWishlist {
                        newGameToSave.inWishlist = true
                        newGameToSave.inLibrary = false
                    } else {
                        newGameToSave.inWishlist = false
                        newGameToSave.inLibrary = true
                    }
                    newGameToSave.add(gameField, platform)
                }
                
                autoreleasepool {
                    let realm = try? Realm()
                    gameField = realm?.object(ofType: GameField.self, forPrimaryKey: idNumber)
                }
                
                var gamesToAdd: [Game] = []
                for game in gameField!.ownedGames {
                    let platform = game.platform!
                    if consoleIds.contains(platform.idNumber) {
                        gamesToAdd.append(game)
                    }
                }
                
                if self.isAddingToPlaylist {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistNavigation") as! UINavigationController
                    let playlistVc = vc.viewControllers.first as! PlaylistViewController
                    playlistVc.addingGames = gamesToAdd
                    playlistVc.isAddingGames = true
                    playlistVc.delegate = self
                    self.present(vc, animated: true, completion: nil)
                    self.isAddingToPlaylist = false
                }
                if self.isAddingToPlayNext {
                    self.addToUpNext(games: gamesToAdd, later: false)
                    self.isAddingToPlayNext = false
                }
                if self.isAddingToPlayLater {
                    self.addToUpNext(games: gamesToAdd, later: true)
                    self.isAddingToPlayLater = false
                }
                if self.isAddingToWishlist {
                    self.isAddingToWishlist = false
                }
            }
        }
    }
}

extension LibraryAddSearchViewController: GameDetailsViewControllerDelegate {
    func gamesCreated(gameField: GameField) {
        let cell = self.tableView?.cellForRow(at: IndexPath(row: self.currentlySelectedRow, section: 0)) as! TableViewCell
        if gameField.ownedGames.count > 0 {
            cell.libraryState = .addPartial
        } else {
            cell.libraryState = .add
        }
    }
}
