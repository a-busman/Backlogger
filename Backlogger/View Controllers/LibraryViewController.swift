//
//  LibraryViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class LibraryViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var addBackgroundView: UIView?
    
    var isSearching = false
    
    let tableReuseIdentifier = "table_cell"
    
    var platforms: Results<Platform>?
    
    var allGames: Results<Game>?
    
    var filteredGames: Results<Game>?
    
    enum SortType: Int {
        case alphabetical = 0
        case dateAdded = 1
    }
    
    var sortType: SortType?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchBar?.tintColor = Util.appColor
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: tableReuseIdentifier)
        self.tableView?.tableFooterView = UIView(frame: .zero)
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
        self.tableView?.reloadData()
        autoreleasepool {
            let realm = try? Realm()
            var sortString: String
            var ascending: Bool
            switch self.sortType! {
            case .alphabetical:
                sortString = "gameFields.name"
                ascending = true
                self.platforms = realm?.objects(Platform.self).filter("ownedGames.@count > 0").sorted(byKeyPath: "name", ascending: ascending)
                break
            case .dateAdded:
                sortString = "dateAdded"
                ascending = false
                self.platforms = realm?.objects(Platform.self).filter("ownedGames.@count > 0")
                break
            }
            self.allGames = realm?.objects(Game.self).sorted(byKeyPath: sortString, ascending: ascending)
            self.filteredGames = self.allGames
        }
        if self.isSearching {
            self.filterContent(for: self.searchBar!.text!)
        }
        if (platforms?.count ?? 0) > 0 {
            self.addBackgroundView?.isHidden = true
            self.tableView?.isHidden = false
        } else {
            self.addBackgroundView?.isHidden = false
            self.tableView?.isHidden = true
        }
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func leftBarButtonTapped(sender: UIBarButtonItem) {
        self.searchBar?.resignFirstResponder()
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let alphaAction = UIAlertAction(title: "Alphabetical", style: .default, handler: { _ in
            self.sortType = .alphabetical
            if self.platforms != nil {
                self.platforms = self.platforms!.sorted(byKeyPath: "name", ascending: true)
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "gameFields.name", ascending: true)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "gameFields.name", ascending: true)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let dateAction = UIAlertAction(title: "Recently Added", style: .default, handler: { _ in
            self.sortType = .dateAdded
            autoreleasepool {
                let realm = try? Realm()
                self.platforms = realm?.objects(Platform.self).filter("ownedGames.@count > 0")
            }
            if self.allGames != nil {
                self.allGames = self.allGames!.sorted(byKeyPath: "dateAdded", ascending: false)
            }
            if self.filteredGames != nil {
                self.filteredGames = self.filteredGames!.sorted(byKeyPath: "dateAdded", ascending: false)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        
        switch self.sortType! {
        case .alphabetical:
            alphaAction.setValue(true, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            break
        case .dateAdded:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(true, forKey: "checked")
            break
        }
        actions.addAction(alphaAction)
        actions.addAction(dateAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "table_game_list" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameTableViewController
                vc.platform = self.platforms?[i]
            }
        }
    }
    
    func addGame() {
        self.performSegue(withIdentifier: "add_show_details", sender: nil)
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
        var ascending: Bool
        switch self.sortType! {
        case .alphabetical:
            sortString = "gameFields.name"
            ascending = true
            break
        case .dateAdded:
            sortString = "dateAdded"
            ascending = false
        }
        if searchText != "" {
            self.filteredGames = allGames!.filter("gameFields.name contains[c] \"\(searchText)\"").sorted(byKeyPath: sortString, ascending: ascending)
        } else {
            self.filteredGames = allGames?.sorted(byKeyPath: sortString)
        }
        self.tableView?.reloadData()
    }
}

extension LibraryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !self.isSearching {
            return self.platforms?.count ?? 0
        } else {
            return self.filteredGames?.count ?? 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        cell.row = indexPath.row
        cell.accessoryType = .disclosureIndicator
        
        var indent: CGFloat = 0.0
        if indexPath.row < self.platforms!.count - 1 {
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
        
        if !self.isSearching {
            let platform = self.platforms![indexPath.row]
            cell.titleLabel?.text = platform.name ?? ""
            cell.descriptionLabel?.text = platform.company?.name ?? ""
            cell.rightLabel?.text = "\(platform.ownedGames.count)"
            
            if let image = platform.image {
                cell.imageUrl = URL(string: image.iconUrl!)
            } else {
                cell.set(image: #imageLiteral(resourceName: "table_placeholder_light"))
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
        } else {
            let game = self.filteredGames![indexPath.row]
            cell.titleLabel?.text = game.gameFields!.name
            cell.descriptionLabel?.text = game.platform!.name
            cell.rightLabel?.text = ""
            if let image = game.gameFields!.image {
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
