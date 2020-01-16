//
//  RootViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class RootViewController: UITabBarController {
    let steamLoaderViewController = SteamLoaderViewController()
    private var bottomAnchor = NSLayoutConstraint()
    
    private let MINIMIZED_SIZE: CGFloat = 30
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.insertSubview(self.steamLoaderViewController.view, belowSubview: self.tabBar)
        self.steamLoaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.bottomAnchor = self.steamLoaderViewController.view.bottomAnchor.constraint(equalTo: self.tabBar.topAnchor)
        self.bottomAnchor.isActive = true
        self.steamLoaderViewController.view.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.steamLoaderViewController.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.bottomAnchor.constant = self.MINIMIZED_SIZE
    }
    
    func steamLoaderVisibility(_ visibile: Bool) {
        if visibile {
            self.bottomAnchor.constant = 0
        } else {
            self.bottomAnchor.constant = self.MINIMIZED_SIZE
        }
        UIView.animate(withDuration: 1.0) {
            self.view.layoutSubviews()
        }
    }
}
