//
//  PlaylistTableCellView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/3/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class PlaylistTableCell: UITableViewCell {
    @IBOutlet weak var artView:  UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var descLabel:  UILabel?
    @IBOutlet weak var blurView:   UIVisualEffectView?
    @IBOutlet weak var blurImage:  UIImageView?
    
    @IBOutlet weak var titleCenterLayoutConstraint: NSLayoutConstraint?
    
    var artImage: UIImage?
    
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
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

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
    }
    
    func showImage() {
        if let image = self.artImage {
            self.artView?.image = image
            self.blurView?.isHidden = true
        } else {
            self.blurImage?.image = #imageLiteral(resourceName: "controller_icon_lg")
        }
    }
    
    func hideImage() {
        self.blurView?.isHidden = false
        self.artView?.image = #imageLiteral(resourceName: "new_playlist")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.playlist = nil
        self._state = .new
        self.artImage = nil
    }
}
