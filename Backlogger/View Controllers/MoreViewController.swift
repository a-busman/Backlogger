//
//  MoreViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift
import Kingfisher

class MoreViewController: UIViewController {
    let stringList: [String] = ["Delete All", "About"]
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension MoreViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stringList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        cell.textLabel?.text = stringList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let versionLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: 30.0))
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return UIView(frame: .zero)
        }
        versionLabel.text = "Version \(version)"
        versionLabel.textAlignment = .center
        versionLabel.textColor = .lightGray
        return versionLabel
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.row) {
        case 0:
            let actions = UIAlertController(title: "Delete all games?", message: "This will delete all games and playlists in your library.", preferredStyle: .alert)
            actions.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                autoreleasepool {
                    let realm = try! Realm()
                    try! realm.write {
                        realm.deleteAll()
                    }
                }
                // Delete all playlist images
                let fileManager = FileManager.default
                let dirPath = Util.getPlaylistImagesDirectory()
                var directoryContents: [String] = []
                do {
                    directoryContents = try fileManager.contentsOfDirectory(atPath: dirPath.path)
                } catch {
                    NSLog("Could not retrieve directory")
                }
                for path in directoryContents {
                    let fullPath = dirPath.appendingPathComponent(path)
                    do {
                        try fileManager.removeItem(atPath: fullPath.path)
                    } catch {
                        NSLog("Could not delete file: \(fullPath)")
                    }
                }
                // Delete all cached images
                ImageCache.default.clearDiskCache()
                self.tabBarController!.viewControllers?[0] = self.storyboard!.instantiateViewController(withIdentifier: "NowPlayingNavigation")
                self.tabBarController!.viewControllers?[1] = self.storyboard!.instantiateViewController(withIdentifier: "PlaylistNavigation")
                self.tabBarController!.viewControllers?[2] = self.storyboard!.instantiateViewController(withIdentifier: "LibraryNavigation")
            }))
            actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actions, animated: true, completion: nil)
        case 1:
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "about")
            self.navigationController?.pushViewController(vc, animated: true)
            self.navigationController?.navigationBar.tintColor = .white
            print("About")
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
