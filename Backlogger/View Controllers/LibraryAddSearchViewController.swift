//
//  LibraryAddSearchViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/15/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class LibraryAddSearchViewController: UIViewController, ConsoleSelectionTableViewControllerDelegate, GameDetailsViewControllerDelegate {
    
    @IBOutlet weak var tableView:          UITableView?
    @IBOutlet weak var searchTintView:     UIView?
    @IBOutlet weak var searchBackground:   UIImageView?
    @IBOutlet weak var searchLabel:        UILabel?
    @IBOutlet weak var activityIndicator:  UIActivityIndicatorView?
    @IBOutlet weak var activityBackground: UIView?
    @IBOutlet weak var searchBar:          UISearchBar?
    @IBOutlet weak var cancelButton:       UIBarButtonItem?
    
    var games: [GameField]?
    var gamesViewControllers: [TableViewCellView] = [TableViewCellView]()
    var searchResults: SearchResults?
    var isLoadingGames = false
    var currentPage = 0
    var query: String?
    var imageCache: [String : UIImage] = [:]
    
    var platformDict: [Int : Platform] = [:]
    
    var currentGameField: GameField?
    
    var tempGames: [Int: [Game]] = [:]
    
    var currentlySelectedRow = 0
    
    private var viewAlreadyLoaded = false
    
    var toastOverlay = ToastOverlayViewController()
    
    let tableReuseIdentifier = "library_add_search_cell"
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        self.searchBar?.tintColor = .white
        //self.loadFirstGame(withQuery: self.query!)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
                           constant: 250.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 250.0
            ).isActive = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !viewAlreadyLoaded {
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
        if let games = self.games,
            let results = self.searchResults,
            let totalGamesCount = results.numberOfTotalResults,
            games.count < totalGamesCount,
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
        if self.games == nil {
            self.games = self.searchResults?.results
        } else if self.searchResults != nil && self.searchResults!.results != nil {
            self.games = self.games! + self.searchResults!.results!
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
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
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
                var stringList = [String]()
                let gameList = self.tempGames[(self.games?[i].idNumber)!] ?? [Game]()
                
                self.currentlySelectedRow = i
                for game in gameList {
                    stringList.append(game.uuid)
                }
                
                self.searchBar?.resignFirstResponder()
                
                vc.stringsToFetch = stringList
                vc.gameFieldId = self.games?[i].idNumber
                vc.gameField = self.games?[i]
                vc.state = stringList.count > 0 ? .partialAddToLibrary : .addToLibrary
                vc.delegate = self
            }
        }
    }
    
    func gamesCreated(gameField: GameField, games: [Game]) {
        if games.count > 0 {
            self.gamesViewControllers[self.currentlySelectedRow].libraryState = .remove
        } else {
            self.gamesViewControllers[self.currentlySelectedRow].libraryState = .add
        }
        self.games?[self.currentlySelectedRow] = gameField
        self.tempGames[gameField.idNumber] = games
    }
    
    func didSelectConsoles(_ consoles: [Int]) {
        let currentGameId = (self.currentGameField?.idNumber)!
        var gameList: [Game] = self.tempGames[currentGameId] ?? [Game]()
        var currentPlatformList: [Int] = [Int]()
        for i in 0..<gameList.count {
            let game = gameList[i]
            if !consoles.contains((game.platform?.idNumber)!) {
                game.delete()
                gameList.remove(at: i)
            } else {
                currentPlatformList.append((game.platform?.idNumber)!)
            }
        }
        if consoles.count > 0 {
            for platform in consoles[0..<consoles.endIndex] {
                if !currentPlatformList.contains(platform) {
                    let newGameToSave = Game()
                    newGameToSave.inLibrary = true
                    newGameToSave.add(self.currentGameField, self.platformDict[platform])
                    gameList.append(newGameToSave)
                }
            }
            self.gamesViewControllers[self.currentlySelectedRow].libraryState = .remove
            self.tempGames[currentGameId] = gameList
        }
    }
    
    func didSelectConsoles(withCustom custom: [Platform], _ consoles: [Int]) {
        for newPlatform in custom {
            self.platformDict[newPlatform.idNumber] = newPlatform
        }
        self.didSelectConsoles(consoles)
    }
}

