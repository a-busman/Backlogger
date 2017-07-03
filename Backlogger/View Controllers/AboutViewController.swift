//
//  AboutViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 6/25/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    let urlStrings: [String] = [
        "https://github.com/a-busman",
        "https://giantbomb.com/api",
        "https://github.com/Alamofire",
        "https://realm.io",
        "https://github.com/onevcat/Kingfisher",
        "https://github.com/MailOnline/ImageViewer",
        "https://steamcommunity.com/dev",
        "https://fabric.io/kits/android/crashlytics"
    ]
    @IBAction func tappedLink(sender: UITapGestureRecognizer) {
        guard let view = sender.view else {
            return
        }
        
        UIApplication.shared.open(URL(string: self.urlStrings[view.tag - 1])!, options: [:], completionHandler: nil)
    }
}
