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
import Zip
import MobileCoreServices
import Zephyr

class MoreViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var loadingView: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var progressLabel: UILabel?
    @IBOutlet weak var progressBar: UIProgressView?
    @IBOutlet weak var plainLoadingView: UIView?
    @IBOutlet weak var plainActivityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var progressCollectionView: UICollectionView?
    
    let progressReuseId = "progress_cell"
    
    var steamVc: UINavigationController?
    let generalStrings: [String] = ["Link Steam Account", "Wishlist", "About"]
    let dataStrings: [String] = ["Import", "Export", "Reset Data"]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.tableFooterView = self.progressCollectionView
        self.progressCollectionView?.register(UINib(nibName: "ProgressCell", bundle: nil), forCellWithReuseIdentifier: self.progressReuseId)
        self.progressCollectionView?.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Util.isICloudContainerAvailable {
            Zephyr.sync()
        }
        self.progressCollectionView?.reloadData()
        self.progressCollectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let screenSize = UIScreen.main.bounds
        if screenSize.width == 320.0 {
            self.progressCollectionView?.contentInset = UIEdgeInsets(top: 0, left: 0.0, bottom: 0, right: 0.0)
        } else {
            self.progressCollectionView?.contentInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 16.0)
        }
        if self.tableView!.contentSize.height > (self.tableView!.frame.height - self.navigationController!.navigationBar.frame.height - self.tabBarController!.tabBar.frame.height - 20.0) {
            self.tableView?.bounces = true
        }
    }
}

extension MoreViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 145, height: 170)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.progressReuseId, for: indexPath) as! ProgressCell
        autoreleasepool {
            let realm = try! Realm()
            let allObjects = realm.objects(Game.self).filter("inLibrary = true")
            let totalCount = allObjects.count
            cell.denominator = totalCount
            cell.progressType = .games
            switch(indexPath.item) {
            case 0:
                let completeCount = allObjects.filter("finished = true").count
                cell.numerator = completeCount
                cell.titleString = "Finished"
                break
            case 1:
                let hundoPCount = allObjects.filter("progress = 100").count
                cell.numerator = hundoPCount
                cell.titleString = "100% Complete"
                break
            case 2:
                let startedCount = allObjects.filter("progress != 0").count
                cell.numerator = startedCount
                cell.titleString = "Started"
                break
            case 3:
                let sumOfPercentages: Int = allObjects.sum(ofProperty: "progress")
                if totalCount > 0 {
                    cell.numerator = sumOfPercentages / totalCount
                } else {
                    cell.numerator = 0
                }
                cell.denominator = 100
                cell.progressType = .percent
                cell.titleString = "Total Progress"
                break
            default:
                break
            }
        }
        cell.layoutSubviews()
        return cell
    }
}

