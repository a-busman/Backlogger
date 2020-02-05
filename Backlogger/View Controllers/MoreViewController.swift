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
import GoogleMobileAds

class MoreViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var plainLoadingView: UIView?
    @IBOutlet weak var plainActivityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var progressCollectionView: UICollectionView?
    
    let progressReuseId = "progress_cell"
    
    var steamVc: UINavigationController?
    var adBannerView: GADBannerView!
    let generalStrings: [String] = ["Link Steam Account", "Wishlist", "About"]
    let dataStrings: [String] = ["Import", "Export", "Reset Data"]
    var iaps: [String] = ["Remove Ads", "Restore Purchases"]
    
    var iapProduct: SKProduct?
    var iapPrice: String?
    private var _isAdVisible = false
    var isAdVisible: Bool {
        get {
            return self._isAdVisible
        }
        set(newValue) {
            self._isAdVisible = newValue
            if newValue {
                self.tableView?.contentInset.bottom = self.tableDefaultInset + Util.adContentInset
            } else {
                self.tableView?.contentInset.bottom = self.tableDefaultInset
                self.adBannerView.removeFromSuperview()
            }
        }
    }
    private var tableDefaultInset: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.tableFooterView = self.progressCollectionView
        self.progressCollectionView?.register(UINib(nibName: "ProgressCell", bundle: nil), forCellWithReuseIdentifier: self.progressReuseId)
        self.progressCollectionView?.backgroundColor = .clear
        let showAds = Util.shouldShowAds()
        if showAds {
            self.adBannerView = Util.getNewBannerAd(for: self)
            self.isAdVisible = true
            IAPManager.shared.getProducts { (result) in
                switch result {
                case .success(let products):
                    if products.count == 1 {
                        self.iapProduct = products.first!
                        self.iapPrice = IAPManager.shared.getPriceFormatted(for: self.iapProduct!)
                        DispatchQueue.main.async {
                            self.tableView?.reloadRows(at: [IndexPath(row: 0, section: 2), IndexPath(row: 1, section: 2)], with: .automatic)
                        }
                    }
                case .failure(_):
                    NSLog("Failed to get in-app products")
                }
            }
        } else {
            self.iaps = ["Ads removed!"]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Util.shouldShowAds() {
            if !self.isAdVisible {
                self.isAdVisible = true
            }
        } else {
            if self.isAdVisible {
                self.isAdVisible = false
            }
            self.iaps = ["Ads removed!"]
        }
        self.refreshCells()
    }
    
    func refreshCells() {
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
    
    private func removeAds() {
        self.isAdVisible = false
    }
    
    private func showIAPError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "Could not complete purchase. \(error.localizedDescription)", preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .cancel)
        
        alert.addAction(action)
        
        self.present(alert, animated: true)
    }
    
    @discardableResult func purchase(product: SKProduct) -> Bool {
        if !IAPManager.shared.canMakePayments() {
            return false
        } else {
            IAPManager.shared.buy(product: product) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_): self.removeAds()
                    case .failure(let error): self.showIAPError(error)
                    }
                }
            }
            return true
        }
    }
    
    func restorePurchases() {
        IAPManager.shared.restorePurchases { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        self.removeAds()
                    } else {
                        NSLog("No products to be restored")
                    }

                case .failure(let error): self.showIAPError(error)
                }
            }
        }
    }
}

