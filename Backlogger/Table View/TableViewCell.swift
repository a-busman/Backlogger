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
    @IBOutlet weak var truncGradient:    UIView!
    
    @IBOutlet weak var rightTrailingLayoutConstraint: NSLayoutConstraint!
    
    let truncateGradientLayer = CAGradientLayer()
    
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
    
    var row: Int!
    
    var imageUrl: URL?
    var cacheCompletionHandler: CompletionHandler?
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        self.addButton?.isHidden = self.addButtonHidden
        if self.addButtonHidden {
            self.rightTrailingLayoutConstraint?.constant = -10.0
        } else {
            self.rightTrailingLayoutConstraint?.constant = -38.0
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
        
        self.truncateGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: (self.truncGradient?.frame.width)!, height: (self.truncGradient?.frame.height)!)
        var alternateColor: CGColor
        var clearColor: CGColor
        if !super.isHighlighted {
            clearColor = UIColor(white: 1.0, alpha: 0.0).cgColor
            alternateColor = UIColor.white.cgColor
        } else {
            clearColor = UIColor(white: 0.85, alpha: 0.0).cgColor
            alternateColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        }
        self.truncateGradientLayer.colors = [clearColor, alternateColor]
        let newLocation = 35.0/(self.truncGradient?.frame.width)!
        self.truncateGradientLayer.locations = [0.0, NSNumber(value: Float(newLocation))]
        self.truncateGradientLayer.startPoint = .zero
        self.truncateGradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        self.truncGradient?.layer.addSublayer(self.truncateGradientLayer)
        self.contentView.bringSubview(toFront: self.addButton!)
        self.contentView.bringSubview(toFront: self.rightLabel!)
        if self.imageUrl != nil {
            self.artView?.kf.setImage(with: self.imageUrl, placeholder: #imageLiteral(resourceName: "table_placeholder_light"), completionHandler: self.cacheCompletionHandler)
        } else {
            self.artView?.image = #imageLiteral(resourceName: "table_placeholder_light")
        }
        self.truncateGradientLayer.removeAllAnimations()
    }
    
    @IBAction func addButtonTapped(sender: UIButton!) {
        if self.libraryState == .add || self.libraryState == .addPartial {
            self.delegate?.addTapped(self.row)
        } else if self.libraryState == .addPlaylist {
            self.delegate?.addTapped(self.row)
            self.libraryState = .inPlaylist
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
    }
}