extension MoreViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.5
        } else {
            return 10.0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.generalStrings.count
        case 1:
            return self.dataStrings.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        if indexPath.section == 0 {
            if indexPath.row == 0,
               let steamName = UserDefaults.standard.value(forKey: "steamName") as? String {
                    cell.textLabel?.text = "Unlink Steam Account"
                    cell.detailTextLabel?.text = steamName
                
            } else {
                cell.textLabel?.text = self.generalStrings[indexPath.row]
                cell.detailTextLabel?.text = ""
            }
        } else if indexPath.section == 1 {
            cell.textLabel?.text = self.dataStrings[indexPath.row]
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    func tappedDone(sender: UIBarButtonItem) {
        self.steamVc?.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                if Util.isICloudContainerAvailable {
                    Zephyr.sync(keys: ["steamName"])
                }
                if let _ = UserDefaults.standard.value(forKey: "steamName") as? String {
                    let actions = UIAlertController(title: "Unlink Steam account?", message: "This will remove all steam games from Backlogger.", preferredStyle: .alert)
                    actions.addAction(UIAlertAction(title: "Unlink", style: .destructive, handler: { _ in
                        UserDefaults.standard.removeObject(forKey: "steamName")
                        UserDefaults.standard.removeObject(forKey: "steamId")
                        self.plainActivityIndicator?.startAnimating()
                        self.plainLoadingView?.isHidden = false
                        UIApplication.shared.beginIgnoringInteractionEvents()
                        autoreleasepool {
                            let realm = try! Realm()
                            if let platform = realm.object(ofType: Platform.self, forPrimaryKey: Steam.steamPlatformIdNumber) {
                                let ownedGames = platform.ownedGames
                                for game in ownedGames {
                                    game.delete()
                                }
                            }
                        }
                        UIApplication.shared.endIgnoringInteractionEvents()
                        self.plainLoadingView?.isHidden = true
                        self.plainActivityIndicator?.stopAnimating()
                        self.tableView?.reloadData()
                        self.tabBarController!.viewControllers?[0] = self.storyboard!.instantiateViewController(withIdentifier: "NowPlayingNavigation")
                        self.tabBarController!.viewControllers?[1] = self.storyboard!.instantiateViewController(withIdentifier: "PlaylistNavigation")
                        self.tabBarController!.viewControllers?[2] = self.storyboard!.instantiateViewController(withIdentifier: "LibraryNavigation")
                    }))
                    actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(actions, animated: true, completion: nil)
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
                let vc = self.storyboard!.instantiateViewController(withIdentifier: "wishlist_nav_vc")
                self.present(vc, animated: true, completion: nil)

            case 2:
                let vc = self.storyboard!.instantiateViewController(withIdentifier: "about")
                self.navigationController?.pushViewController(vc, animated: true)
                self.navigationController?.navigationBar.tintColor = .white
            default:
                break
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeData)], in: .import)
                documentPicker.delegate = self
                self.present(documentPicker, animated: true, completion: nil)
            case 1:
                let dir: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.BackloggerSharing")!
                let realmPath = dir.appendingPathComponent("db.realm")
                let zipFile = try? Zip.quickZipFiles([Util.getDocumentsDirectory(), realmPath], fileName: "Backlogger")
                let documentPicker = UIDocumentPickerViewController(url: zipFile!, in: .exportToService)
                documentPicker.delegate = self
                self.present(documentPicker, animated: true, completion: nil)
            case 2:
                var messageString: String = "This will remove all games and playlists in your library."
                if Util.isICloudContainerAvailable {
                    Zephyr.sync(keys: ["steamName"])
                }
                if let _ = UserDefaults.standard.value(forKey: "steamName") as? String {
                    messageString += " This will also unlink your steam account."
                }
                
                let actions = UIAlertController(title: "Reset Data?", message: messageString, preferredStyle: .alert)
                actions.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
                    UserDefaults.standard.removeObject(forKey: "steamName")
                    UserDefaults.standard.removeObject(forKey: "steamId")
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
                    self.tableView?.reloadData()
                    self.tabBarController!.viewControllers?[0] = self.storyboard!.instantiateViewController(withIdentifier: "NowPlayingNavigation")
                    self.tabBarController!.viewControllers?[1] = self.storyboard!.instantiateViewController(withIdentifier: "PlaylistNavigation")
                    self.tabBarController!.viewControllers?[2] = self.storyboard!.instantiateViewController(withIdentifier: "LibraryNavigation")
                }))
                actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(actions, animated: true, completion: nil)
                break
            default:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MoreViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        let oldBackup = Util.getDocumentsDirectory().appendingPathComponent("Backlogger.zip")
        if FileManager.default.fileExists(atPath: oldBackup.path) {
            try! FileManager.default.removeItem(at: oldBackup)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let oldBackup = Util.getDocumentsDirectory().appendingPathComponent("Backlogger.zip")
        if FileManager.default.fileExists(atPath: oldBackup.absoluteString) {
            try! FileManager.default.removeItem(at: oldBackup)
        }
        if controller.documentPickerMode == .import {
            let backupUrl = Util.getDocumentsDirectory().appendingPathComponent("backup")
            do {
                var isDir : ObjCBool = true
                if FileManager.default.fileExists(atPath: backupUrl.path, isDirectory: &isDir) {
                    if isDir.boolValue {
                        try FileManager.default.removeItem(at: backupUrl)
                    }
                }
                try FileManager.default.createDirectory(at: backupUrl, withIntermediateDirectories: false, attributes: nil)
                try Zip.unzipFile(url, destination: backupUrl, overwrite: true, password: nil, progress: nil)
                
                let dir: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.BackloggerSharing")!
                let realmPath = dir.appendingPathComponent("db.realm")
                try FileManager.default.removeItem(at: realmPath)
                try FileManager.default.moveItem(at: backupUrl.appendingPathComponent("db.realm"), to: realmPath)
                for file in try FileManager.default.contentsOfDirectory(atPath: Util.getPlaylistImagesDirectory().path) {
                    try FileManager.default.removeItem(at: Util.getPlaylistImagesDirectory().appendingPathComponent(file))
                }
                for file in try FileManager.default.contentsOfDirectory(atPath: backupUrl.appendingPathComponent("Documents/images/playlists").path) {
                    try FileManager.default.moveItem(at: backupUrl.appendingPathComponent("Documents/images/playlists").appendingPathComponent(file), to: Util.getPlaylistImagesDirectory().appendingPathComponent(file))
                }
                try FileManager.default.removeItem(at: backupUrl)
            } catch let error as NSError {
                NSLog("Error importing backup: \(error.localizedDescription)")
            }
        }
    }
}

