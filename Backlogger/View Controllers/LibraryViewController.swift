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
    var tableSearchBar: UISearchBar?
    @IBOutlet weak var addBackgroundView: UIView?
    
    var isSearching = false
    
    let tableReuseIdentifier = "console_table_cell"
    
    var platforms: Results<Platform>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableSearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        self.tableSearchBar?.tintColor = .white
        self.tableSearchBar?.placeholder = "Library"
        self.tableSearchBar?.delegate = self
        self.tableView?.tableHeaderView = self.tableSearchBar
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
        //var contentOffset = (self.tableView?.contentOffset)!
        //if contentOffset.y == 0 {
        //    contentOffset.y = (self.tableView?.tableHeaderView?.frame)!.height
        //}
        //self.tableView?.contentOffset = contentOffset
        //self.tableView?.contentInset.top = 64
        //self.tableView?.contentInset.bottom = 40
    }
    
    @IBAction func leftBarButtonTapped(sender: UIBarButtonItem) {
        self.tableSearchBar?.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "table_game_list" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameTableViewController
                vc.title = self.platforms?[i].name
                vc.games = Array((self.platforms?[i].ownedGames)!)
            }
        }
    }
    
    func addGame() {
        self.performSegue(withIdentifier: "add_show_details", sender: nil)
    }
}

extension LibraryViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

    }
    
}

extension LibraryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.platforms?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier)!
        let cellView = TableViewCellView()
        let platform = self.platforms![indexPath.row]
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
        
        if !self.isSearching {
            cellView.titleLabel?.text = platform.name ?? ""
            cellView.descriptionLabel?.text = platform.company?.name ?? ""
            cellView.rightLabel?.text = "\(platform.ownedGames.count)"
            
            if cellView.imageSource == .Placeholder {
                cellView.artView?.image = (indexPath.item % 2) == 1 ? #imageLiteral(resourceName: "table_placeholder_dark") : #imageLiteral(resourceName: "table_placeholder_light")
                platform.image?.getImage(field: .IconUrl) {
                    result in
                    if let error = result.error {
                        print(error)
                    } else {
                        // Save the image so we won't have to keep fetching it if they scroll
                        if let cellToUpdate = self.tableView?.cellForRow(at: indexPath) {
                            UIView.transition(with: cellView.artView!,
                                              duration:0.5,
                                              options: .transitionCrossDissolve,
                                              animations: { cellView.artView?.image = result.value! },
                                              completion: nil)
                            cellView.imageSource = .Downloaded
                            cellToUpdate.setNeedsLayout() // need to reload the view, which won't happen otherwise since this is in an async call
                        }
                    }
                }
            }
        } else {
            
        }
        
        cell.backgroundColor = (indexPath.item % 2) == 1 ? UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) : .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
