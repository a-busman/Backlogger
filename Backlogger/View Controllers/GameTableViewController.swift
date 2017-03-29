//
//  GameTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class GameTableViewController: UIViewController, GameDetailsViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView?
    
    var games: [Game] = []
    
    var currentlySelectedRow = 0
    
    let tableReuseIdentifier = "game_cell"
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        tableView?.tableFooterView = UIView(frame: .zero)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if games.count < 1 {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
        self.tableView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "library_show_details" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameDetailsViewController
                var stringList = [String]()
                let gameList = [self.games[i]]
                
                self.currentlySelectedRow = i
                for game in gameList {
                    stringList.append(game.uuid)
                }
                
                //self.searchBar?.resignFirstResponder()
                
                vc.stringsToFetch = stringList
                vc.gameFieldId = self.games[i].gameFields?.idNumber
                vc.gameField = self.games[i].gameFields
                vc.state = .inLibrary
                vc.delegate = self
            }
        }
    }
    func gamesCreated(gameField: GameField, games: [Game]) {
        self.games = games
    }
}

extension GameTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        let cellView = TableViewCellView()
        let game = self.games[indexPath.row]
        cellView.addButtonHidden = true
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
        cell.backgroundColor = (indexPath.item % 2) == 1 ? UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) : .white
        cellView.titleLabel?.text = game.gameFields?.name
        cellView.descriptionLabel?.text = game.gameFields?.releaseDate
        cellView.rightLabel?.text = "\(game.progress)%"
        if cellView.imageSource == .Placeholder {
            cellView.artView?.image = (indexPath.item % 2) == 1 ? #imageLiteral(resourceName: "table_placeholder_dark") : #imageLiteral(resourceName: "table_placeholder_light")
            game.gameFields?.getImage {
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let game = games.remove(at: indexPath.row)
            game.delete()
            self.tableView?.deleteRows(at: [indexPath], with: .automatic)
            if games.count < 1 {
                let _ = self.navigationController?.popViewController(animated: true)
            }
            self.tableView?.reloadData()
        }
    }
}
