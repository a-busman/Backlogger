//
//  AboutViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 6/25/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    @IBOutlet weak var versionLabel: UILabel?
    
    let urlStrings: [String] = [
        "https://github.com/a-busman",
        "https://giantbomb.com/api",
        "https://github.com/Alamofire",
        "https://realm.io",
        "https://github.com/onevcat/Kingfisher",
        "https://github.com/MailOnline/ImageViewer",
        "https://steamcommunity.com/dev",
        "https://fabric.io/kits/android/crashlytics",
        "https://github.com/marmelroy/Zip",
        "https://github.com/ArtSabintsev/Zephyr"
    ]
    @IBAction func tappedLink(sender: UITapGestureRecognizer) {
        guard let view = sender.view else {
            return
        }
        
        UIApplication.shared.open(URL(string: self.urlStrings[view.tag - 1])!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nsObject: Any? = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let version = nsObject as! String
        self.versionLabel?.text = "Version \(version)"

    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
