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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar?.tintColor = Util.appColor
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: tableReuseIdentifier)
        self.tableView?.tableFooterView = UIView(frame: .zero)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView?.reloadData()
        autoreleasepool {
            let realm = try? Realm()
            self.platforms = realm?.objects(Platform.self).filter("ownedGames.@count > 0")
        }
        if (platforms?.count ?? 0) > 0 {
            self.addBackgroundView?.isHidden = true
            self.tableView?.isHidden = false
        } else {
            self.addBackgroundView?.isHidden = false
            self.tableView?.isHidden = true
            
        }
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        //self.tableView?.contentInset.top = 165
        //self.tableView?.contentInset.bottom = 40
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func leftBarButtonTapped(sender: UIBarButtonItem) {
        self.searchBar?.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "table_game_list" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameTableViewController
                //vc.title = self.platforms?[i].name
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
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        /*self.filterContent(for: searchBar.text!)
        if self.bottomActivity!.isAnimating {
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
        /*self.filterContent(for: searchText)
        if self.bottomActivity!.isAnimating {
            self.bottomActivity?.stopAnimating()
        }
        self.gameCountLabel?.text = "\(self.filteredGames!.count) games found."
        if self.gameCountLabel!.isHidden {
            self.gameCountLabel?.isHidden = false
        }*/
    }
}

extension LibraryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.platforms?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        let platform = self.platforms![indexPath.row]
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
            cell.titleLabel?.text = platform.name ?? ""
            cell.descriptionLabel?.text = platform.company?.name ?? ""
            cell.rightLabel?.text = "\(platform.ownedGames.count)"
            
            if let image = platform.image {
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
        } else {
            
        }
        
        cell.setNeedsLayout()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "table_game_list", sender: tableView.cellForRow(at: indexPath))
    }
}