extension LibraryAddSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier, for: indexPath) as! TableViewCell
        var cellView: TableViewCellView
        if indexPath.row + 1 > gamesViewControllers.count {
            cellView = TableViewCellView(indexPath.row)
            cellView.addButtonHidden = false
            cellView.delegate = self
            gamesViewControllers.append(cellView)
        } else {
            cellView = gamesViewControllers[indexPath.row]
        }

        cellView.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(cellView.view)
        
        NSLayoutConstraint(item: cellView.view,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .leading,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: cellView.view,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .trailing,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: cellView.view,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .top,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: cellView.view,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        
        if let games = self.games, games.count >= indexPath.row {
            cell.backgroundColor = (indexPath.item % 2) == 1 ? .clear : .white
            if cellView.imageSource == .Placeholder {
                cellView.artView?.image = (indexPath.item % 2) == 1 ? #imageLiteral(resourceName: "table_placeholder_dark") : #imageLiteral(resourceName: "table_placeholder_light")
            }
            let gameToShow = games[indexPath.row]
            var rightLabelText = ""
            if let releaseDate = gameToShow.releaseDate {
                if !releaseDate.isEmpty {
                    let index = releaseDate.index(releaseDate.startIndex, offsetBy: 4)
                    rightLabelText = releaseDate.substring(to: index)
                } else {
                    let expectedDate = gameToShow.expectedDate
                    if expectedDate > 0 {
                        rightLabelText = String(expectedDate)
                    }
                    
                }
            }
            cellView.rightLabel?.text = ""
            
            if let name = gameToShow.name {
                let attributedString = NSMutableAttributedString(string: name)
                
                // *** Create instance of `NSMutableParagraphStyle`
                let paragraphStyle = NSMutableParagraphStyle()
                
                // *** set LineSpacing property in points ***
                paragraphStyle.lineSpacing = 4
                
                // *** Apply attribute to string ***
                attributedString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
                
                // *** Set Attributed String to your label ***
                cellView.titleLabel?.attributedText = attributedString
            } else {
                cellView.titleLabel?.text = ""
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
            cellView.descriptionLabel?.text = platformString
            
            // See if we need to load more games
            let rowsToLoadFromBottom = 5;
            let rowsLoaded = games.count
            if (!self.isLoadingGames && (indexPath.row >= (rowsLoaded - rowsToLoadFromBottom))) {
                let totalRows = self.searchResults?.numberOfTotalResults ?? 0
                let remainingGamesToLoad = totalRows - rowsLoaded;
                if (remainingGamesToLoad > 0) {
                    self.loadMoreGames(withQuery: self.query!)
                }
            }
            // this isn't ideal since it will keep running even if the cell scrolls off of the screen
            // if we had lots of cells we'd want to stop this process when the cell gets reused
            let cellViewToUpdate = self.gamesViewControllers[indexPath.row]
            if cellViewToUpdate.imageSource == .Placeholder {

                gameToShow.getImage {
                    result in
                    if let error = result.error {
                        print(error)
                    } else {
                        // Save the image so we won't have to keep fetching it if they scroll
                        if let cellToUpdate = self.tableView?.cellForRow(at: indexPath) {
                            UIView.transition(with: cellViewToUpdate.artView!,
                                                      duration:0.5,
                                                      options: .transitionCrossDissolve,
                                                      animations: { cellViewToUpdate.artView?.image = result.value! },
                                                      completion: nil)
                            cellViewToUpdate.imageSource = .Downloaded
                            cellToUpdate.setNeedsLayout() // need to reload the view, which won't happen otherwise since this is in an async call
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
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.query = searchText
        if !(self.query?.isEmpty)! {
            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                            self.searchTintView?.alpha = 0.0
            },
                           completion: nil)
            games?.removeAll()
            gamesViewControllers.removeAll()
            self.searchLabel?.isHidden = true
            self.searchBackground?.isHidden = true
            self.activityIndicator?.startAnimating()
            self.activityBackground?.isHidden = false
            tableView?.reloadData()
            self.loadFirstGame(withQuery: self.query!)
        } else {
            games?.removeAll()
            gamesViewControllers.removeAll()
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
            tableView?.reloadData()
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

extension LibraryAddSearchViewController: TableViewCellViewDelegate {
    func addTapped(_ row: Int) {
        self.currentlySelectedRow = row
        let gameField = self.games?[row]
        let consoleSelection = ConsoleSelectionTableViewController()
        
        consoleSelection.delegate = self
        for platform in (gameField?.platforms)! {
            let dict: [Int: String] = [platform.idNumber: platform.name!]
            self.platformDict[platform.idNumber] = platform
            consoleSelection.consoles.append(dict)
        }
        self.navigationController?.pushViewController(consoleSelection, animated: true)
        self.currentGameField = gameField
    }
    func removeTapped(_ row: Int) {
        
        let gameField = self.games?[row]
        let gameFieldIdNumber = (gameField?.idNumber)!
        let gameList = self.tempGames[(gameField?.idNumber)!]
        let newGameFieldCopy = (gameField?.deepCopy())!
        for game in gameList! {
            game.delete()
        }
        self.games?[row] = newGameFieldCopy
        self.gamesViewControllers[row].libraryState = .add
        self.tempGames[gameFieldIdNumber]!.removeAll()
        toastOverlay.show(withIcon: #imageLiteral(resourceName: "large_x"), text: "Removed from Library")
    }
}
