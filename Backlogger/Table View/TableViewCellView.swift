//
//  TableViewCellView.swift
//  Backlogger
//
//  Created by Alex Busman on 2/24/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

protocol TableViewCellViewDelegate {
    func addTapped(_ row: Int)
    func removeTapped(_ row: Int)
}

class TableViewCellView: UIViewController {
    
    @IBOutlet weak var artView:          UIImageView?
    @IBOutlet weak var titleLabel:       UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var rightLabel:       UILabel?
    @IBOutlet weak var addButton:        UIButton?
    
    @IBOutlet weak var rightTrailingLayoutConstraint: NSLayoutConstraint?
    
    enum ImageSource {
        case Placeholder
        case Downloaded
    }
    
    enum LibraryState {
        case add
        case addPartial
        case remove
    }
    
    var delegate: TableViewCellViewDelegate?
    var addButtonHidden = true
    private var _libraryState = LibraryState.add
    
    var imageSource: ImageSource = .Placeholder
    
    var row: Int!
    
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
    }
    
    override func viewDidLayoutSubviews() {
        self.addButton?.isHidden = self.addButtonHidden
        if self.addButtonHidden {
            self.rightTrailingLayoutConstraint?.isActive = false
            self.rightTrailingLayoutConstraint = NSLayoutConstraint(item: self.rightLabel!, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1.0, constant: -10.0)
            self.rightTrailingLayoutConstraint?.isActive = true
        }
        self.view.layoutIfNeeded()
    }
    
    @IBAction func addButtonTapped(sender: UIButton!) {
        if self.libraryState != .remove{
            self.delegate?.addTapped(self.row)
        //} else {
        //    self.delegate?.removeTapped(self.row)
        }
    }
}
