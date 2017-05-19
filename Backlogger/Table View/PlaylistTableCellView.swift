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
    
    var image: UIImage?
    
    enum CellState {
        case new
        case title
        case full
    }
    
    private var _state: CellState = .new
    
    var playlist: Playlist?
    
    var state: CellState {
        get {
            return self._state
        }
        set(newState) {
            self._state = newState
            if self.isViewLoaded {
                if newState == .new {
                    self.titleLabel?.text = "New Playlist..."
                    self.titleLabel?.textColor = Util.appColor
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
            }
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

        if let playlist = self.playlist {
            self.titleLabel?.text = playlist.name
            self.titleLabel?.textColor = .black
            self.showImage()
            if playlist.descriptionText == nil {
                self.titleCenterLayoutConstraint?.constant = 0.0
                self.descLabel?.text = ""
                self.descLabel?.isHidden = true
            } else {
                self.titleCenterLayoutConstraint?.constant = -14.0
                self.descLabel?.text = playlist.descriptionText
                self.descLabel?.isHidden = false
            }
        } else {
            self.titleLabel?.text = "New Playlist..."
            self.titleLabel?.textColor = Util.appColor
            self.titleCenterLayoutConstraint?.constant = 0.0
            self.descLabel?.text = ""
            self.descLabel?.isHidden = true
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
    
    func showImage() {
        if let image = self.image {
            self.imageView?.image = image
            self.blurView?.isHidden = true
        }
    }
    
    func hideImage() {
        self.blurView?.isHidden = false
        self.imageView?.image = #imageLiteral(resourceName: "new_playlist")
    }
}
