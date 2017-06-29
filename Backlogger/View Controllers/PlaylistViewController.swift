//
//  PlaylistViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

protocol PlaylistViewControllerDelegate {
    func chosePlaylist(vc: PlaylistViewController, playlist: Playlist, games: [Game], isNew: Bool)
}

class PlaylistViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    let cellReuseIdentifier = "playlist_cell"
    var playlistList: [Playlist] = []
    
    var imageCache: [String: UIImage] = [:]
    
    var isAddingGames = false
    
    var addingGames: [Game] = []
    
    var delegate: PlaylistViewControllerDelegate?
    
    var showFavourites: Bool = false
    
    enum SortType: Int {
        case alphabetical = 0
        case dateAdded = 1
        case percentComplete = 2
        case completed = 3
    }
    
    var sortType: SortType?
    var ascending: Bool?
    
    var selectedRow = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        let sort = UserDefaults.standard.value(forKey: "playlistSortType")
        if sort == nil {
            self.sortType = .dateAdded
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "playlistSortType")
        } else {
            self.sortType = SortType.init(rawValue: sort as! Int)
        }
        self.ascending = UserDefaults.standard.value(forKey: "playlistAscending") as? Bool
        if self.ascending == nil {
            self.ascending = true
            UserDefaults.standard.set(self.ascending, forKey: "playlistAscending")
        }
        self.tableView?.register(UINib(nibName: "PlaylistTableCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.navigationController?.navigationBar.tintColor = .white
        if self.isAddingGames {
            self.navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        }
    }
    
    @IBAction func sortTapped(sender: UIBarButtonItem) {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let alphaAction = UIAlertAction(title: "Title", style: .default, handler: { _ in
            self.ascending = self.sortType == .alphabetical ? !self.ascending! : true
            self.sortType = .alphabetical
            autoreleasepool {
                let realm = try! Realm()
                self.playlistList = Array(realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted(byKeyPath: "name", ascending: self.ascending!))
            }
            UserDefaults.standard.set(self.ascending!, forKey: "playlistAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "playlistSortType")
            self.tableView?.reloadData()
        })
        let dateAction = UIAlertAction(title: "Recently Added", style: .default, handler: { _ in
            self.ascending = self.sortType == .dateAdded ? !self.ascending! : false
            self.sortType = .dateAdded
            autoreleasepool {
                let realm = try! Realm()
                self.playlistList = Array(realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted(byKeyPath: "dateAdded", ascending: self.ascending!))
            }
            UserDefaults.standard.set(self.ascending!, forKey: "playlistAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "playlistSortType")
            self.tableView?.reloadData()
        })
        let progressAction = UIAlertAction(title: "Progress", style: .default, handler: { _ in
            self.ascending = self.sortType == .percentComplete ? !self.ascending! : true
            self.sortType = .percentComplete
            autoreleasepool {
                let realm = try! Realm()
                self.playlistList = realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.progress < p2.progress
                    } else {
                        ret = p1.progress > p2.progress
                    }
                    return ret
                }
            }
            UserDefaults.standard.set(self.ascending!, forKey: "playlistAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "playlistSortType")
            self.tableView?.reloadData()
        })
        let completedAction = UIAlertAction(title: "Finished", style: .default, handler: { _ in
            self.ascending = self.sortType == .completed ? !self.ascending! : true
            self.sortType = .completed
            autoreleasepool {
                let realm = try! Realm()
                self.playlistList = realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.finished < p2.finished
                    } else {
                        ret = p1.finished > p2.finished
                    }
                    return ret
                }
            }
            UserDefaults.standard.set(self.ascending!, forKey: "playlistAscending")
            UserDefaults.standard.set(self.sortType!.rawValue, forKey: "playlistSortType")
            self.tableView?.reloadData()
        })
        
        switch self.sortType! {
        case .alphabetical:
            alphaAction.setValue(true, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            progressAction.setValue(false, forKey: "checked")
            completedAction.setValue(false, forKey: "checked")
            break
        case .dateAdded:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(true, forKey: "checked")
            progressAction.setValue(false, forKey: "checked")
            completedAction.setValue(false, forKey: "checked")
            break
        case .percentComplete:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            progressAction.setValue(true, forKey: "checked")
            completedAction.setValue(false, forKey: "checked")
            break
        case .completed:
            alphaAction.setValue(false, forKey: "checked")
            dateAction.setValue(false, forKey: "checked")
            progressAction.setValue(false, forKey: "checked")
            completedAction.setValue(true, forKey: "checked")
            break
        }
        actions.addAction(alphaAction)
        actions.addAction(dateAction)
        actions.addAction(progressAction)
        actions.addAction(completedAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actions.popoverPresentationController?.barButtonItem = self.navigationController?.navigationBar.topItem?.rightBarButtonItem
        self.present(actions, animated: true, completion: nil)
    }
    func cancelTapped(sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        autoreleasepool {
            let realm = try! Realm()
            switch self.sortType! {
            case .alphabetical:
                self.playlistList = Array(realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted(byKeyPath: "name", ascending: self.ascending!))
                break
            case .dateAdded:
                self.playlistList = Array(realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted(byKeyPath: "dateAdded", ascending: self.ascending!))
                break
            case .percentComplete:
                self.playlistList = realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.progress < p2.progress
                    } else {
                        ret = p1.progress > p2.progress
                    }
                    return ret
                }
                break
            case .completed:
                self.playlistList = realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false").sorted { (p1, p2) in
                    var ret: Bool
                    if self.ascending! {
                        ret = p1.finished < p2.finished
                    } else {
                        ret = p1.finished > p2.finished
                    }
                    return ret
                }
            }
            if realm.objects(Game.self).filter("favourite = true").count > 0 && !self.isAddingGames {
                self.showFavourites = true
            } else {
                self.showFavourites = false
            }
        }
        for (_, playlist) in self.playlistList.enumerated() {
            let _ = self.loadImageFromFile(playlist.uuid)
        }
        if self.tabBarController != nil {
            if self.playlistList.count == 0 {
                self.navigationController?.navigationBar.topItem?.rightBarButtonItem = nil
            } else {
                self.navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(self.sortTapped))
            }
        }
        self.tableView?.reloadData()
    }
}