extension MoreViewController: SteamLoginViewControllerDelegate {
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
                    if results.value!.count > 0 {
                        Steam.matchGiantBombGames(with: results.value!, progressHandler: { progress, total in
                            self.progressBar?.setProgress(Float(progress) / Float(total), animated: true)
                            self.progressLabel?.text = "\(progress) / \(total)"
                        }) { matched, unmatched in
                            if let gamesError = matched.error {
                                NSLog(gamesError.localizedDescription)
                            } else {
                                NSLog("Done")
                                self.loadingView?.isHidden = true
                                self.activityIndicator?.stopAnimating()
                                UIApplication.shared.endIgnoringInteractionEvents()
                                if matched.value!.count > 0 {
                                    //dedupe
                                    var dedupedList: [GameField] = []
                                    for game in matched.value! {
                                        var inNewList = false
                                        for newGame in dedupedList {
                                            if game.idNumber == newGame.idNumber {
                                                inNewList = true
                                                break
                                            }
                                        }
                                        if !inNewList {
                                            dedupedList.append(game)
                                        }
                                    }
                                    let vc = self.storyboard!.instantiateViewController(withIdentifier: "add_from_steam") as! UINavigationController
                                    let rootView = vc.viewControllers.first! as! AddSteamGamesViewController
                                    vc.navigationBar.tintColor = .white
                                    rootView.delegate = self
                                    rootView.gameFields = dedupedList
                                    self.present(vc, animated: true, completion: nil)
                                }
                            }
                        }
                    } else {
                        self.loadingView?.isHidden = true
                        self.activityIndicator?.stopAnimating()
                        UIApplication.shared.endIgnoringInteractionEvents()
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
                            Steam.matchGiantBombGames(with: gameResults.value!, progressHandler: { progress, total in
                                self.progressBar?.setProgress(Float(progress) / Float(total), animated: true)
                                self.progressLabel?.text = "\(progress) / \(total)"
                            }) { matched, unmatched in
                                if let gamesError = matched.error {
                                    NSLog(gamesError.localizedDescription)
                                } else {
                                    NSLog("Done")
                                    self.loadingView?.isHidden = true
                                    self.activityIndicator?.stopAnimating()
                                    UIApplication.shared.endIgnoringInteractionEvents()
                                    if matched.value!.count > 0 {
                                        //dedupe
                                        var dedupedList: [GameField] = []
                                        for game in matched.value! {
                                            var inNewList = false
                                            for newGame in dedupedList {
                                                if game.idNumber == newGame.idNumber {
                                                    inNewList = true
                                                    break
                                                }
                                            }
                                            if !inNewList {
                                                dedupedList.append(game)
                                            }
                                        }
                                        let vc = self.storyboard!.instantiateViewController(withIdentifier: "add_from_steam") as! UINavigationController
                                        let rootView = vc.viewControllers.first! as! AddSteamGamesViewController
                                        vc.navigationBar.tintColor = .white
                                        rootView.delegate = self
                                        rootView.gameFields = dedupedList
                                        self.present(vc, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        self.tableView?.reloadData()
        self.steamVc?.dismiss(animated: true, completion: nil)
        self.activityIndicator?.startAnimating()
        self.progressBar?.setProgress(0.0, animated: false)
        self.progressLabel?.text = ""
        self.loadingView?.isHidden = false
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
}

extension MoreViewController: AddSteamGamesViewControllerDelegate {
    func didSelectSteamGames(vc: AddSteamGamesViewController, games: [GameField]) {
        vc.dismiss(animated: true, completion: nil)
        if games.count > 0 {
            var steamPlatform: Platform?
            autoreleasepool {
                let realm = try! Realm()
                if let plat = realm.object(ofType: Platform.self, forPrimaryKey: Steam.steamPlatformIdNumber) {
                    steamPlatform = plat
                } else {
                    var company: Company
                    if let comp = realm.object(ofType: Company.self, forPrimaryKey: 1374) {
                        company = comp
                    } else {
                        company = Company()
                        company.name = "Valve Corporation"
                        company.idNumber = 1374
                        company.apiDetailUrl = "https://www.giantbomb.com/api/company/3010-1374/"
                        company.siteDetailUrl = "https://www.giantbomb.com/valve-corporation/3010-1374/"
                        company.add()
                    }
                    steamPlatform = Platform()
                    steamPlatform?.idNumber = Steam.steamPlatformIdNumber
                    steamPlatform?.name = "Steam"
                    steamPlatform?.company = company
                    steamPlatform?.hasDetails = true
                    steamPlatform?.add()
                }
            }
            self.plainActivityIndicator?.startAnimating()
            self.plainLoadingView?.isHidden = false
            UIApplication.shared.beginIgnoringInteractionEvents()
            for game in games {
                let newGame = Game()
                newGame.inLibrary = true
                newGame.fromSteam = true
                newGame.add(game, steamPlatform)
            }
            self.plainLoadingView?.isHidden = true
            self.plainActivityIndicator?.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
    
    func didDismiss(vc: AddSteamGamesViewController) {
        vc.dismiss(animated: true, completion: nil)
    }
}
