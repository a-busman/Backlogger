//
//  PlaylistTableCellView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/3/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class PlaylistTableCellView: UIViewController {
    @IBOutlet weak var imageView:  UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var descLabel:  UILabel?
    @IBOutlet weak var blurView:   UIVisualEffectView?
    
    @IBOutlet weak var titleCenterLayoutConstraint: NSLayoutConstraint?
    
    enum CellState {
        case new
        case title
        case full
    }
    
    private var _state: CellState = .new
    
    var state: CellState {
        get {
            return self._state
        }
        set(newState) {
            if newState == .new {
                self.titleLabel?.text = "New Playlist..."
                self.titleLabel?.textColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
                self.titleCenterLayoutConstraint?.constant = 0.0
                self.descLabel?.text = ""
                self.descLabel?.isHidden = true
            } else if newState == .title {
                self.titleLabel?.textColor = .black
                self.titleCenterLayoutConstraint?.constant = 0.0
                self.descLabel?.text = ""
                self.descLabel?.isHidden = true
            } else {
                self.titleLabel?.textColor = .black
                self.titleCenterLayoutConstraint?.constant = -14.0
                self.descLabel?.isHidden = false
            }
            self.view.layoutIfNeeded()
            self._state = newState
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self._state == .new {
            self.titleLabel?.text = "New Playlist..."
            self.titleLabel?.textColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
            self.titleCenterLayoutConstraint?.constant = 0.0
            self.descLabel?.text = ""
            self.descLabel?.isHidden = true
        } else if self._state == .title {
            self.titleLabel?.textColor = .black
            self.titleCenterLayoutConstraint?.constant = 0.0
            self.descLabel?.text = ""
            self.descLabel?.isHidden = true
        } else {
            self.titleLabel?.textColor = .black
            self.titleCenterLayoutConstraint?.constant = -14.0
            self.descLabel?.isHidden = false
        }
        self.view.setNeedsLayout()
    }
    
    override func viewDidLayoutSubviews() {
        let lineView = UIView()
        lineView.backgroundColor = .lightGray
        lineView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(lineView)
        
        NSLayoutConstraint(item: lineView,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: self.titleLabel,
                           attribute: .leading,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: lineView,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .trailing,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: lineView,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: -0.5
            ).isActive = true
        NSLayoutConstraint(item: lineView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
    }
}
