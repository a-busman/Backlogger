//
//  WishlistViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 9/3/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class WishlistViewController: UIViewController {
    @IBOutlet weak var tableView:   UITableView?
    @IBOutlet weak var noGamesView: UIView?
    @IBOutlet weak var rightBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var leftBarButtonItem:  UIBarButtonItem?
    
    let reuseString = "table_cell"
    
    var wishlistGames: Results<Game>?
    
    var isInEditing: Bool = false
    
    var selected: [Int: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.reuseString)
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshCells()
    }
    
    func refreshCells() {
        autoreleasepool {
            let realm = try? Realm()
            self.wishlistGames = realm?.objects(Game.self).filter("inWishlist = true").sorted(byKeyPath: "dateAdded", ascending: false)
        }
        if self.wishlistGames?.count ?? 0 == 0 {
            self.leftBarButtonItem?.isEnabled = false
            self.noGamesView?.isHidden = false
        }
        self.selected = [:]
        self.tableView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func rightTapped(sender: UIBarButtonItem) {
        if !self.isInEditing {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.tableView?.setEditing(false, animated: false)
            self.leftBarButtonItem?.title = "Edit"
            self.rightBarButtonItem?.title = "Done"
            self.rightBarButtonItem?.style = .done
            self.leftBarButtonItem?.isEnabled = true
            self.isInEditing = false
        }
    }
    
    @IBAction func leftTapped(sender: UIBarButtonItem) {
        if !self.isInEditing {
            self.tableView?.setEditing(true, animated: true)
            self.leftBarButtonItem?.title = "Delete"
            self.leftBarButtonItem?.isEnabled = false
            self.rightBarButtonItem?.title = "Cancel"
            self.rightBarButtonItem?.style = .plain
            self.selected = [:]
            self.isInEditing = true
        } else {
            var indexPaths: [IndexPath] = []
            for (k, uuid) in self.selected {
                indexPaths.append(IndexPath(row: k, section: 0))
                autoreleasepool {
                    let realm = try? Realm()
                    let game = realm?.object(ofType: Game.self, forPrimaryKey: uuid)
                    game?.delete()
                }
            }
            autoreleasepool {
                let realm = try? Realm()
                self.wishlistGames = realm?.objects(Game.self).filter("inWishlist = true").sorted(byKeyPath: "dateAdded", ascending: false)
            }
            self.selected = [:]
            self.leftBarButtonItem?.title = "Delete"
            self.leftBarButtonItem?.isEnabled = false
            self.tableView?.deleteRows(at: indexPaths, with: .automatic)
            if self.wishlistGames?.count ?? 0 == 0 {
                self.noGamesView?.alpha = 0.0
                self.noGamesView?.isHidden = false
                UIView.animate(withDuration: 0.4, animations: {
                    self.noGamesView?.alpha = 1.0
                    self.leftBarButtonItem?.isEnabled = false
                })
                self.tableView?.setEditing(false, animated: false)
                self.leftBarButtonItem?.title = "Edit"
                self.rightBarButtonItem?.title = "Done"
                self.rightBarButtonItem?.style = .done
                self.leftBarButtonItem?.isEnabled = false
                self.isInEditing = false
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "wishlist_show_details" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameDetailsViewController
                
                vc.gameField = self.wishlistGames![i].gameFields
                vc.game = self.wishlistGames![i]
                vc.state = .addToLibrary
            }
        }
    }
}

extension WishlistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.isInEditing {
            self.selected[indexPath.row] = self.wishlistGames?[indexPath.row].uuid ?? ""
            self.leftBarButtonItem?.isEnabled = true
            self.leftBarButtonItem?.title = "Delete (\(self.selected.count))"
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            self.performSegue(withIdentifier: "wishlist_show_details", sender: tableView.cellForRow(at: indexPath))

        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if self.isInEditing {
            self.selected.removeValue(forKey: indexPath.row)
            if self.selected.count > 0 {
                self.leftBarButtonItem?.isEnabled = true
                self.leftBarButtonItem?.title = "Delete (\(self.selected.count))"
            } else {
                self.leftBarButtonItem?.isEnabled = false
                self.leftBarButtonItem?.title = "Delete"
            }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.wishlistGames?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseString) as! TableViewCell
        if let game = self.wishlistGames?[indexPath.row] {
            var indent: CGFloat = 0.0
            
            if indexPath.row < self.wishlistGames!.count - 1 {
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
            cell.descriptionLabel?.text = game.platform?.name
            cell.showDetails()
            cell.isWishlist = false
            cell.percentView?.isHidden = true
            cell.rightLabel?.isHidden = true
            cell.accessoryType = .disclosureIndicator

            if let image = game.gameFields?.image, !image.isDefaultPlaceholder(field: .IconUrl) {
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
            let game = self.wishlistGames![indexPath.row]
            game.delete()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            if self.wishlistGames?.count ?? 0 == 0 {
                self.noGamesView?.alpha = 0.0
                self.noGamesView?.isHidden = false
                UIView.animate(withDuration: 0.4, animations: {
                    self.noGamesView?.alpha = 1.0
                    self.leftBarButtonItem?.isEnabled = false
                })
            }
        }
    }
}
