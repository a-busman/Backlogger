//
//  TableViewCell.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import Kingfisher

protocol TableViewCellDelegate {
    func addTapped(_ row: Int)
}

class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var artView:          UIImageView!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var rightLabel:       UILabel!
    @IBOutlet weak var addButton:        UIButton!
    @IBOutlet weak var percentView:      UIView!
    
    @IBOutlet weak var rightTrailingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleBottomLayoutConstraint:   NSLayoutConstraint!
    
    let percentViewController = PercentViewController()
    
    enum LibraryState {
        case add
        case addPartial
        case addPlaylist
        case inPlaylist
        case remove
    }
    
    var delegate: TableViewCellDelegate?
    var addButtonHidden = true
    private var _libraryState: LibraryState = .add
    
    var laidOut = false
    
    var row: Int!
    
    var imageUrl: URL?
    var cacheCompletionHandler: CompletionHandler?
    
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
    
    var libraryState: LibraryState {
        get {
            return self._libraryState
        }
        set(newState) {
            self._libraryState = newState
            if newState == .remove {
                UIView.animate(withDuration: 0.1, animations: {
                    self.addButton?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
                })
                UIView.transition(with: self.addButton!, duration: 0.1, options: .transitionCrossDissolve, animations: {
                    self.addButton?.setImage(#imageLiteral(resourceName: "add_symbol_red"), for: .normal)
                }, completion: nil)
            } else if newState == .addPartial {
                UIView.animate(withDuration: 0.1, animations: {
                    self.addButton?.transform = CGAffineTransform.identity
                })
                UIView.transition(with: self.addButton!, duration: 0.1, options: .transitionCrossDissolve, animations: {
                    self.addButton?.setImage(#imageLiteral(resourceName: "add_partial"), for: .normal)
                }, completion: nil)
            } else if newState == .addPlaylist {
                UIView.animate(withDuration: 0.1, animations: {
                    self.addButton?.transform = CGAffineTransform.identity
                })
                UIView.transition(with: self.addButton!, duration: 0.1, options: .transitionCrossDissolve, animations: {
                    self.addButton?.setImage(#imageLiteral(resourceName: "add_playlist"), for: .normal)
                }, completion: nil)
            } else if newState == .inPlaylist {
                UIView.animate(withDuration: 0.1, animations: {
                    self.addButton?.transform = CGAffineTransform.identity
                })
                UIView.transition(with: self.addButton!, duration: 0.1, options: .transitionCrossDissolve, animations: {
                    self.addButton?.setImage(#imageLiteral(resourceName: "check_blue"), for: .normal)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 0.1, animations: {
                    self.addButton?.transform = CGAffineTransform.identity
                })
                UIView.transition(with: self.addButton!, duration: 0.1, options: .transitionCrossDissolve, animations: {
                    self.addButton?.setImage(#imageLiteral(resourceName: "add_symbol_blue"), for: .normal)
                }, completion: nil)
            }
        }
    }
    
    func showDetails() {
        self.titleBottomLayoutConstraint.constant = 0
        self.descriptionLabel.isHidden = false
    }
    
    func hideDetails() {
        self.titleBottomLayoutConstraint.constant = 10.25
        self.descriptionLabel.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.percentViewController.progress = self.progress
        self.percentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addButton?.isHidden = self.addButtonHidden
        if self.addButtonHidden {
            self.rightTrailingLayoutConstraint?.constant = 0.0
        } else {
            self.rightTrailingLayoutConstraint?.constant = -28.0
        }
        switch self._libraryState {
        case .addPlaylist:
            self.addButton?.setImage(#imageLiteral(resourceName: "add_playlist"), for: .normal)
            break
        case .addPartial:
            self.addButton?.setImage(#imageLiteral(resourceName: "add_partial"), for: .normal)
            break
        case .inPlaylist:
            self.addButton?.setImage(#imageLiteral(resourceName: "check_blue"), for: .normal)
            break
        default:
            self.addButton?.setImage(#imageLiteral(resourceName: "add_symbol_blue"), for: .normal)
        }

        if self.imageUrl != nil {
            self.artView?.kf.setImage(with: self.imageUrl, placeholder: #imageLiteral(resourceName: "table_placeholder_light"), completionHandler: self.cacheCompletionHandler)
        }
        
        self.percentView.addSubview(self.percentViewController.view)
        NSLayoutConstraint(item: self.percentViewController.view, attribute: .top, relatedBy: .equal, toItem: self.percentView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.percentViewController.view, attribute: .bottom, relatedBy: .equal, toItem: self.percentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.percentViewController.view, attribute: .leading, relatedBy: .equal, toItem: self.percentView, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.percentViewController.view, attribute: .trailing, relatedBy: .equal, toItem: self.percentView, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
        
    }
    
    @IBAction func addButtonTapped(sender: UIButton!) {
        if self.libraryState == .add || self.libraryState == .addPartial {
            self.delegate?.addTapped(self.row)
        } else if self.libraryState == .addPlaylist {
            self.delegate?.addTapped(self.row)
        }
    }
    
    func set(image: UIImage) {
        self.artView?.image = image
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.libraryState = .add
        self.addButtonHidden = true
        //self.laidOut = false
    }
}
