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
    var playlistList: Results<Playlist>?
    
    var imageCache: [String: UIImage] = [:]
    
    var isAddingGames = false
    
    var addingGames: [Game] = []
    
    var delegate: PlaylistViewControllerDelegate?
    
    var selectedRow = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(UINib(nibName: "PlaylistTableCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView?.tableFooterView = UIView(frame: .zero)
        self.navigationController?.navigationBar.tintColor = .white
        if self.isAddingGames {
            self.navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        }
    }
    
    func cancelTapped(sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        autoreleasepool {
            let realm = try! Realm()
            playlistList = realm.objects(Playlist.self).filter("isNowPlaying = false and isUpNext = false")
        }
        if self.playlistList != nil {
            for (_, playlist) in self.playlistList!.enumerated() {
                let _ = self.loadImageFromFile(playlist.uuid)
            }
        }
        self.tableView?.reloadData()
    }
}

extension PlaylistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.playlistList?.count ?? 0) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! PlaylistTableCell
        
        var indent: CGFloat = 0.0
        if indexPath.row < self.playlistList!.count {
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
        
        if indexPath.row > 0 {
            cell.playlist = self.playlistList![indexPath.row - 1]
            cell.artImage = self.loadPlaylistImage(indexPath.row - 1)
            cell.accessoryType = .disclosureIndicator
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
        } else {
            let details = segue.destination as! PlaylistDetailsViewController
            details.playlist = self.playlistList![self.selectedRow - 1]
            details.playlistState = .default
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "newPlaylist", sender: tableView.cellForRow(at: indexPath))
        } else {
            if self.isAddingGames {
                self.delegate?.chosePlaylist(vc: self, playlist: self.playlistList![indexPath.row - 1], games: self.addingGames, isNew: false)
            } else {
                self.selectedRow = indexPath.row
                self.performSegue(withIdentifier: "viewPlaylist", sender: tableView.cellForRow(at: indexPath))
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func loadPlaylistImage(_ row: Int) -> UIImage? {
        guard let uuid = self.playlistList?[row].uuid else {
            return nil
        }
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
        self.delegate?.chosePlaylist(vc: self, playlist: playlist, games: [], isNew: true)
    }
}
