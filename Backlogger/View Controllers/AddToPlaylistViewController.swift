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

class AddToPlaylistViewController: UITableViewController, TableViewCellViewDelegate {
    
    var allGames: Results<Game>?
    var filteredGames: Results<Game>?
    var addedGames = List<Game>()
    var query = ""
    var delegate: AddToPlaylistViewControllerDelegate?
    let reuseIdentifier = "add_to_cell"
    var gamesViewControllers: [TableViewCellView] = [TableViewCellView]()
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView.register(TableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
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
        if self.gamesViewControllers[indexPath.row].libraryState == .addPlaylist {
            self.gamesViewControllers[indexPath.row].libraryState = .inPlaylist
            self.addTapped(indexPath.row)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TableViewCell

        var cellView: TableViewCellView
        if indexPath.row + 1 > gamesViewControllers.count {
            cellView = TableViewCellView(indexPath.row)
            cellView.addButtonHidden = false
            cellView.libraryState = .addPlaylist
            cellView.delegate = self
            self.gamesViewControllers.append(cellView)
        } else {
            cellView = self.gamesViewControllers[indexPath.row]
        }
        cellView.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(cellView.view)
        let lineView = UIView()
        lineView.backgroundColor = .lightGray
        lineView.translatesAutoresizingMaskIntoConstraints = false
        cellView.view.addSubview(lineView)
        
        if indexPath.row == self.filteredGames!.count - 1 {
            NSLayoutConstraint(item: lineView,
                               attribute: .leading,
                               relatedBy: .equal,
                               toItem: cellView.view,
                               attribute: .leading,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
        } else {
            NSLayoutConstraint(item: lineView,
                               attribute: .leading,
                               relatedBy: .equal,
                               toItem: cellView.titleLabel,
                               attribute: .leading,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
        }
        NSLayoutConstraint(item: lineView,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: cellView.view,
                           attribute: .trailing,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: lineView,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: cellView.view,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: -0.5
            ).isActive = true
        NSLayoutConstraint(item: lineView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: cellView.view,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        
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
        if let game = self.filteredGames?[indexPath.row] {
            cellView.titleLabel?.text = (game.gameFields?.name)!
            cellView.descriptionLabel?.text = (game.platform?.name)!
            cellView.rightLabel?.text = ""
            
            // this isn't ideal since it will keep running even if the cell scrolls off of the screen
            // if we had lots of cells we'd want to stop this process when the cell gets reused
            if let gameField = game.gameFields {
                if cellView.imageSource == .Placeholder {                    
                    if let image = gameField.image {
                        cellView.imageUrl = URL(string: image.iconUrl!)
                    }
                    cellView.cacheCompletionHandler = {
                        (image, error, cacheType, imageUrl) in
                        if image != nil {
                            if cacheType == .none {
                                UIView.transition(with: cellView.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                    cellView.set(image: image!)
                                }, completion: nil)
                            } else {
                                cellView.set(image: image!)
                            }
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
