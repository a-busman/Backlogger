//
//  GameTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class GameTableViewController: UIViewController, GameDetailsViewControllerDelegate, UIViewControllerPreviewingDelegate, PlaylistViewControllerDelegate {
    
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
    
    var games: Results<Game>?
    
    var platform: Platform?
    var platformId: Int?
    
    var currentlySelectedRow = 0
    
    var toastOverlay = ToastOverlayViewController()
    
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
    
    fileprivate let tableReuseIdentifier = "table_cell"
    
    enum SortType: Int {
        case alphabetical = 0
        case dateAdded = 1
    }
    
    var sortType: SortType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.headerTravelDistance = self.headerMaxHeight - self.headerMinHeight
        self.insetToHeader = startInset - headerMaxHeight
        if let platform = self.platform {
            self.platformId = platform.idNumber
            self.titleLabel?.text = platform.name
            self.games = platform.ownedGames.filter("platform.name = \"\(platform.name!)\"")
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
                self.platformImage?.kf.setImage(with: URL(string: superUrl), placeholder: #imageLiteral(resourceName: "now_playing_placeholder"), completionHandler: {
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
                self.platformImage?.image = #imageLiteral(resourceName: "now_playing_placeholder")
            }
        } else {
            NSLog("No platform during load")
        }
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: tableReuseIdentifier)
        
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                self.registerForPreviewing(with: self, sourceView: self.tableView!)
            }
        }
        self.toastOverlay.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(toastOverlay.view)
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerX,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerY,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 300.0
            ).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let sort = UserDefaults.standard.value(forKey: "librarySortType")
        self.sortType = SortType.init(rawValue: sort as! Int)
        if self.sortType == nil {
            self.sortType = .dateAdded
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
        }
        autoreleasepool {
            let realm = try? Realm()
            self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: platformId)
        }
        if self.platform == nil {
            let _ = self.navigationController?.popViewController(animated: true)
            return
        }
        var sortString: String
        var ascending: Bool
        switch self.sortType! {
        case .alphabetical:
            sortString = "gameFields.name"
            ascending = true
            break
        case .dateAdded:
            sortString = "dateAdded"
            ascending = false
            break
        }
        self.games = self.platform?.ownedGames.sorted(byKeyPath: sortString, ascending: ascending)
        self.tableView?.reloadData()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.clear]
        if self.games!.count < 1 {
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "library_show_details" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameDetailsViewController
                
                self.currentlySelectedRow = i
                
                vc.gameField = self.games![i].gameFields
                vc.game = self.games![i]
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
    
    @IBAction func moreTapped(sender: UIBarButtonItem) {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let addAction = UIAlertAction(title: "Add Games", style: .default, handler: self.addGames)
        let sortAction = UIAlertAction(title: "Sort...", style: .default, handler: self.sortTapped)
        
        actions.addAction(addAction)
        actions.addAction(sortAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)
    }
    
    func sortTapped(sender: UIAlertAction) {
        let actions = UIAlertController(title: "Sort games", message: nil, preferredStyle: .actionSheet)

        let alphaAction = UIAlertAction(title: "Alphabetical", style: .default, handler: { _ in
            self.sortType = .alphabetical
            if self.games != nil {
                self.games = self.games!.sorted(byKeyPath: "gameFields.name", ascending: true)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        let dateAction = UIAlertAction(title: "Recently Added", style: .default, handler: { _ in
            self.sortType = .dateAdded
            
            if self.games != nil {
                self.games = self.games!.sorted(byKeyPath: "dateAdded", ascending: false)
            }
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "librarySortType")
            self.tableView?.reloadData()
        })
        
        switch self.sortType! {
        case .alphabetical:
            alphaAction.setValue(true, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            break
        case .dateAdded:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(true, forKey: "checked")
            break
        }
        actions.addAction(alphaAction)
        actions.addAction(dateAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)
    }
    
    func addGames(sender: UIAlertAction) {
        let vc: LibraryAddSearchViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "add_game") as! LibraryAddSearchViewController
        let navVc = UINavigationController(rootViewController: vc)
        navVc.navigationBar.barStyle = .black
        navVc.navigationBar.isTranslucent = true
        navVc.navigationBar.barTintColor = Util.appColor
        self.present(navVc, animated: true, completion: nil)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView?.indexPathForRow(at: location),
            let cell = self.tableView?.cellForRow(at: indexPath),
            let gameFields = self.games![indexPath.row].gameFields else { return nil }
        let game = self.games![indexPath.row]
        let vc: GameDetailsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "game_details") as! GameDetailsViewController
        var gameField: GameField!

        autoreleasepool {
            let realm = try? Realm()
            gameField = realm?.object(ofType: GameField.self, forPrimaryKey: gameFields.idNumber)
        }
        if gameField == nil {
            gameField = gameFields
        }
        
        vc.game = game
        vc.state = .inLibrary
        vc.delegate = self
        vc.gameField = gameField
        
        previewingContext.sourceRect = cell.frame
        
        vc.addRemoveClosure = { (action, vc) -> Void in
            let game = self.games![indexPath.row]
            game.delete()
            autoreleasepool {
                let realm = try? Realm()
                self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: self.platform!.idNumber)
            }
            if self.platform != nil {
                self.games = self.platform?.ownedGames.filter("platform.name = \"\(self.platform!.name!)\"")
                self.tableView?.reloadData()
            } else {
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
        vc.addToPlayLaterClosure = { (action, vc) -> Void in
            self.addToUpNext(games: [game], later: true)
        }
        vc.addToPlaylistClosure = { (action, vc) -> Void in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistNavigation") as! UINavigationController
            let playlistVc = vc.viewControllers.first as! PlaylistViewController
            playlistVc.addingGames = [game]
            playlistVc.isAddingGames = true
            playlistVc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
        vc.addToPlayNextClosure = { (action, vc) -> Void in
            self.addToUpNext(games: [game], later: false)
        }
        return vc
    }
    
    func addToUpNext(games: [Game], later: Bool) {
        if later {
            autoreleasepool {
                let realm = try! Realm()
                let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
                if upNextPlaylist != nil {
                    var currentGames = Array(upNextPlaylist!.games)
                    currentGames.append(contentsOf: games)
                    upNextPlaylist!.update {
                        upNextPlaylist?.games.removeAll()
                        upNextPlaylist?.games.append(contentsOf: currentGames)
                    }
                }
            }
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_queue_large"), title: "Added to Queue", description: nil)
        } else {
            autoreleasepool {
                let realm = try! Realm()
                let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
                if upNextPlaylist != nil {
                    var currentGames = games
                    currentGames += upNextPlaylist!.games
                    upNextPlaylist!.update {
                        upNextPlaylist?.games.removeAll()
                        upNextPlaylist?.games.append(contentsOf: currentGames)
                    }
                }
            }
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "play_next_large"), title: "Added to Queue", description: "We'll play this one next.")
        }
    }
    
    func chosePlaylist(vc: PlaylistViewController, playlist: Playlist, games: [Game], isNew: Bool) {
        if !isNew {
            playlist.update {
                playlist.games.append(contentsOf: games)
            }
        }
        vc.presentingViewController?.dismiss(animated: true, completion: {
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_playlist_large"), title: "Added to Playlist", description: "Added to \"\(playlist.name!)\".")
        })
        vc.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
}

extension GameTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        cell.row = indexPath.row
        cell.accessoryType = .disclosureIndicator
        let game = self.games![indexPath.row]
        var indent: CGFloat = 0.0
        
        if indexPath.row < self.games!.count - 1 {
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
        
        cell.addButtonHidden = true
        
        cell.titleLabel?.text = game.gameFields?.name
        let index = game.gameFields?.releaseDate?.index((game.gameFields?.releaseDate?.startIndex)!, offsetBy: 4)
        cell.descriptionLabel?.text = game.gameFields?.releaseDate?.substring(to: index!)
        cell.rightLabel?.text = "\(game.progress)%"
        if let image = game.gameFields?.image {
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
            let game = games![indexPath.row]
            game.delete()
            autoreleasepool {
                let realm = try? Realm()
                self.platform = realm?.object(ofType: Platform.self, forPrimaryKey: self.platformId)
            }
            if self.platform != nil {
                self.games = self.platform?.ownedGames.filter("platform.name = \"\(self.platform!.name!)\"")
                self.tableView?.deleteRows(at: [indexPath], with: .automatic)
                self.tableView?.reloadData()
            } else {
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView?.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "library_show_details", sender: tableView.cellForRow(at: indexPath))
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
