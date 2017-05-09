//
//  PlaylistAddTableCellView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/7/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

protocol PlaylistAddTableCellViewDelegate {
    func addTapped(_ row: Int)
    func removeTapped(_ row: Int)
}

class PlaylistAddTableCellView: UIViewController {
    
    @IBOutlet weak var artView:          UIImageView?
    @IBOutlet weak var artViewBorder:    UIView?
    @IBOutlet weak var titleLabel:       UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var rightImage:       UIImageView?
    @IBOutlet weak var addButton:        UIButton?
    
    @IBOutlet weak var rightTrailingLayoutConstraint: NSLayoutConstraint?
    
    enum ImageSource {
        case Placeholder
        case Downloaded
    }
    
    enum PlaylistState {
        case add
        case remove
    }
    
    var delegate: PlaylistAddTableCellViewDelegate?
    var addButtonHidden = true
    private var _playlistState = PlaylistState.add
    
    var imageSource: ImageSource = .Placeholder
    
    var row: Int!
    
    var playlistState: PlaylistState {
        get {
            return self._playlistState
        }
        set(newState) {
            self._playlistState = newState
            if newState == .remove {
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.addButton?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
                })
                UIView.transition(with: self.addButton!, duration: 0.1, options: .transitionCrossDissolve, animations: {
                    self.addButton?.setImage(#imageLiteral(resourceName: "remove_red_circle"), for: .normal)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 0.1, animations: {
                    self.addButton?.transform = CGAffineTransform.identity
                })
                UIView.transition(with: self.addButton!, duration: 0.1, options: .transitionCrossDissolve, animations: {
                    self.addButton?.setImage(#imageLiteral(resourceName: "add_green_circle"), for: .normal)
                }, completion: nil)
            }
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(_ row: Int) {
        super.init(nibName: nil, bundle: nil)
        self.row = row
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if playlistState == .add {
            self.addButton?.setImage(#imageLiteral(resourceName: "add_green_circle"), for: .normal)
        } else {
            self.addButton?.setImage(#imageLiteral(resourceName: "remove_red_circle"), for: .normal)
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.addButton?.isHidden = self.addButtonHidden
        if self.addButtonHidden {
            self.rightTrailingLayoutConstraint?.constant = -10.0
        }
    }
    
    @IBAction func addButtonTapped(sender: UIButton!) {
        if self.playlistState != .remove{
            self.delegate?.addTapped(self.row)
            //} else {
            //    self.delegate?.removeTapped(self.row)
        }
    }
}
