//
//  LibraryViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class LibraryViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var tableView: UITableView?
    var tableSearchBar: UISearchBar?
    @IBOutlet weak var collectionSearchBar: UISearchBar?
    
    var flowLayout: UICollectionViewFlowLayout {
        return self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    enum ViewState{
        case icon
        case list
    }
    
    enum ScrollDirection {
        case Up
        case Down
    }
    
    var lastPosition: CGFloat = -64.0
    var lastDirection: ScrollDirection = .Up
    
    var originalSearchBarPos: CGFloat = 0.0
    
    private var viewState: ViewState = .icon
    
    let collectionReuseIdentifier = "console_cell"
    let tableReuseIdentifier = "console_table_cell"
    let collectionHeaderReuseIdentifier = "library_collection_header"

    var consoles: [Console] = [Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo")),
                               Console(title: "GameCube", company: "Nintendo", releaseDate: "2001", gameCount: "1382", image: #imageLiteral(resourceName: "gc-logo"))]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableSearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        tableSearchBar?.tintColor = .white
        tableSearchBar?.placeholder = "Library"
        tableSearchBar?.delegate = self
        self.tableView?.tableHeaderView = tableSearchBar
        let size = (self.collectionView?.frame.size)!
        collectionView?.backgroundColor = .clear
        flowLayout.itemSize = CGSize(width: size.width / 2.0, height: size.width / 2.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var contentOffset = (self.tableView?.contentOffset)!
        if contentOffset.y == 0 {
            contentOffset.y = (self.tableView?.tableHeaderView?.frame)!.height
        }
        self.tableView?.contentOffset = contentOffset
        self.tableView?.contentInset.top = 64
        self.tableView?.contentInset.bottom = 40
    }
    
    override func viewDidLayoutSubviews() {
        self.originalSearchBarPos = (self.collectionSearchBar?.center.y)!
    }
    
    @IBAction func leftBarButtonTapped(sender: UIBarButtonItem) {
        if self.viewState == .icon {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.image = #imageLiteral(resourceName: "tile_icon")
            self.collectionView?.isHidden = true
            self.collectionSearchBar?.isHidden = true
            self.tableView?.isHidden = false
            self.viewState = .list
        } else {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.image = #imageLiteral(resourceName: "list_icon")
            self.collectionView?.isHidden = false
            self.collectionSearchBar?.isHidden = false
            self.tableView?.isHidden = true
            self.viewState = .icon
        }
        self.collectionSearchBar?.resignFirstResponder()
        self.tableSearchBar?.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "table_game_list" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameTableViewController
                vc.title = self.consoles[i].title
            }
        } else if segue.identifier == "collection_game_list" {
            if let cell = sender as? UICollectionViewCell {
                let i = (self.collectionView?.indexPath(for: cell)?.item)!
                let vc = segue.destination as! GameTableViewController
                vc.title = self.consoles[i].title
            }
        }
    }
    
    func addGame() {
        self.performSegue(withIdentifier: "add_show_details", sender: nil)
    }
}

extension LibraryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.consoles.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath)
        let consoleViewController = ConsoleViewController(console: consoles[indexPath.item])
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        let consoleView = (consoleViewController.view)!
        consoleView.translatesAutoresizingMaskIntoConstraints = false
        consoleView.setNeedsLayout()
        consoleView.layoutIfNeeded()
        cell.contentView.addSubview(consoleView)
        //cell.bounds.size = (self.collectionView?.bounds.size)!
        
        NSLayoutConstraint(item: consoleView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: consoleView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: consoleView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: consoleView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "library_collection_header", for: indexPath)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = (self.collectionView?.frame.size)!
        size.width = (size.width / 2.0)
        size.height = size.width
        return size
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !(collectionSearchBar?.isHidden)! {
            if targetContentOffset.pointee.y > -64.0 && targetContentOffset.pointee.y <= -53.0 {
                UIView.animate(withDuration: 0.5, animations: {targetContentOffset.pointee.y = -64.0})
            } else if targetContentOffset.pointee.y > -31.0 && targetContentOffset.pointee.y < -20.0 {
                UIView.animate(withDuration: 0.5, animations: {targetContentOffset.pointee.y = -20.0})
            } else if targetContentOffset.pointee.y > -53.0 && targetContentOffset.pointee.y < -31.0 {
                if self.lastDirection == .Up {
                    UIView.animate(withDuration: 0.75, animations: {targetContentOffset.pointee.y = -64.0})
                } else {
                    UIView.animate(withDuration: 0.75, animations: {targetContentOffset.pointee.y = -20.0})

                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !(collectionSearchBar?.isHidden)! {
            if scrollView.contentOffset.y >= -64.0 && scrollView.contentOffset.y <= -20.0 {
                self.collectionSearchBar?.center.y = self.originalSearchBarPos - (scrollView.contentOffset.y + 64.0)
            } else if scrollView.contentOffset.y > -20.0 {
                self.collectionSearchBar?.center.y = self.originalSearchBarPos - 44.0
            } else if scrollView.contentOffset.y < -64.0 {
                self.collectionSearchBar?.center.y = self.originalSearchBarPos
            }
            self.collectionSearchBar?.resignFirstResponder()
            if self.lastPosition > scrollView.contentOffset.y {
                self.lastDirection = .Up
            } else {
                self.lastDirection = .Down
            }
            self.lastPosition = scrollView.contentOffset.y
        } else {
            self.tableSearchBar?.resignFirstResponder()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt source: IndexPath, to destination: IndexPath) {
        let game = self.consoles.remove(at: source.item)
        self.consoles.insert(game, at: destination.item)
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
    
}

extension LibraryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.consoles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier)!
        let console = self.consoles[indexPath.item]
        let cellView = TableViewCellView(console: console)
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
        cell.backgroundColor = (indexPath.item % 2) == (self.consoles.count % 2 == 0 ? 1 : 0) ? UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) : .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