extension MoreViewController: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        Util.showBannerAd(in: self.view, banner: self.adBannerView)
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.generalStrings.count
        case 1:
            return self.dataStrings.count
        case 2:
            return self.iaps.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        cell.isUserInteractionEnabled = true
        cell.textLabel?.isEnabled = true
        if indexPath.section == 0 {
            if indexPath.row == 0,
               let steamName = UserDefaults.standard.value(forKey: "steamName") as? String {
                    cell.textLabel?.text = "Unlink Steam Account"
                    cell.detailTextLabel?.textColor = .secondaryLabel
                    cell.detailTextLabel?.text = steamName
                
            } else {
                cell.textLabel?.text = self.generalStrings[indexPath.row]
                cell.detailTextLabel?.text = ""
            }
        } else if indexPath.section == 1 {
            cell.textLabel?.text = self.dataStrings[indexPath.row]
            cell.detailTextLabel?.text = ""
        } else if indexPath.section == 2 {
            cell.textLabel?.text = self.iaps[indexPath.row]
            if indexPath.row == 0 {
                cell.detailTextLabel?.textColor = .label
                cell.detailTextLabel?.text = self.iapPrice
            } else {
                cell.detailTextLabel?.text = ""
            }
            if self.iapProduct == nil || !Util.shouldShowAds() {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.isEnabled = false
            }
        }
        return cell
    }
    
    @objc func tappedDone(sender: UIBarButtonItem) {
        self.steamVc?.dismiss(animated: true, completion: nil)
        self.refreshCells()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
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
                        self.view.isUserInteractionEnabled = false
                        autoreleasepool {
                            let realm = try! Realm()
                            if let platform = realm.object(ofType: Platform.self, forPrimaryKey: Steam.steamPlatformIdNumber) {
                                let ownedGames = platform.ownedGames
                                for game in ownedGames {
                                    game.delete()
                                }
                            }
                        }
                        self.view.isUserInteractionEnabled = true
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
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                // Remove Ads
                if self.iapProduct != nil {
                    let alertView = UIAlertController(title: "Remove Ads", message: "Would you like to buy me a muffin and remove all ads at the same time?", preferredStyle: .alert)
                    let buyButton = UIAlertAction(title: "Buy (\(self.iapPrice!))", style: .default, handler: { action in
                        self.purchase(product: self.iapProduct!)
                    })
                    let cancelButton = UIAlertAction(title: "No!", style: .cancel)
                    
                    alertView.addAction(buyButton)
                    alertView.addAction(cancelButton)
                    self.present(alertView, animated: true)
                }
            } else {
                // Restore Purchases
                if self.iapProduct != nil {
                    let alertView = UIAlertController(title: "Restore Purchase", message: "Would you like to restore your purchase?", preferredStyle: .alert)
                    let buyButton = UIAlertAction(title: "Restore", style: .default, handler: { action in
                        self.restorePurchases()
                    })
                    let cancelButton = UIAlertAction(title: "No!", style: .cancel)
                    
                    alertView.addAction(buyButton)
                    alertView.addAction(cancelButton)
                    self.present(alertView, animated: true)
                }
            }
        }
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
    func getGames(with steamId: String) {
        Steam.getUserGameList(with: steamId) { results in
            if let listError = results.error {
                NSLog(listError.localizedDescription)
            } else {
                if results.value!.count > 0 {
                    let tabBar = self.tabBarController as? RootViewController
                    if tabBar != nil {
                        tabBar!.steamLoaderVisibility(true)
                    }
                    Steam.matchGiantBombGames(with: results.value!, progressHandler: { progress, total in
                        if tabBar != nil {
                            tabBar!.progress = (progress * 100) / total
                        }
                    }) { matched, unmatched in
                        if tabBar != nil {
                            tabBar!.steamLoaderVisibility(false)
                        }
                        if let gamesError = matched.error {
                            NSLog(gamesError.localizedDescription)
                        } else {
                            NSLog("Done")
                            self.view.isUserInteractionEnabled = true
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
                                if dedupedList.count > 0 {
                                    let vc = self.storyboard!.instantiateViewController(withIdentifier: "add_from_steam") as! UINavigationController
                                    let rootView = vc.viewControllers.first! as! AddSteamGamesViewController
                                    vc.navigationBar.tintColor = .white
                                    rootView.delegate = self
                                    rootView.gameFields = dedupedList
                                    self.present(vc, animated: true, completion: nil)
                                } else {
                                    let alert = UIAlertController(title: "No Steam games to add", message: nil, preferredStyle: .alert)
                                    let ok = UIAlertAction(title: "Okay", style: .default, handler: nil)
                                    
                                    alert.addAction(ok)
                                    self.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                } else {
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
    }
    func got(steamId: String) {
        defer {
            self.tableView?.reloadData()
            self.steamVc?.dismiss(animated: true, completion: nil)
            self.refreshCells()
        }
        UserDefaults.standard.set(steamId, forKey: "steamId")
        
        Steam.getUserName(with: steamId) { results in
            if let error = results.error {
                NSLog(error.localizedDescription)
                // Could not get steamID
            } else {
                UserDefaults.standard.set(results.value!, forKey: "steamName")
                self.tableView?.reloadData()
            }
        }
        self.getGames(with: steamId)
    }

    func got(username: String) {
        defer {
            self.tableView?.reloadData()
            self.steamVc?.dismiss(animated: true, completion: nil)
            self.refreshCells()
        }
        UserDefaults.standard.set(username, forKey: "steamName")
        Steam.getUserId(with: username) { results in
            if let error = results.error {
                NSLog(error.localizedDescription)
                // Could not get steamID
            } else {
                UserDefaults.standard.set(results.value!, forKey: "steamId")
                self.getGames(with: results.value!)
            }
        }
    }
}

extension MoreViewController: AddSteamGamesViewControllerDelegate {
    func didSelectSteamGames(vc: AddSteamGamesViewController, games: [GameField]) {
        defer {
            self.view.isUserInteractionEnabled = true
            self.refreshCells()
        }
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
            self.view.isUserInteractionEnabled = false
            for game in games {
                let newGame = Game()
                newGame.inLibrary = true
                newGame.fromSteam = true
                newGame.add(game, steamPlatform)
            }
            self.plainLoadingView?.isHidden = true
            self.plainActivityIndicator?.stopAnimating()
        }
    }
    
    func didDismiss(vc: AddSteamGamesViewController) {
        vc.dismiss(animated: true, completion: nil)
        self.refreshCells()
    }
}
