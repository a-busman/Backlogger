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
}

class AddToPlaylistViewController: UITableViewController, TableViewCellDelegate {
    
    var allGames: Results<Game>?
    var filteredGames: Results<Game>?
    var addedGames = List<Game>()
    var query = ""
    var delegate: AddToPlaylistViewControllerDelegate?
    let reuseIdentifier = "table_cell"
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.reuseIdentifier)
        autoreleasepool {
            let realm = try! Realm()
            self.allGames = realm.objects(Game.self)
            self.filteredGames = self.allGames
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func cancelTapped(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        self.delegate?.didChoose(games: self.addedGames)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredGames?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! TableViewCell
        if cell.libraryState == .addPlaylist {
            cell.libraryState = .inPlaylist
            self.addTapped(indexPath.row)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TableViewCell
        cell.addButtonHidden = false

        cell.selectionStyle = .none
        
        var indent: CGFloat = 0.0
        if indexPath.row < self.filteredGames!.count - 1 {
            indent = 67.0
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
        

        if let game = self.filteredGames?[indexPath.row] {
            if self.addedGames.contains(game) {
                cell.libraryState = .inPlaylist
            } else {
                cell.libraryState = .addPlaylist
            }
            cell.titleLabel?.text = (game.gameFields?.name)!
            cell.descriptionLabel?.text = (game.platform?.name)!
            cell.rightLabel?.text = ""
            
            // this isn't ideal since it will keep running even if the cell scrolls off of the screen
            // if we had lots of cells we'd want to stop this process when the cell gets reused
            if let gameField = game.gameFields {
                if let image = gameField.image {
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
        }
        
        return cell
    }
    
    func addTapped(_ row: Int) {
        self.addedGames.append(self.filteredGames![row])
    }
}
