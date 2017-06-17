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
    let stringList: [String] = ["Delete All"]
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.row) {
        case 0:
            let actions = UIAlertController(title: "Delete all games?", message: nil, preferredStyle: .alert)
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
            }))
            actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actions, animated: true, completion: nil)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
