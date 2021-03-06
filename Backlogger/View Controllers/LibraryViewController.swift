//
//  LibraryViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift
import Zephyr
import GoogleMobileAds

class LibraryViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var addBackgroundView: UIView?
    
    var isSearching = false
    private var _isAdVisible = false
    var isAdVisible: Bool {
        get {
            return self._isAdVisible
        }
        set(newValue) {
            self._isAdVisible = newValue
            if newValue {
                self.tableView?.contentInset.bottom = self.tableDefaultInset + Util.adContentInset
            } else {
                self.tableView?.contentInset.bottom = self.tableDefaultInset
                self.adBannerView.removeFromSuperview()
            }
        }
    }
    private var tableDefaultInset: CGFloat = 0.0
    
    let tableReuseIdentifier = "table_cell"
    
    var platforms: [Platform] = []
    
    var allGames: Results<Game>?
    
    var filteredGames: Results<Game>?
    
    enum SortType: Int {
        case alphabetical = 0
        case dateAdded = 1
        case releaseYear = 2
        case percentComplete = 3
        case completed = 4
        case rating = 5
    }
    
    var sortType: SortType?
    
    var ascending: Bool?
    
    var adBannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar?.tintColor = Util.appColor
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: tableReuseIdentifier)
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.navigationController?.navigationBar.tintColor = .white
        if Util.shouldShowAds() {
            self.adBannerView = Util.getNewBannerAd(for: self)
            self.isAdVisible = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Util.shouldShowAds() {
            if !self.isAdVisible {
                self.isAdVisible = true
            }
        } else {
            if self.isAdVisible {
                self.isAdVisible = false
            }
        }
        self.refreshCells()
    }
    
    func refreshCells() {
        if Util.isICloudContainerAvailable {
            Zephyr.sync()
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
        autoreleasepool {
            let realm = try! Realm()
            var sortString: String
            let ascending = self.ascending!
            switch self.sortType! {
            case .alphabetical:
                sortString = "gameFields.name"
                self.platforms = Array(realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted(byKeyPath: "name", ascending: ascending))
                break
            case .dateAdded:
                sortString = "dateAdded"
                self.platforms = Array(realm.objects(Platform.self).filter("ownedGames.@count > 0"))
                break
            case .releaseYear:
                sortString = "gameFields.releaseDate"
                self.platforms = Array(realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted(byKeyPath: "releaseDate", ascending: ascending))
                break
            case .percentComplete:
                sortString = "progress"
                self.platforms = realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.progress < p2.progress
                    } else {
                        ret = p1.progress > p2.progress
                    }
                    return ret
                }
                break
            case .completed:
                sortString = "finished"
                self.platforms = realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.finished < p2.finished
                    } else {
                        ret = p1.finished > p2.finished
                    }
                    return ret
                }
                break
            case .rating:
                sortString = "rating"
                self.platforms = realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.rating < p2.rating
                    } else {
                        ret = p1.rating > p2.rating
                    }
                    return ret
                }
                break
            }
            self.allGames = realm.objects(Game.self).sorted(byKeyPath: sortString, ascending: ascending)
            self.filteredGames = self.allGames
        }
        if self.isSearching {
            self.filterContent(for: self.searchBar!.text!)
        }
        self.tableView?.reloadData()

        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])
        if platforms.count > 0 {
            self.addBackgroundView?.isHidden = true
            self.tableView?.isHidden = false
        } else {
            self.addBackgroundView?.isHidden = false
            self.tableView?.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if platforms.count > 0 {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(self.leftBarButtonTapped))
        } else {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func leftBarButtonTapped(sender: UIBarButtonItem) {
        self.searchBar?.resignFirstResponder()
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let alphaAction = UIAlertAction(title: "Title", style: .default, handler: { _ in
            self.ascending = self.sortType == .alphabetical ? !self.ascending! : true
            self.sortType = .alphabetical
            autoreleasepool {
                let realm = try! Realm()
                self.platforms = Array(realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted(byKeyPath: "name", ascending: self.ascending!))
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "gameFields.name", ascending: self.ascending!)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "gameFields.name", ascending: self.ascending!)
            }
            UserDefaults.standard.set(self.ascending!, forKey: "libraryAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let dateAction = UIAlertAction(title: "Recently Added", style: .default, handler: { _ in
            self.ascending = self.sortType == .dateAdded ? !self.ascending! : false
            self.sortType = .dateAdded
            autoreleasepool {
                let realm = try! Realm()
                self.platforms = Array(realm.objects(Platform.self).filter("ownedGames.@count > 0"))
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "dateAdded", ascending: self.ascending!)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "dateAdded", ascending: self.ascending!)
            }
            UserDefaults.standard.set(self.ascending!, forKey: "libraryAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let releaseAction = UIAlertAction(title: "Release Date", style: .default, handler: { _ in
            self.ascending = self.sortType == .releaseYear ? !self.ascending! : true
            self.sortType = .releaseYear
            autoreleasepool {
                let realm = try! Realm()
                self.platforms = Array(realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted(byKeyPath: "releaseDate", ascending: self.ascending!))
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "gameFields.releaseDate", ascending: self.ascending!)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "gameFields.releaseDate", ascending: self.ascending!)
            }
            UserDefaults.standard.set(self.ascending!, forKey: "libraryAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let percentAction = UIAlertAction(title: "Progress", style: .default, handler: { _ in
            self.ascending = self.sortType == .percentComplete ? !self.ascending! : true
            self.sortType = .percentComplete
            autoreleasepool {
                let realm = try! Realm()
                self.platforms = realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.progress < p2.progress
                    } else {
                        ret = p1.progress > p2.progress
                    }
                    return ret
                }
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "progress", ascending: self.ascending!)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "progress", ascending: self.ascending!)
            }
            UserDefaults.standard.set(self.ascending!, forKey: "libraryAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let completeAction = UIAlertAction(title: "Finished", style: .default, handler: { _ in
            self.ascending = self.sortType == .completed ? !self.ascending! : true
            self.sortType = .completed
            autoreleasepool {
                let realm = try! Realm()
                self.platforms = realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.finished < p2.finished
                    } else {
                        ret = p1.finished > p2.finished
                    }
                    return ret
                }
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "finished", ascending: self.ascending!)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "finished", ascending: self.ascending!)
            }
            UserDefaults.standard.set(self.ascending!, forKey: "libraryAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        
        let ratingAction = UIAlertAction(title: "Rating", style: .default, handler: { _ in
            self.ascending = self.sortType == .rating ? !self.ascending! : true
            self.sortType = .rating
            autoreleasepool {
                let realm = try! Realm()
                self.platforms = realm.objects(Platform.self).filter("ownedGames.@count > 0").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.rating < p2.rating
                    } else {
                        ret = p1.rating > p2.rating
                    }
                    return ret
                }
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "rating", ascending: self.ascending!)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "rating", ascending: self.ascending!)
            }
            UserDefaults.standard.set(self.ascending!, forKey: "libraryAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
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
        actions.popoverPresentationController?.barButtonItem = self.navigationController?.navigationBar.topItem?.leftBarButtonItem
        self.present(actions, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        let identifier = segue.identifier
        if identifier == "table_game_list" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameTableViewController
                vc.platform = self.platforms[i]
            }
        }
        else if identifier == "add_game_to_library" {
            let rootVc = segue.destination as? UINavigationController
            let vc = rootVc?.viewControllers.first as? LibraryAddSearchViewController
            vc?.delegate = self
        }
    }
    
    func addGame() {
        self.performSegue(withIdentifier: "add_show_details", sender: nil)
    }
    
    func addAdView(_ banner: GADBannerView) {
        if banner.superview == nil {
            banner.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(banner)
            
            banner.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            banner.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        }
    }
}

