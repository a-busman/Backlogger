//
//  PlaylistFooter.swift
//  Backlogger
//
//  Created by Alex Busman on 5/16/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

protocol PlaylistFooterDelegate {
    func addTapped()
}

class PlaylistFooter: UIViewController {
    @IBOutlet weak var addView: UIView?
    @IBOutlet weak var countLabel: UILabel?
    @IBOutlet weak var addButton: UIButton?
    private var _showButton = false
    
    var count = 0
    var percent = 0
    var showButton: Bool {
        get {
            return self._showButton
        }
        set(newValue) {
            self._showButton = newValue
            if self.isViewLoaded {
                self.view.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.showButton ? 136.0 : 40.0)
                self.addView?.isHidden = !newValue
            }
        }
    }
    
    var delegate: PlaylistFooterDelegate?
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addView?.isHidden = !self._showButton
        self.view.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.showButton ? 136.0 : 40.0)
        self.update(count: self.count)
    }
    
    func update(percent: Int) {
        self.percent = percent
        self.refreshLabel()
    }
    
    func update(count: Int) {
        self.count = count
        self.refreshLabel()
    }
    
    private func refreshLabel() {
        if self.count != 1 {
            self.countLabel?.text = "\(self.count) Games, \(self.percent)% complete"
        } else {
            self.countLabel?.text = "\(self.count) Game, \(self.percent)% complete"
        }
    }
    
    @IBAction func addTapped(sender: UIButton) {
        self.delegate?.addTapped()
    }
}
