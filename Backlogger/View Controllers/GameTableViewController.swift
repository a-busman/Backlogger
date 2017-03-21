//
//  GameTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class GameTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    
    var games: [Game] = [
    ]
    var consoles: [Console] = [Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo"))]
    
    let tableReuseIdentifier = "game_cell"
    var count = 6
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        tableView?.tableFooterView = UIView(frame: .zero)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension GameTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        let cellView = TableViewCellView()
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
        cell.backgroundColor = (indexPath.item % 2) == (self.games.count % 2 == 0 ? 1 : 0) ? UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) : .white
        
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
            count = count - 1
            self.tableView?.deleteRows(at: [indexPath], with: .automatic)
            self.tableView?.reloadData()
        }
    }
}
