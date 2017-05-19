//
//  PlaylistAddTableCellView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/7/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

protocol PlaylistAddTableCellViewDelegate {
    func handleLongPress(sender: UILongPressGestureRecognizer)
    func handleTap(sender: UITapGestureRecognizer)
}

class PlaylistAddTableCellView: UIViewController {
    @IBOutlet weak var artView:          UIImageView?
    @IBOutlet weak var artViewBorder:    UIView?
    @IBOutlet weak var titleLabel:       UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var moveHandle:       UIImageView?
    @IBOutlet weak var rightLabel:       UILabel?
    @IBOutlet weak var truncGradient:    UIView?
    
    @IBOutlet weak var longPressRecognizer: UILongPressGestureRecognizer?
    @IBOutlet weak var tapRecognizer:       UITapGestureRecognizer?
    
    @IBOutlet weak var titleCenterLayoutConstraint:   NSLayoutConstraint?
    @IBOutlet weak var titleLeadingLayoutConstraint:  NSLayoutConstraint?
    
    enum ImageSource {
        case Placeholder
        case Downloaded
    }
    
    enum PlaylistState {
        case add
        case remove
    }
    
    var delegate: PlaylistAddTableCellViewDelegate?
    private var _playlistState = PlaylistState.add
    
    var didLayout = false
    
    let truncateGradientLayer = CAGradientLayer()
    
    var imageSource: ImageSource = .Placeholder
    
    var isHandleHidden = false
    
    var game: Game?
    
    var image: UIImage?
    
    var playlistState: PlaylistState {
        get {
            return self._playlistState
        }
        set(newState) {
            self._playlistState = newState
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
        if playlistState == .add {
            self.artViewBorder?.isHidden = true
            self.descriptionLabel?.isHidden = true
            self.moveHandle?.isHidden = true
            self.rightLabel?.isHidden = true
            self.titleLabel?.text = "Add Games"
            self.titleLabel?.textColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
            self.titleCenterLayoutConstraint?.constant = 0
            self.titleLeadingLayoutConstraint?.constant = 10
        } else {
            self.moveHandle?.isHidden = self.isHandleHidden
            self.rightLabel?.isHidden = !self.isHandleHidden
            self.tapRecognizer?.isEnabled = false
            if self.game != nil {
                self.titleLabel?.text = self.game!.gameFields?.name
                self.descriptionLabel?.text = self.game!.platform?.name
                self.rightLabel?.text = "\(self.game!.progress)%"
                self.artView?.image = self.image
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !self.didLayout {
            let lineView = UIView()
            lineView.backgroundColor = .lightGray
            lineView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(lineView)
            if playlistState == .add {
                NSLayoutConstraint(item: lineView,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: self.titleLabel,
                                   attribute: .leading,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true

            } else {
                self.truncateGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: (self.truncGradient?.frame.width)!, height: (self.truncGradient?.frame.height)!)
                let whiteColor = UIColor(white: 1.0, alpha: 1.0).cgColor
                let clearColor = UIColor(white: 1.0, alpha: 0.0).cgColor
                self.truncateGradientLayer.colors = [clearColor, whiteColor]
                let newLocation = 35.0/(self.truncGradient?.frame.width)!
                self.truncateGradientLayer.locations = [0.0, NSNumber(value: Float(newLocation))]
                self.truncateGradientLayer.startPoint = .zero
                self.truncateGradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
                self.truncGradient?.layer.addSublayer(self.truncateGradientLayer)
                self.view.bringSubview(toFront: self.moveHandle!)
                NSLayoutConstraint(item: lineView,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: self.artView,
                                   attribute: .centerX,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
            }
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
            self.didLayout = true
        }
    }
    
    func set(image: UIImage) {
        self.image = image
        self.artView?.image = image
    }
    
    func showHandle() {
        if self.isViewLoaded {
            self.moveHandle!.isHidden = false
            self.rightLabel!.isHidden = true
            self.isHandleHidden = false
        }
    }
    
    func hideHandle() {
        if self.isViewLoaded {
            self.moveHandle!.isHidden = true
            self.rightLabel!.isHidden = false
            self.isHandleHidden = true
        }
    }
    
    func toggleHandle() {
        if self.isViewLoaded {
            UIView.transition(with: self.moveHandle!, duration: 0.15, options: .transitionCrossDissolve, animations: {
                self.moveHandle!.isHidden = !self.moveHandle!.isHidden
                self.rightLabel!.isHidden = !self.rightLabel!.isHidden
            }, completion: nil)
        }
    }
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        self.delegate?.handleLongPress(sender: sender)
    }
    
    @IBAction func handleTap(sender: UITapGestureRecognizer) {
        if self.playlistState == .add {
            self.delegate?.handleTap(sender: sender)
        }
    }
}
