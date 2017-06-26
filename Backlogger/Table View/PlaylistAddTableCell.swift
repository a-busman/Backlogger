//
//  PlaylistAddTableCellView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/7/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import Kingfisher

class PlaylistAddTableCell: UITableViewCell {
    @IBOutlet weak var artView:          UIImageView?
    @IBOutlet weak var artViewBorder:    UIView?
    @IBOutlet weak var titleLabel:       UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var rightLabel:       UILabel?
    @IBOutlet weak var percentImage:     UIImageView?
    
    @IBOutlet weak var titleCenterLayoutConstraint:   NSLayoutConstraint?
    @IBOutlet weak var titleLeadingLayoutConstraint:  NSLayoutConstraint?
    @IBOutlet weak var titleTrailingLayoutConstraint: NSLayoutConstraint?
    
    enum PlaylistState {
        case add
        case remove
        case `default`
    }
    
    private var _playlistState = PlaylistState.add
    
    var isHandleHidden = false
    
    var game: Game?
    
    var artImage: UIImage?
    
    var imageUrl: URL?
    var cacheCompletionHandler: CompletionHandler?
    
    var playlistState: PlaylistState {
        get {
            return self._playlistState
        }
        set(newState) {
            self._playlistState = newState
        }
    }
    
    let percentageImages: [Int: UIImage] = [
        0: #imageLiteral(resourceName: "0-percent"),
        10: #imageLiteral(resourceName: "10-percent"),
        20: #imageLiteral(resourceName: "20-percent"),
        30: #imageLiteral(resourceName: "30-percent"),
        40: #imageLiteral(resourceName: "40-percent"),
        50: #imageLiteral(resourceName: "50-percent"),
        60: #imageLiteral(resourceName: "60-percent"),
        70: #imageLiteral(resourceName: "70-percent"),
        80: #imageLiteral(resourceName: "80-percent"),
        90: #imageLiteral(resourceName: "90-percent"),
        100: #imageLiteral(resourceName: "100-percent")
    ]
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self._playlistState = .add
        self.isHandleHidden = false
        self.game = nil
        self.artImage = nil
        self.imageUrl = nil
        self.cacheCompletionHandler = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Not using the right label for now
        self.rightLabel?.isHidden = true
        if playlistState == .add {
            self.artViewBorder?.isHidden = true
            self.descriptionLabel?.isHidden = true
            self.percentImage?.isHidden = true
            self.titleLabel?.text = "Add Games"
            self.titleLabel?.textColor = Util.appColor
            self.titleCenterLayoutConstraint?.constant = 0
            self.titleLeadingLayoutConstraint?.constant = 10
        } else {
            self.artViewBorder?.isHidden = false
            self.descriptionLabel?.isHidden = false
            self.percentImage?.isHidden = !self.isHandleHidden
            if self.game != nil {
                self.titleLabel?.text = self.game!.gameFields?.name
                self.titleLabel?.textColor = .black
                self.titleCenterLayoutConstraint?.constant = -10
                self.titleLeadingLayoutConstraint?.constant = 67
                self.titleTrailingLayoutConstraint?.constant = self.isHandleHidden ? -40.0 : 0.0
                self.descriptionLabel?.text = self.game!.platform?.name
                self.percentImage?.image = self.percentageImages[self.game!.progress]!
            }
        }
    }
    
    func set(image: UIImage) {
        self.artImage = image
        self.artView?.image = image
    }
    
    func loadImage(url: URL) {
        if self.imageUrl != url {
            self.artView?.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "table_placeholder_light"), completionHandler: self.cacheCompletionHandler)
            self.imageUrl = url
        }
    }
}