extension PlaylistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = self.playlistList.count + 1
        if self.showFavourites {
            count += 1
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! PlaylistTableCell
        let extraCell = self.showFavourites ? 1 : 0
        
        var indent: CGFloat = 0.0
        if indexPath.row < self.playlistList.count + extraCell {
            indent = 129.5
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
        if self.showFavourites && indexPath.row == 1 {
            cell.state = .favourite
            cell.accessoryType = .disclosureIndicator
        }
        if indexPath.row > 0 + extraCell {
            cell.playlist = self.playlistList[indexPath.row - 1 - extraCell]
            cell.artImage = self.loadPlaylistImage(indexPath.row - 1 - extraCell)
            if !self.isAddingGames {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newPlaylist" {
            let nav = segue.destination as! UINavigationController
            let details = nav.topViewController! as! PlaylistDetailsViewController
            details.playlistState = .new
            if self.isAddingGames {
                details.delegate = self
                details.games.append(contentsOf: self.addingGames)
            }
        } else if self.selectedRow == 1 && self.showFavourites {
            let details = segue.destination as! PlaylistDetailsViewController
            details.isFavourites = true
            details.playlistState = .default
        } else {
            let details = segue.destination as! PlaylistDetailsViewController
            details.playlist = self.playlistList[self.selectedRow - 1 - (self.showFavourites ? 1 : 0)]
            details.playlistState = .default
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "playlist_details") as! PlaylistDetailsViewController
            let navVc = UINavigationController(rootViewController: vc)
            vc.playlistState = .new
            vc.delegate = self
            if self.isAddingGames {
                vc.games.append(contentsOf: self.addingGames)
            }
            navVc.navigationBar.barTintColor = Util.appColor
            navVc.navigationBar.barStyle = .black
            navVc.navigationBar.isTranslucent = true
            self.present(navVc, animated: true, completion: {
                vc.showCamera()
            })
        } else {
            if self.isAddingGames {
                self.delegate?.chosePlaylist(vc: self, playlist: self.playlistList[indexPath.row - 1], games: self.addingGames, isNew: false)
            } else {
                self.selectedRow = indexPath.row
                self.performSegue(withIdentifier: "viewPlaylist", sender: tableView.cellForRow(at: indexPath))
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func loadPlaylistImage(_ row: Int) -> UIImage? {
        let uuid = self.playlistList[row].uuid
        if let image = self.imageCache[uuid] {
            return image
        } else {
            return loadImageFromFile(uuid)
        }
    }
    
    func loadImageFromFile(_ uuid: String) -> UIImage? {
        let filename = Util.getPlaylistImagesDirectory().appendingPathComponent("\(uuid).png")
        let image = UIImage(contentsOfFile: filename.path)
        self.imageCache[uuid] = image
        return image
    }
}

extension PlaylistViewController: PlaylistDetailsViewControllerDelegate {
    func didFinish(vc: PlaylistDetailsViewController, playlist: Playlist) {
        if !self.isAddingGames {
            vc.dismiss(animated: true, completion: nil)
        }
        self.delegate?.chosePlaylist(vc: self, playlist: playlist, games: [], isNew: true)
    }
}
