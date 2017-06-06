//
//  LibraryAddSearchViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/15/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class LibraryAddSearchViewController: UIViewController, ConsoleSelectionTableViewControllerDelegate, GameDetailsViewControllerDelegate {
    
    @IBOutlet weak var tableView:          UITableView?
    @IBOutlet weak var searchTintView:     UIView?
    @IBOutlet weak var searchBackground:   UIImageView?
    @IBOutlet weak var searchLabel:        UILabel?
    @IBOutlet weak var activityIndicator:  UIActivityIndicatorView?
    @IBOutlet weak var activityBackground: UIView?
    @IBOutlet weak var searchBar:          UISearchBar?
    @IBOutlet weak var cancelButton:       UIBarButtonItem?
    
    var gameFields: [GameField] = []
    var searchResults: SearchResults?
    var isLoadingGames = false
    var currentPage = 0
    var query: String?
    
    var platformDict: [Int : Platform] = [:]
    
    var currentlySelectedRow = 0
    
    private var viewAlreadyLoaded = false
    
    var toastOverlay = ToastOverlayViewController()
    
    let tableReuseIdentifier = "table_cell"
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        self.searchBar?.tintColor = .white
        self.tableView?.tableFooterView = UIView(frame: .zero)
        //self.loadFirstGame(withQuery: self.query!)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        self.toastOverlay.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.toastOverlay.view)
        NSLayoutConstraint(item: self.toastOverlay.view,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerX,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: self.toastOverlay.view,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerY,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: self.toastOverlay.view,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 250.0
            ).isActive = true
        NSLayoutConstraint(item: self.toastOverlay.view,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 250.0
            ).isActive = true
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.tableReuseIdentifier)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                self.registerForPreviewing(with: self, sourceView: self.tableView!)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !self.viewAlreadyLoaded {
            self.searchBar?.becomeFirstResponder()
            self.viewAlreadyLoaded = true
        }
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
    
    
    @IBAction func dismissView() {
        if (self.searchBar?.isFirstResponder)! {
            self.searchBar?.resignFirstResponder()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
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
                    gameField = realm?.object(ofType: GameField.self, forPrimaryKey: self.gameFields[i].idNumber)
                }
                if gameField == nil {
                    gameField = self.gameFields[i]
                }
                vc.gameField = gameField
                vc.state = gameField.ownedGames.count > 0 ? .partialAddToLibrary : .addToLibrary
                vc.delegate = self
            }
        }
    }
    
    func gamesCreated(gameField: GameField) {
        let cell = self.tableView?.cellForRow(at: IndexPath(row: self.currentlySelectedRow, section: 0)) as! TableViewCell
        if gameField.ownedGames.count > 0 {
            cell.libraryState = .addPartial
        } else {
            cell.libraryState = .add
        }
    }
    
    func didSelectConsoles(_ consoles: [Platform]) {
        let selectedRow = self.currentlySelectedRow
        var gameList: [Game] = []
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
                if !consoles.contains(game.platform!) {
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
                    newGameToSave.inLibrary = true
                    newGameToSave.add(gameField, platform)
                    newGameList.append(newGameToSave)
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
    }
}

extension LibraryAddSearchViewController: UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gameFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.tableReuseIdentifier, for: indexPath) as! TableViewCell
        cell.addButtonHidden = false
        cell.delegate = self
        cell.row = indexPath.row

        var indent: CGFloat = 0.0
        if indexPath.row < self.gameFields.count - 1 {
            indent = 55.0
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
        
        if self.gameFields.count >= indexPath.row {

            let gameToShow = self.gameFields[indexPath.row]
            
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
            cell.descriptionLabel?.text = platformString
            
            // See if we need to load more games
            let rowsToLoadFromBottom = 5;
            let rowsLoaded = gameFields.count
            if (!self.isLoadingGames && (indexPath.row >= (rowsLoaded - rowsToLoadFromBottom))) {
                let totalRows = self.searchResults?.numberOfTotalResults ?? 0
                let remainingGamesToLoad = totalRows - rowsLoaded;
                if (remainingGamesToLoad > 0) {
                    self.loadMoreGames(withQuery: self.query!)
                }
            }

            if let image = gameToShow.image {
                cell.imageUrl = URL(string: image.iconUrl!)
            }
            cell.cacheCompletionHandler = {
                (image, error, cacheType, imageUrl) in
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
        
        return cell
    }
    
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
        vc.state = gameField.ownedGames.count > 0 ? .partialAddToLibrary : .addToLibrary
        vc.delegate = self
        
        previewingContext.sourceRect = cell.frame
        
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
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
        self.tableView?.reloadData()
        self.loadFirstGame(withQuery: self.query!)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        if self.query != searchBar.text {
            self.query = searchBar.text
            self.performSearch()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.query = searchText
        if !(self.query?.isEmpty)! {
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
        let consoleSelection = ConsoleSelectionTableViewController()
        self.searchBar?.resignFirstResponder()
        consoleSelection.delegate = self
        consoleSelection.gameField = self.gameFields[row]
        self.navigationController?.pushViewController(consoleSelection, animated: true)
    }
}
