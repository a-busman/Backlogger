//
//  TodayViewController.swift
//  BackloggerWidget
//
//  Created by Alex Busman on 6/19/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import NotificationCenter
import RealmSwift
import Kingfisher

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var artView:          UIImageView?
    @IBOutlet weak var minusView:        UIView?
    @IBOutlet weak var plusView:         UIView?
    @IBOutlet weak var vibrancyView:     UIVisualEffectView?
    @IBOutlet weak var percentLabel:     UILabel?
    @IBOutlet weak var completeButton:   UIView?
    @IBOutlet weak var completeVibrancy: UIVisualEffectView?
    @IBOutlet weak var completeLabel:    UILabel?
    
    var game: Game?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
        
        let dir: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.BackloggerWidgetSharing")!
        let realmPath = dir.appendingPathComponent("db.realm")
        
        let config = Realm.Configuration(fileURL: realmPath, schemaVersion: 2, migrationBlock: {
            migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                // auto migrate
            }
        })
        Realm.Configuration.defaultConfiguration = config
        self.vibrancyView?.effect = UIVibrancyEffect.widgetPrimary()
        self.completeVibrancy?.effect = UIVibrancyEffect.widgetSecondary()
        self.loadNowPlaying()
        let mask = UIImageView(image: #imageLiteral(resourceName: "check_mask"))
        self.completeButton?.mask = self.game!.finished ? mask : nil
        
        self.percentLabel?.text = "\(self.game!.progress)%"
        
        self.completeLabel?.text = self.game!.finished ? "Finished" : "In Progress"
        
        let minusMask = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0))
        let plusMask = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0))
        
        minusMask.image = #imageLiteral(resourceName: "minus_mask")
        plusMask.image = #imageLiteral(resourceName: "add_mask")
        self.minusView?.mask = minusMask
        self.plusView?.mask = plusMask
        
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //ImageCache.default.clearMemoryCache()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }
    
    @IBAction func minusTapped(sender: UITapGestureRecognizer) {
        if self.game!.progress > 0 {
            self.game?.update {
                self.game?.progress -= 10
            }
            self.percentLabel?.text = "\(self.game!.progress)%"
        }
        UIView.animate(withDuration: 0.1, animations: {self.minusView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)}, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {self.minusView?.transform = CGAffineTransform.identity})
        })
    }
    
    @IBAction func plusTapped(sender: UITapGestureRecognizer) {
        if self.game!.progress < 100 {
            self.game?.update {
                self.game?.progress += 10
            }
            self.percentLabel?.text = "\(self.game!.progress)%"
        }
        UIView.animate(withDuration: 0.1, animations: {self.plusView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)}, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {self.plusView?.transform = CGAffineTransform.identity})
        })
    }
    
    @IBAction func artTapped(sender: UITapGestureRecognizer) {
        self.extensionContext?.open(URL(string: "backlogger://")! , completionHandler: nil)
    }
    
    @IBAction func completeTapped(sender: UITapGestureRecognizer) {
        self.game?.update {
            self.game?.finished = !self.game!.finished
        }
        if self.game!.finished {
            let checkView = UIImageView(image: #imageLiteral(resourceName: "check_mask"))
            self.completeButton?.mask = checkView
            self.completeLabel?.text = "Finished"
        } else {
            self.completeButton?.mask = nil
            self.completeLabel?.text = "In Progress"
        }
        UIView.animate(withDuration: 0.1, animations: {self.completeButton?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)}, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {self.completeButton?.transform = CGAffineTransform.identity})
        })
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        self.loadNowPlaying()
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func loadNowPlaying() {
        autoreleasepool {
            let realm = try! Realm()
            let playlists = realm.objects(Playlist.self)
            let nowPlaying = playlists.filter("isNowPlaying = true")
            self.game = nowPlaying.first?.games.first
        }
        self.artView?.kf.setImage(with: URL(string: self.game!.gameFields!.image!.smallUrl!), placeholder: nil, options: nil, progressBlock: nil, completionHandler: {
            (image, error, cacheType, imageUrl) in
            if image != nil {
                UIView.transition(with: self.artView!,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.artView?.image = image },
                                  completion: nil)
            }
        })
    }
}