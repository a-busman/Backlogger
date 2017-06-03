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
    func handleLongPress(sender: UILongPressGestureRecognizer)
    func handleTap(sender: UITapGestureRecognizer)
}

class PlaylistAddTableCell: UITableViewCell {
    @IBOutlet weak var artView:          UIImageView?
    @IBOutlet weak var artViewBorder:    UIView?
    @IBOutlet weak var titleLabel:       UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var moveHandle:       UIImageView?
    @IBOutlet weak var rightLabel:       UILabel?
    @IBOutlet weak var truncGradient:    UIView?
    
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer:       UITapGestureRecognizer!
    
    @IBOutlet weak var titleCenterLayoutConstraint:  NSLayoutConstraint?
    @IBOutlet weak var titleLeadingLayoutConstraint: NSLayoutConstraint?
    
    
    enum PlaylistState {
        case add
        case remove
        case `default`
    }
    
    var delegate: PlaylistAddTableCellDelegate?
    private var _playlistState = PlaylistState.add
    
    var didLayout = false
    
    let truncateGradientLayer = CAGradientLayer()
    
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
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set(newValue) {
            let clearColor = UIColor(white: 1.0, alpha: 0.0).cgColor
            if newValue == true {
                self.truncateGradientLayer.colors = [clearColor, UIColor.lightGray.cgColor]
            } else {
                self.truncateGradientLayer.colors = [clearColor, UIColor.white.cgColor]

            }
            super.isHighlighted = newValue
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.delegate = nil
        self._playlistState = .add
        self.didLayout = false
        self.isHandleHidden = false
        self.game = nil
        self.artImage = nil
        self.imageUrl = nil
        self.cacheCompletionHandler = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.moveHandle?.addGestureRecognizer(self.longPressRecognizer)
        self.longPressRecognizer.minimumPressDuration = 0.15
        self.longPressRecognizer.isEnabled = true
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        self.contentView.addGestureRecognizer(self.tapRecognizer)
        if playlistState == .add {
            self.artViewBorder?.isHidden = true
            self.descriptionLabel?.isHidden = true
            self.moveHandle?.isHidden = true
            self.rightLabel?.isHidden = true
            self.titleLabel?.text = "Add Games"
            self.titleLabel?.textColor = Util.appColor
            self.titleCenterLayoutConstraint?.constant = 0
            self.titleLeadingLayoutConstraint?.constant = 10
        } else {
            self.artViewBorder?.isHidden = false
            self.descriptionLabel?.isHidden = false
            self.moveHandle?.isHidden = self.isHandleHidden
            self.rightLabel?.isHidden = !self.isHandleHidden
            self.tapRecognizer?.isEnabled = false
            if self.game != nil {
                self.titleLabel?.text = self.game!.gameFields?.name
                self.titleLabel?.textColor = .black
                self.titleCenterLayoutConstraint?.constant = -10
                self.titleLeadingLayoutConstraint?.constant = 67
                self.descriptionLabel?.text = self.game!.platform?.name
                self.rightLabel?.text = "\(self.game!.progress)%"
                if self.imageUrl != nil {
                    self.artView?.kf.setImage(with: self.imageUrl, placeholder: #imageLiteral(resourceName: "table_placeholder_light"), completionHandler: self.cacheCompletionHandler)
                }
            }
        }
        let lineViewTag = 9001
        if let oldLineView = self.contentView.viewWithTag(lineViewTag) {
            oldLineView.removeFromSuperview()
        }

        if playlistState == .remove {
            self.truncateGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: (self.truncGradient?.frame.width)!, height: (self.truncGradient?.frame.height)!)
            let clearColor = UIColor(white: 1.0, alpha: 0.0).cgColor
            self.truncateGradientLayer.colors = [clearColor, UIColor.white.cgColor]
            let newLocation = 35.0/(self.truncGradient?.frame.width)!
            self.truncateGradientLayer.locations = [0.0, NSNumber(value: Float(newLocation))]
            self.truncateGradientLayer.startPoint = .zero
            self.truncateGradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
            self.truncGradient?.layer.addSublayer(self.truncateGradientLayer)
            self.contentView.bringSubview(toFront: self.moveHandle!)
        } else {
            let lineView = UIView()
            lineView.tag = lineViewTag
            lineView.backgroundColor = .lightGray
            lineView.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(lineView)
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
                               toItem: self.contentView,
                               attribute: .trailing,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
            NSLayoutConstraint(item: lineView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self.contentView,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: -0.5
                ).isActive = true
            NSLayoutConstraint(item: lineView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self.contentView,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
        }
        self.didLayout = true
    }
    
    func set(image: UIImage) {
        self.artImage = image
        self.artView?.image = image
    }
    
    func set(gradientColor: UIColor) {
        self.truncGradient?.backgroundColor = gradientColor
    }
    
    func showHandle() {
        self.moveHandle!.isHidden = false
        self.rightLabel!.isHidden = true
        self.isHandleHidden = false
    }
    
    func hideHandle() {
        self.moveHandle!.isHidden = true
        self.rightLabel!.isHidden = false
        self.isHandleHidden = true
    }
    
    func toggleHandle() {
        UIView.transition(with: self.moveHandle!, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.moveHandle!.isHidden = !self.moveHandle!.isHidden
            self.rightLabel!.isHidden = !self.rightLabel!.isHidden
        }, completion: nil)
    }
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        self.delegate?.handleLongPress(sender: sender)
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        if self.playlistState == .add {
            self.delegate?.handleTap(sender: sender)
        }
    }
}
