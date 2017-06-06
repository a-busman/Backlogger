//
//  PlaylistAddTableCellView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/7/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import Kingfisher

protocol PlaylistAddTableCellDelegate {
    func handleTap(sender: UITapGestureRecognizer)
}

class PlaylistAddTableCell: UITableViewCell {
    @IBOutlet weak var artView:          UIImageView?
    @IBOutlet weak var artViewBorder:    UIView?
    @IBOutlet weak var titleLabel:       UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var rightLabel:       UILabel?
    
    var tapRecognizer:       UITapGestureRecognizer!
    
    @IBOutlet weak var titleCenterLayoutConstraint:   NSLayoutConstraint?
    @IBOutlet weak var titleLeadingLayoutConstraint:  NSLayoutConstraint?
    @IBOutlet weak var titleTrailingLayoutConstraint: NSLayoutConstraint?
    
    enum PlaylistState {
        case add
        case remove
        case `default`
    }
    
    var delegate: PlaylistAddTableCellDelegate?
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.delegate = nil
        self._playlistState = .add
        self.isHandleHidden = false
        self.game = nil
        self.artImage = nil
        self.imageUrl = nil
        self.cacheCompletionHandler = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        self.contentView.addGestureRecognizer(self.tapRecognizer)
        if playlistState == .add {
            self.artViewBorder?.isHidden = true
            self.descriptionLabel?.isHidden = true
            self.rightLabel?.isHidden = true
            self.titleLabel?.text = "Add Games"
            self.titleLabel?.textColor = Util.appColor
            self.titleCenterLayoutConstraint?.constant = 0
            self.titleLeadingLayoutConstraint?.constant = 10
        } else {
            self.artViewBorder?.isHidden = false
            self.descriptionLabel?.isHidden = false
            self.rightLabel?.isHidden = !self.isHandleHidden
            self.tapRecognizer?.isEnabled = false
            if self.game != nil {
                self.titleLabel?.text = self.game!.gameFields?.name
                self.titleLabel?.textColor = .black
                self.titleCenterLayoutConstraint?.constant = -10
                self.titleLeadingLayoutConstraint?.constant = 67
                self.titleTrailingLayoutConstraint?.constant = self.isHandleHidden ? 55.0 : 0.0
                self.descriptionLabel?.text = self.game!.platform?.name
                self.rightLabel?.text = "\(self.game!.progress)%"
                if self.imageUrl != nil {
                    self.artView?.kf.setImage(with: self.imageUrl, placeholder: #imageLiteral(resourceName: "table_placeholder_light"), completionHandler: self.cacheCompletionHandler)
                }
            }
        }
    }
    
    func set(image: UIImage) {
        self.artImage = image
        self.artView?.image = image
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        if self.playlistState == .add {
            self.delegate?.handleTap(sender: sender)
        }
    }
}
