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
    @IBOutlet weak var headerView:    UIView?
    @IBOutlet weak var platformImage: UIImageView?
    @IBOutlet weak var titleLabel:    UILabel?
    @IBOutlet weak var shadowView:    UIView?
    
    @IBOutlet weak var shadowBottomLayoutConstraint:  NSLayoutConstraint?
    @IBOutlet weak var titleBottomLayoutConstraint:   NSLayoutConstraint?
    @IBOutlet weak var backgroundTopLayoutConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageTopLayoutConstraint:      NSLayoutConstraint?
    @IBOutlet weak var imageHeightLayoutConstraint:   NSLayoutConstraint?
    
    let shadowGradientLayer = CAGradientLayer()
    
    var games: [Game] = []
    
    var platform: Platform?
    
    var currentlySelectedRow = 0
    
    fileprivate var didLayout = false
    
    fileprivate let titleBottomInitial:   CGFloat = -10.0
    fileprivate let shadowBottomInitial:  CGFloat = 0.0
    fileprivate let imageHeightInitial:   CGFloat = 165.0
    fileprivate let imageTopInitial:      CGFloat = 0.0
    fileprivate let backgroundTopInitial: CGFloat = 165.0
    
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
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.headerTravelDistance = self.headerMaxHeight - self.headerMinHeight
        self.insetToHeader = startInset - headerMaxHeight
        if let platform = self.platform {
            self.titleLabel?.text = platform.name
            self.games = Array(platform.ownedGames)
            if platform.name!.characters.count < 10 {
                self.title = platform.name
            } else {
                self.title = platform.abbreviation
            }
//            if let releaseDate = platform.releaseDate {
//                let index = releaseDate.index(releaseDate.startIndex, offsetBy: 4)
//                self.yearLabel?.text = "\(platform.company?.name ?? "") • \(releaseDate.substring(to: index))"
//            } else {
//                self.yearLabel?.text = "\(platform.company?.name ?? "")"
//            }
            if let superUrl = platform.image?.superUrl {
                self.platformImage?.kf.setImage(with: URL(string: superUrl), placeholder: nil, completionHandler: {
                    (image, error, cacheType, imageUrl) in
                    if image != nil {
                        if cacheType == .none {
                            UIView.transition(with: self.platformImage!,
                                              duration:0.5,
                                              options: .transitionCrossDissolve,
                                              animations: { self.platformImage?.image = image },
                                              completion: nil)
                        } else {
                            self.platformImage?.image = image
                        }
                    }
                })
            } else {
                self.platformImage?.image = nil
            }
        } else {
            NSLog("No platform during load")
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.games = Array((self.platform?.ownedGames)!)
        self.tableView?.reloadData()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.clear]
        if self.games.count < 1 {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !self.didLayout {
            self.shadowGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: (self.shadowView?.frame.width)!, height: (self.shadowView?.frame.height)!)
            let darkColor = UIColor(white: 0.0, alpha: 0.3).cgColor
            self.shadowGradientLayer.colors = [UIColor.clear.cgColor, darkColor]
            self.shadowGradientLayer.locations = [0.7, 1.0]
            self.tableView?.contentInset.top = self.startInset
            self.tableView?.contentInset.bottom = 49.0
            self.tableView?.scrollIndicatorInsets.top = self.startInset
            self.tableView?.scrollIndicatorInsets.bottom = 50.0
            self.tableView?.setContentOffset(CGPoint(x: 0.0, y: -self.startInset), animated: false)
            self.shadowView?.layer.addSublayer(shadowGradientLayer)
        }
        self.didLayout = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        
        let lineView = UIView()
        lineView.backgroundColor = .lightGray
        lineView.translatesAutoresizingMaskIntoConstraints = false
        cellView.view.addSubview(lineView)
        
        if indexPath.row == self.games.count - 1 {
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
        cellView.titleLabel?.text = game.gameFields?.name
        let index = game.gameFields?.releaseDate?.index((game.gameFields?.releaseDate?.startIndex)!, offsetBy: 4)
        cellView.descriptionLabel?.text = game.gameFields?.releaseDate?.substring(to: index!)
        cellView.rightLabel?.text = "\(game.progress)%"
        if cellView.imageSource == .Placeholder {
            if let image = game.gameFields?.image {
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
            self.titleBottomLayoutConstraint?.constant = offset - self.startInset + self.titleBottomInitial
            self.shadowBottomLayoutConstraint?.constant = offset - self.startInset
            self.backgroundTopLayoutConstraint?.constant = offset - self.startInset + self.backgroundTopInitial
            if offset > self.startInset {
                self.imageHeightLayoutConstraint?.constant = offset - self.startInset + self.imageHeightInitial
                self.imageTopLayoutConstraint?.constant = 0.0
                self.tableView?.scrollIndicatorInsets.top = offset
            } else {
                self.imageTopLayoutConstraint?.constant = (offset - self.startInset) / 5.0
                self.imageHeightLayoutConstraint?.constant = self.imageHeightInitial
                self.tableView?.scrollIndicatorInsets.top = self.startInset
            }
            if offset < 90.0 {
                
                let remainingWidth = offset - 65.0
                let newColor = UIColor(white: 1.0, alpha: (25.0 - remainingWidth) / 25.0)
                self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: newColor]
            } else if offset < 65.0 {
                self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
            } else {
                self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.clear]
            }
        }
    }
}
