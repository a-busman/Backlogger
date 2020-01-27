//
//  AppDelegate.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Fabric
import Crashlytics
import Zephyr
import Firebase
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Fabric.with([Crashlytics.self])
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        self.createDirectories()
        let dir: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.BackloggerSharing")!
        let realmPath = dir.appendingPathComponent("db.realm")
        
        let config = Realm.Configuration(fileURL: realmPath, schemaVersion: 2, migrationBlock: {
            migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                // auto migrate
            }
        })
        Realm.Configuration.defaultConfiguration = config
        self.compactRealm(at: realmPath)
        
        (UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])).tintColor = Util.appColor
        UISlider.appearance().tintColor = Util.appColor
        self.window?.tintColor = Util.appColor
        Zephyr.syncUbiquitousKeyValueStoreOnChange = true
        if Util.isICloudContainerAvailable {
            Zephyr.addKeysToBeMonitored(keys: ["librarySortType", "libraryAscending", "steamName", "steamId", "libraryShowWishlist", "playlistSortType", "playlistAscending", "hideComplete"])
            Zephyr.sync()
        }
        
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = UIColor(named: "App")
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
               
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            self.shortcutItem = shortcutItem
            return false
        }
        
        return true
    }

    func handleShortcut(_ shortcutItem:UIApplicationShortcutItem ) -> Bool {
        var succeeded = false
        
        if(shortcutItem.type == "a-busman.backlogger.appshortcut.add-game") {
            let rootTabBarController = window!.rootViewController as? UITabBarController
            
            rootTabBarController?.selectedIndex = 2
            let libraryNavigationViewController = rootTabBarController?.selectedViewController as? UINavigationController
            let libraryViewController = libraryNavigationViewController?.viewControllers.first as? LibraryViewController
            
            libraryViewController?.performSegue(withIdentifier: "add_game_to_library", sender: nil)

            succeeded = true
            
        }
        
        return succeeded
        
    }
    
    func createDirectories() {
        let playlistsFolder = Util.getPlaylistImagesDirectory()
        
        if !FileManager.default.fileExists(atPath: playlistsFolder.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: playlistsFolder, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        }
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard let shortcut = shortcutItem else { return }

        let _ = self.handleShortcut(shortcut)
        
        self.shortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func compactRealm(at realmPath: URL) {
        let defaultParentURL = realmPath.deletingLastPathComponent()
        let compactedURL = defaultParentURL.appendingPathComponent("default-compact.realm")
        autoreleasepool {
            let realm = try! Realm()
            try! realm.writeCopy(toFile: compactedURL)
        }
        try! FileManager.default.removeItem(at: realmPath)
        try! FileManager.default.moveItem(at: compactedURL, to: realmPath)
    }
    
}

