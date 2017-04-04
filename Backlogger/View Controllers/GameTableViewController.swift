//
//  GameTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class GameTableViewController: UIViewController, GameDetailsViewControllerDelegate {
    
    @IBOutlet weak var tableView:     UITableView?
    @IBOutlet weak var headerView:    UIVisualEffectView?
    @IBOutlet weak var yearLabel:     UILabel?
    @IBOutlet weak var titleLabel:    UILabel?
    @IBOutlet weak var platformImage: UIImageView?
    @IBOutlet weak var shadowView:    UIView?
    
    @IBOutlet weak var headerHeightConstraint:         NSLayoutConstraint?
    @IBOutlet weak var platformImageLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var platformImageTopConstraint:     NSLayoutConstraint?
    @IBOutlet weak var platformImageBottomConstraint:  NSLayoutConstraint?
    
    var games: [Game] = []
    
    var platform: Platform?
    
    var currentlySelectedRow = 0
    
    fileprivate var didLayout = false
    
    fileprivate let headerMaxHeight:      CGFloat = 165.0
    fileprivate let headerMinHeight:      CGFloat = 80.0
    fileprivate let platformMaxMargin:    CGFloat = 20.0
    fileprivate let platformMinMargin:    CGFloat = 10.0
    fileprivate let startInset:           CGFloat = 229.0
    fileprivate var headerTravelDistance: CGFloat = 0.0
    fileprivate var insetToHeader:        CGFloat = 0.0
    
    fileprivate let tableReuseIdentifier = "game_cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shadowView?.layer.shadowOpacity = 0.8
        self.shadowView?.layer.shadowRadius = 5.0
        self.shadowView?.layer.shadowColor = UIColor.black.cgColor
        //self.shadowView?.layer.shadowPath = UIBezierPath(rect: (self.shadowView?.bounds)!).cgPath
        self.shadowView?.layer.shadowOffset = CGSize.zero
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.headerTravelDistance = self.headerMaxHeight - self.headerMinHeight
        self.insetToHeader = startInset - headerMaxHeight
        if let platform = self.platform {
            self.titleLabel?.text = platform.name
            self.games = Array(platform.ownedGames)

            if let releaseDate = platform.releaseDate {
                let index = releaseDate.index(releaseDate.startIndex, offsetBy: 4)
                self.yearLabel?.text = "\(platform.company?.name ?? "") • \(releaseDate.substring(to: index))"
            } else {
                self.yearLabel?.text = "\(platform.company?.name ?? "")"
            }
            
            platform.image?.getImage(field: .MediumUrl, { result in
                if let error = result.error {
                    NSLog("\(error.localizedDescription)")
                    return
                }
                UIView.transition(with: self.platformImage!,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.platformImage?.image = result.value! },
                                  completion: nil)
            })
        } else {
            NSLog("No platform during load")
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.games = Array((self.platform?.ownedGames)!)
        self.tableView?.reloadData()
        if self.games.count < 1 {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView?.contentInset.top = self.startInset
        self.tableView?.scrollIndicatorInsets.top = self.startInset
        self.didLayout = true
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
                
                self.currentlySelectedRow = i
                
                //self.searchBar?.resignFirstResponder()
                
                vc.gameField = self.games[i].gameFields
                vc.game = self.games[i]
                vc.state = .inLibrary
                vc.delegate = self
            }
        }
    }
    func gamesCreated(gameField: GameField) {
        /*if games.count == 1 {
            self.games[self.currentlySelectedRow] = games.first!
        } else {
            self.games.remove(at: self.currentlySelectedRow)
        }*/
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
        let index = game.gameFields?.releaseDate?.index((game.gameFields?.releaseDate?.startIndex)!, offsetBy: 4)
        cellView.descriptionLabel?.text = game.gameFields?.releaseDate?.substring(to: index!)
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.didLayout {
            let offset = scrollView.contentOffset.y * -1.0
            if offset < self.startInset {
                if offset > (self.startInset - self.headerTravelDistance) {
                    let offsetPercentage = (offset - (self.startInset - self.headerTravelDistance)) / self.headerTravelDistance
                    let imageMargin = (offsetPercentage * self.platformMinMargin) + self.platformMinMargin
                    self.headerHeightConstraint?.constant = offset - insetToHeader
                    self.platformImageTopConstraint?.constant = imageMargin
                    self.platformImageBottomConstraint?.constant = imageMargin * -1.0
                    self.platformImageLeadingConstraint?.constant = imageMargin
                } else {
                    self.headerHeightConstraint?.constant = headerMinHeight
                    self.platformImageTopConstraint?.constant = self.platformMinMargin
                    self.platformImageBottomConstraint?.constant = self.platformMinMargin * -1.0
                    self.platformImageLeadingConstraint?.constant = self.platformMinMargin
                    
                }
            } else {
                self.headerHeightConstraint?.constant = headerMaxHeight
                self.platformImageTopConstraint?.constant = self.platformMaxMargin
                self.platformImageBottomConstraint?.constant = self.platformMaxMargin * -1.0
                self.platformImageLeadingConstraint?.constant = self.platformMaxMargin
            }
            //self.headerView?.layoutIfNeeded()
        }
    }
}