extension LibraryViewController: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        if let navView = self.navigationController?.view {
            Util.showBannerAd(in: navView, banner: self.adBannerView)
        }
    }
}

extension LibraryViewController: LibraryAddSearchViewControllerDelegate {
    func didDismiss() {
        self.refreshCells()
    }
}

extension LibraryViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        self.isSearching = false
        searchBar.resignFirstResponder()
        self.tableView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if searchBar.text! == "" {
            self.isSearching = false
            self.tableView?.reloadData()
        } else {
            self.filterContent(for: searchBar.text!)
        }
        /*if self.bottomActivity!.isAnimating {
            self.bottomActivity?.stopAnimating()
        }
        self.gameCountLabel?.text = "\(self.filteredGames!.count) games found."
        if self.gameCountLabel!.isHidden {
            self.gameCountLabel?.isHidden = false
        }*/
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.isSearching = false
            self.tableView?.reloadData()
        } else {
            self.isSearching = true
            self.filterContent(for: searchText)
        }
    }
 
    func filterContent(for searchText: String) {
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
        if searchText != "" {
            self.filteredGames = allGames!.filter("gameFields.name contains[c] %@", searchText.replacingOccurrences(of: "’", with: "\'")).sorted(byKeyPath: sortString, ascending: self.ascending!)
        } else {
            self.filteredGames = allGames?.sorted(byKeyPath: sortString)
        }
        self.tableView?.reloadData()
    }
}

