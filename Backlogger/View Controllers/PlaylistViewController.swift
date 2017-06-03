//
//  PlaylistViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class PlaylistViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    let cellReuseIdentifier = "playlist_cell"
    var playlistList: Results<Playlist>?
    
    var selectedRow = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.separatorStyle = .none
        self.tableView?.register(UINib(nibName: "PlaylistTableCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        autoreleasepool {
            let realm = try! Realm()
            playlistList = realm.objects(Playlist.self)
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
        
        if indexPath.row > 0 {
            cell.playlist = playlistList![indexPath.row - 1]
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
        } else {
            let details = segue.destination as! PlaylistDetailsViewController
            details.playlist = playlistList![self.selectedRow - 1]
            details.playlistState = .default
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "newPlaylist", sender: tableView.cellForRow(at: indexPath))
        } else {
            self.selectedRow = indexPath.row
            self.performSegue(withIdentifier: "viewPlaylist", sender: tableView.cellForRow(at: indexPath))
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func loadPlaylistImage(_ row: Int) -> UIImage? {
        let filename = Util.getPlaylistImagesDirectory().appendingPathComponent("\(self.playlistList![row].uuid).png")
        return UIImage(contentsOfFile: filename.path)
    }
}
