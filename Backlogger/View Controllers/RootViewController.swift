//
//  RootViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class RootViewController: UITabBarController {
    private let progressBar = UIProgressView()
    private var bottomAnchor = NSLayoutConstraint()
    
    private var _progress: Int = 0
    
    private let MINIMIZED_SIZE: CGFloat = 5
    
    var progress: Int {
        get {
            return self._progress
        }
        set(newValue) {
            if newValue >= 0 && newValue <= 100 {
                self._progress = newValue
                self.progressBar.setProgress(Float(newValue) / 100.0, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.insertSubview(self.progressBar, belowSubview: self.tabBar)
        self.progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.bottomAnchor = self.progressBar.bottomAnchor.constraint(equalTo: self.tabBar.topAnchor)
        self.bottomAnchor.isActive = true
        self.progressBar.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.progressBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
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