extension LibraryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !self.isSearching {
            return self.platforms.count
        } else {
            return self.filteredGames?.count ?? 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        cell.row = indexPath.row
        cell.accessoryType = .disclosureIndicator
        
        var indent: CGFloat = 0.0
        if indexPath.row < self.platforms.count - 1 {
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
        
        if !self.isSearching {
            let platform = self.platforms[indexPath.row]
            cell.titleLabel?.text = platform.name ?? ""
            cell.percentView?.isHidden = true
            cell.rightLabel?.text = "\(platform.ownedGames.count)"
            
            if !platform.hasDetails && !platform.custom {
                platform.updateDetails { results in
                    if let error = results.error {
                        cell.descriptionLabel?.text = ""
                        cell.set(image: #imageLiteral(resourceName: "table_placeholder_light"))
                        NSLog("\(error.localizedDescription)")
                    } else {
                        if let companyName = platform.company?.name {
                            cell.descriptionLabel?.text = companyName
                            cell.showDetails()
                        } else {
                            cell.descriptionLabel?.text = ""
                            cell.hideDetails()
                        }
                        if let image = platform.image, !image.isDefaultPlaceholder(field: .IconUrl) {
                            cell.imageUrl = URL(string: image.iconUrl!)
                        } else {
                            cell.set(image: #imageLiteral(resourceName: "table_placeholder_light"))
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
                                NSLog("Error \(error)")
                            }
                            
                        }
                        cell.setNeedsLayout()
                    }
                }
            } else {
                if let companyName = platform.company?.name {
                    cell.descriptionLabel?.text = companyName
                    cell.showDetails()
                } else {
                    cell.descriptionLabel?.text = ""
                    cell.hideDetails()
                }
                
                if platform.idNumber != Steam.steamPlatformIdNumber {
                    if let image = platform.image, !image.isDefaultPlaceholder(field: .IconUrl) {
                        cell.imageUrl = URL(string: image.iconUrl!)
                    } else {
                        cell.set(image: #imageLiteral(resourceName: "table_placeholder_light"))
                    }
                    cell.cacheCompletionHandler = {
                        result in
                        switch result {
                        case .success(let value):
                            if value.cacheType == .none || value.cacheType == .disk {
                                UIView.transition(with: cell.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                    cell.set(image: value.image)
                                }, completion: nil)
                            } else {
                                cell.set(image: value.image)
                            }
                        case .failure(let error):
                            NSLog("Error: \(error)")
                        }
                    }
                } else {
                    cell.imageUrl = nil
                    cell.set(image: #imageLiteral(resourceName: "steam_logo"))
                }
            }
        } else {
            let game = self.filteredGames![indexPath.row]
            cell.titleLabel?.text = game.gameFields!.name
            cell.descriptionLabel?.text = game.platform!.name
            cell.showDetails()
            cell.percentView?.isHidden = true
            cell.rightLabel?.text = ""
            if let image = game.gameFields!.image, !image.isDefaultPlaceholder(field: .IconUrl) {
                cell.imageUrl = URL(string: image.iconUrl!)
            }
            cell.cacheCompletionHandler = {
                result in
                switch result {
                case .success(let value):
                    if value.cacheType == .none || value.cacheType == .disk {
                        UIView.transition(with: cell.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                            cell.set(image: value.image)
                        }, completion: nil)
                    } else {
                        cell.set(image: value.image)
                    }
                case .failure(let error):
                    NSLog("Error: \(error)")
                }
            }
        }
        
        cell.setNeedsLayout()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath) as! TableViewCell
        if !self.isSearching {
            self.searchBar?.resignFirstResponder()
            self.performSegue(withIdentifier: "table_game_list", sender: cell)
        } else {
            self.searchBar?.resignFirstResponder()
            let vc: GameDetailsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "game_details") as! GameDetailsViewController
            let game = self.filteredGames![indexPath.row]
            let gameField = game.gameFields!
            
            vc.state = .inLibrary
            vc.gameField = gameField
            vc.game = game
            self.navigationController?.navigationBar.tintColor = .white
            self.navigationController?.pushViewController(vc, animated: true)
            
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar?.resignFirstResponder()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
