//
//  AddToPlaylist.swift
//  Backlogger
//
//  Created by Alex Busman on 5/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

protocol AddToPlaylistViewControllerDelegate {
    func didChoose(games: List<Game>)
    func dismissView(_ vc: AddToPlaylistViewController)
}

class AddToPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TableViewCellDelegate, ConsoleSelectionTableViewControllerDelegate{
    
    var allGames: Results<Game>?
    var filteredGames: Results<Game>?
    var addedGames = List<Game>()
    var query = ""
    var delegate: AddToPlaylistViewControllerDelegate?
    let reuseIdentifier = "table_cell"
    
    var gameFields: [GameField] = []
    var isLoadingGames = false
    var currentPage = 0
    var searchResults: SearchResults?
    var currentlySelectedRow = 0
    
    @IBOutlet weak var searchBar:          UISearchBar?
    @IBOutlet weak var tableView:          UITableView?
    @IBOutlet weak var activityBackground: UIView?
    @IBOutlet weak var activityIndicator:  UIActivityIndicatorView?
    
    @IBOutlet weak var bottomActivity: UIActivityIndicatorView?
    @IBOutlet weak var gameCountLabel: UILabel?
    
    
    var registeredToSearch = false
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.tintColor = .white
        self.searchBar?.tintColor = Util.appColor
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.reuseIdentifier)
        self.bottomActivity?.stopAnimating()
        autoreleasepool {
            let realm = try! Realm()
            self.allGames = realm.objects(Game.self)
            self.filteredGames = self.allGames
        }
        self.gameCountLabel?.text = "\(self.filteredGames!.count) games found."
        self.gameCountLabel?.isHidden = false
        if !Util.isInternetAvailable() {
            self.searchBar?.showsScopeBar = false
            self.searchBar?.sizeToFit()
            let scopeBarContainer = self.searchBar!.subviews.first!.subviews.first!
            for view in scopeBarContainer.subviews {
                if view.isKind(of: UISegmentedControl.self) {
                    scopeBarContainer.isHidden = true
                    break
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func cancelTapped(sender: UIBarButtonItem) {
        self.searchBar?.resignFirstResponder()
        self.delegate?.dismissView(self)
    }
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        self.delegate?.didChoose(games: self.addedGames)
        self.searchBar?.resignFirstResponder()
        self.delegate?.dismissView(self)
    }
    
    func loadFirstGame(withQuery query: String) {
        self.isLoadingGames = true
        self.currentPage = 0
        GameField.getGames(withQuery: query, { result in
            if let error = result.error {
                self.isLoadingGames = false
                if error.localizedDescription != "cancelled" {
                    let alert = UIAlertController(title: "Error", message: "Could not load first game :( \(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                } else {
                    return
                }
            }
            let searchResults = result.value
            self.addGames(fromSearchResults: searchResults)
            self.currentPage = 1
            self.isLoadingGames = false
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
                if let error = result.error {
                    self.isLoadingGames = false
                    if error.localizedDescription != "cancelled" {
                        let alert = UIAlertController(title: "Error", message: "Could not load more games :( \(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    } else {
                        return
                    }
                }
                let searchResults = result.value
                self.addGames(fromSearchResults: searchResults)
                self.isLoadingGames = false
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
                    self.gameFields.append(dbGameField)
                } else {
                    self.gameFields.append(gameField)
                }
            }
        }
    }
    
    func didSelectConsoles(_ consoles: [Platform]) {
        let selectedRow = self.currentlySelectedRow
        var gameList: [Game] = []
        let gameField = self.gameFields[selectedRow]
        autoreleasepool {
            let realm = try! Realm()
            if let dbGameField = realm.object(ofType: GameField.self, forPrimaryKey: gameField.idNumber) {
                gameList = Array(dbGameField.ownedGames)
            }
        }
        
        var newGameList: [Game] = []
        var currentPlatformList: [Int: Game] = [:]
        for game in gameList {
            currentPlatformList[game.platform!.idNumber] = game
        }
        let cell = self.tableView?.cellForRow(at: IndexPath(row: selectedRow, section: 0)) as! TableViewCell
        if consoles.count > 0 {
            for console in consoles {
                let game = currentPlatformList[console.idNumber]
                if game == nil {
                    let newGameToSave = Game()
                    newGameToSave.inLibrary = true
                    newGameToSave.add(gameField, console)
                    newGameList.append(newGameToSave)
                } else {
                    newGameList.append(game!)
                }
            }
            self.addedGames.append(contentsOf: newGameList)
            cell.libraryState = .inPlaylist
        } else {
            cell.libraryState = .addPlaylist
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchBar?.selectedScopeButtonIndex == 0 {
            return self.filteredGames?.count ?? 0
        } else {
            return self.gameFields.count
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! TableViewCell
        if self.searchBar?.selectedScopeButtonIndex == 0 {
            if cell.libraryState == .addPlaylist {
                cell.libraryState = .inPlaylist
                self.addTapped(indexPath.row)
            }
        } else {
            if cell.libraryState == .addPlaylist {
                self.showConsoleSelection(indexPath.row)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView != self.tableView {
            if !self.registeredToSearch {
                tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.reuseIdentifier)
                self.registeredToSearch = true
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TableViewCell
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
        
        if self.searchBar?.selectedScopeButtonIndex == 0 {
            if let game = self.filteredGames?[indexPath.row] {
                if self.addedGames.contains(game) {
                    cell.libraryState = .inPlaylist
                } else {
                    cell.libraryState = .addPlaylist
                }
                cell.titleLabel?.text = (game.gameFields?.name)!
                cell.descriptionLabel?.text = (game.platform?.name)!
                cell.rightLabel?.text = ""
                cell.percentImage?.isHidden = true
                if let gameField = game.gameFields {
                    if let image = gameField.image {
                        cell.imageUrl = URL(string: image.iconUrl!)
                    }
                    cell.cacheCompletionHandler = {
                        (image, error, cacheType, imageUrl) in
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
        } else {
            if self.gameFields.count >= indexPath.row {
                
                let gameToShow = self.gameFields[indexPath.row]
                cell.percentImage?.isHidden = true
                cell.rightLabel?.text = ""
                var inLibrary = false
                
                // Check if game is in library
                autoreleasepool {
                    let realm = try! Realm()
                    if let _ = realm.object(ofType: GameField.self, forPrimaryKey: gameToShow.idNumber) {
                        inLibrary = true
                    }
                }
                if inLibrary {
                    var inPlaylist = false
                    for game in self.addedGames {
                        if game.gameFields!.idNumber == gameToShow.idNumber {
                            inPlaylist = true
                        }
                    }
                    if inPlaylist {
                        cell.libraryState = .inPlaylist
                    } else {
                        cell.libraryState = .addPlaylist
                    }
                } else {
                    cell.libraryState = .addPlaylist
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
                        self.loadMoreGames(withQuery: self.query)
                    } else {
                        if self.bottomActivity!.isAnimating {
                            self.bottomActivity?.stopAnimating()
                        }
                        if self.gameCountLabel!.isHidden {
                            self.gameCountLabel?.text = "\(totalRows) games found."
                            self.gameCountLabel?.isHidden = false
                        }
                    }
                }
                
                if let image = gameToShow.image {
                    cell.imageUrl = URL(string: image.iconUrl!)
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
        }
        
        return cell
    }
    
    func showConsoleSelection(_ row: Int) {
        self.currentlySelectedRow = row
        let consoleSelection = ConsoleSelectionTableViewController(style: .grouped)
        self.searchBar?.resignFirstResponder()
        consoleSelection.delegate = self
        consoleSelection.gameField = self.gameFields[row]
        consoleSelection.playlist = true
        self.navigationController?.pushViewController(consoleSelection, animated: true)
    }
    
    func addTapped(_ row: Int) {
        if self.searchBar?.selectedScopeButtonIndex == 0 {
            let cell = self.tableView?.cellForRow(at: IndexPath(row: row, section: 0)) as! TableViewCell
            cell.libraryState = .inPlaylist
            self.addedGames.append(self.filteredGames![row])
        } else {
            self.showConsoleSelection(row)
        }
    }
    
    func filterContent(for searchText: String, scope: String = "All") {
        if searchText != "" {
            filteredGames = allGames!.filter("gameFields.name contains[c] \"\(searchText)\"")
        } else {
            filteredGames = allGames
        }
        self.tableView?.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar?.resignFirstResponder()
        self.searchBar?.setShowsCancelButton(false, animated: true)
    }
}

extension AddToPlaylistViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchBar.placeholder = searchBar.scopeButtonTitles![selectedScope]
        if selectedScope == 0 {
            self.filterContent(for: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
            if self.bottomActivity!.isAnimating {
                self.bottomActivity?.stopAnimating()
            }
            self.gameCountLabel?.text = "\(self.filteredGames!.count) games found."
            if self.gameCountLabel!.isHidden {
                self.gameCountLabel?.isHidden = false
            }
        } else {
            if self.query != searchBar.text && searchBar.text != nil && searchBar.text != ""{
                self.query = searchBar.text!
                self.performSearch(withQuery: searchBar.text!)
            }
            if self.bottomActivity!.isAnimating {
                self.bottomActivity?.stopAnimating()
            }
            if !self.gameCountLabel!.isHidden {
                self.gameCountLabel?.isHidden = true
            }
        }
        self.tableView?.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        return
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if searchBar.selectedScopeButtonIndex == 0 {
            self.filterContent(for: searchBar.text!)
            if self.bottomActivity!.isAnimating {
                self.bottomActivity?.stopAnimating()
            }
            self.gameCountLabel?.text = "\(self.filteredGames!.count) games found."
            if self.gameCountLabel!.isHidden {
                self.gameCountLabel?.isHidden = false
            }
        } else {
            if self.query != searchBar.text && searchBar.text != nil && searchBar.text != ""{
                self.query = searchBar.text!
                self.performSearch(withQuery: searchBar.text!)
                if self.bottomActivity!.isAnimating {
                    self.bottomActivity?.stopAnimating()
                }
                if !self.gameCountLabel!.isHidden {
                    self.gameCountLabel?.isHidden = true
                }
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.selectedScopeButtonIndex == 0 {
            self.filterContent(for: searchText)
            if self.bottomActivity!.isAnimating {
                self.bottomActivity?.stopAnimating()
            }
            self.gameCountLabel?.text = "\(self.filteredGames!.count) games found."
            if self.gameCountLabel!.isHidden {
                self.gameCountLabel?.isHidden = false
            }
        } else {
            if self.query != searchText && searchText != ""{
                self.query = searchText
                self.performSearch(withQuery: searchText)
                if self.bottomActivity!.isAnimating {
                    self.bottomActivity?.stopAnimating()
                }
                if !self.gameCountLabel!.isHidden {
                    self.gameCountLabel?.isHidden = true
                }
            }
        }
    }
    
    private func performSearch(withQuery query: String) {
        self.gameFields.removeAll()
        self.activityIndicator?.startAnimating()
        self.activityBackground?.isHidden = false
        self.tableView?.reloadData()
        self.loadFirstGame(withQuery: query)
    }
}

extension AddToPlaylistViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        self.filterContent(for: searchController.searchBar.text!, scope: scope)
    }
}
