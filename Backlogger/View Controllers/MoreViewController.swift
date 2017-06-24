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
    @IBOutlet weak var tableView: UITableView?
    var steamVc: UINavigationController?
    let stringList: [String] = ["Link Steam Account", "Delete All", "About"]
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension MoreViewController: UITableViewDelegate, UITableViewDataSource, SteamLoginViewControllerDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stringList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        if indexPath.row == 0,
           let steamName = UserDefaults.standard.value(forKey: "steamName") as? String {
                cell.textLabel?.text = "Unlink Steam Account"
                cell.detailTextLabel?.text = steamName
            
        } else {
            cell.textLabel?.text = stringList[indexPath.row]
            cell.detailTextLabel?.text = ""
        }
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
    
    func tappedDone(sender: UIBarButtonItem) {
        self.steamVc?.dismiss(animated: true, completion: nil)
    }
    
    func got(steamId: String?, username: String?) {
        if steamId != nil {
            UserDefaults.standard.set(steamId, forKey: "steamId")
            Steam.getUserName(with: steamId!) { results in
                if let error = results.error {
                    NSLog(error.localizedDescription)
                    // Could not get steamID
                } else {
                    UserDefaults.standard.set(results.value!, forKey: "steamName")
                    self.tableView?.reloadData()
                }
            }
            Steam.getUserGameList(with: steamId!) { results in
                if let listError = results.error {
                    NSLog(listError.localizedDescription)
                } else {
                    print("\(steamId!) has \(results.value!.count) games")
                    for game in results.value! {
                        print(game.name)
                    }
                }
            }
        } else if username != nil {
            UserDefaults.standard.set(username!, forKey: "steamName")
            Steam.getUserId(with: username!) { results in
                if let error = results.error {
                    NSLog(error.localizedDescription)
                    // Could not get steamID
                } else {
                    UserDefaults.standard.set(results.value!, forKey: "steamId")
                    Steam.getUserGameList(with: results.value!) { gameResults in
                        if let listError = gameResults.error {
                            NSLog(listError.localizedDescription)
                        } else {
                            print("\(username!) has \(gameResults.value!.count) games")
                            for game in gameResults.value! {
                                print(game.name)
                            }
                        }
                    }
                }
            }
        }
        self.tableView?.reloadData()
        self.steamVc?.dismiss(animated: true, completion: nil)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.row) {
        case 0:
            if let _ = UserDefaults.standard.value(forKey: "steamName") as? String {
                UserDefaults.standard.removeObject(forKey: "steamName")
                UserDefaults.standard.removeObject(forKey: "steamId")
                self.tableView?.reloadData()
            } else {
                let vc = SteamLoginViewController()
                self.steamVc = UINavigationController(rootViewController: vc)
                self.steamVc?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.tappedDone))
                self.steamVc?.navigationBar.barTintColor = Util.appColor
                self.steamVc?.navigationBar.tintColor = .white
                self.steamVc?.navigationBar.barStyle = .black
                self.steamVc?.navigationBar.isTranslucent = true
                vc.delegate = self
                self.present(self.steamVc!, animated: true, completion: nil)
                
            }
        case 1:
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
            break
        case 2:
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "about")
            self.navigationController?.pushViewController(vc, animated: true)
            self.navigationController?.navigationBar.tintColor = .white
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
