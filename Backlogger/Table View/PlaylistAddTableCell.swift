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
    @IBOutlet weak var artView:          UIImageView!
    @IBOutlet weak var artViewBorder:    UIView!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var rightLabel:       UILabel!
    @IBOutlet weak var percentView:      UIView!
    
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
    var cacheCompletionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?
    
    let percentViewController = PercentViewController()

    private var _progress: Int = 0
    
    var progress: Int {
        get {
            return self._progress
        }
        set(newValue) {
            self._progress = newValue
            self.percentViewController.progress = newValue
        }
    }
    
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
        self._playlistState = .add
        self.isHandleHidden = false
        self.game = nil
        self.artImage = nil
        self.imageUrl = nil
        self.cacheCompletionHandler = nil
        for subview in self.percentView.subviews {
            subview.removeFromSuperview()
        }
        self.percentView.isHidden = false
        self.titleLabel?.textColor = .label
        self.descriptionLabel?.textColor = .secondaryLabel
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.percentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        // Not using the right label for now
        self.rightLabel?.isHidden = true
        var progressView: UIView
        if let game = self.game {
            if game.progress != 100 {
                progressView = self.percentViewController.view
            } else {
                let progressLabel = UILabel()
                progressLabel.textColor = .white
                progressLabel.text = "100"
                progressLabel.textAlignment = .center
                progressLabel.font = UIFont.systemFont(ofSize: 6.0, weight: UIFont.Weight(rawValue: 4.0))
                progressView = UIImageView(image: #imageLiteral(resourceName: "trophy"))
                progressLabel.translatesAutoresizingMaskIntoConstraints = false
                progressView.addSubview(progressLabel)
                progressLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor, constant: -4.0).isActive = true
                progressLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor).isActive = true
            }
            self.percentView.addSubview(progressView)
            progressView.topAnchor.constraint(equalTo: self.percentView.topAnchor).isActive = true
            progressView.bottomAnchor.constraint(equalTo: self.percentView.bottomAnchor).isActive = true
            progressView.leadingAnchor.constraint(equalTo: self.percentView.leadingAnchor).isActive = true
            progressView.trailingAnchor.constraint(equalTo: self.percentView.trailingAnchor).isActive = true
        }

        if playlistState == .add {
            self.artViewBorder.isHidden = true
            self.descriptionLabel.isHidden = true
            self.percentView.isHidden = true
            self.titleLabel.text = "Add Games"
            self.titleLabel.textColor = Util.appColor
            self.titleCenterLayoutConstraint?.constant = 0
            self.titleLeadingLayoutConstraint?.constant = 10
        } else {
            self.artViewBorder.isHidden = false
            self.descriptionLabel.isHidden = false
            self.percentView.isHidden = !self.isHandleHidden || self.game!.inWishlist

            if self.game != nil {
                self.titleLabel.text = self.game!.gameFields?.name
                self.titleLabel.textColor = self.game!.inWishlist ? .tertiaryLabel : .label
                self.descriptionLabel.textColor = self.game!.inWishlist ? .tertiaryLabel : .secondaryLabel
                self.titleCenterLayoutConstraint?.constant = -10
                self.titleLeadingLayoutConstraint?.constant = 67
                self.titleTrailingLayoutConstraint?.constant = self.isHandleHidden ? -40.0 : 0.0
                self.descriptionLabel.text = self.game!.platform?.name
                self.percentViewController.progress = self.game!.progress
                self.percentViewController.complete = self.game!.finished
            }
        }
    }
    
    func set(image: UIImage) {
        self.artImage = image
        self.artView.image = image
    }
    
    func loadImage(url: URL) {
        if self.imageUrl != url, !ImageList.isDefaultPlaceholder(url: url) {
            self.artView.kf.cancelDownloadTask()
            self.artView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "table_placeholder_light"), completionHandler: self.cacheCompletionHandler)
            self.imageUrl = url
        }
    }
}
