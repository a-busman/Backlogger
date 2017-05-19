//
//  PlaylistTitleView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/4/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class PlaylistTitleView: UIViewController {
    @IBOutlet weak var imageView:  UIImageView!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var deleteButton: UIView!
    @IBOutlet weak var deleteImage: UIImageView!
    @IBOutlet weak var imageBorder: UIView!
    
    var titleDelegate: UITextViewDelegate?
    var observer: NSObject?
    
    var image: UIImage?
    
    private var _titleString: String = ""
    
    var titleString: String {
        get {
            self._titleString = self.titleTextView!.text
            return self._titleString
        }
        set(newValue) {
            self._titleString = newValue
            if self.isViewLoaded {
                self.titleTextView.text = self._titleString
                self.titleTextView.textColor = .black
            }
        }
    }
    private var _isEditable = false
    var isEditable: Bool {
        get {
            return self._isEditable
        }
        set(newValue) {
            self._isEditable = newValue
            if self.isViewLoaded {
                self.titleTextView.isEditable = newValue
                self.titleTextView.isSelectable = newValue
            }
        }
    }
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showImage() {
        if let image = self.image {
            self.imageView.image = image
            self.blurView.isHidden = true
        }
    }
    
    func hideImage() {
        self.blurView.isHidden = false
        self.imageView.image = #imageLiteral(resourceName: "new_playlist")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self._titleString == "" {
            self.titleTextView.text = "Playlist Name"
            self.titleTextView.textColor = .lightGray
        } else {
            self.titleTextView.text = self._titleString
            self.titleTextView.textColor = .black
        }
        self.titleTextView.delegate = self.titleDelegate
        self.titleTextView.isEditable = self._isEditable
        self.titleTextView.isSelectable = self._isEditable
        if self.observer != nil {
            self.titleTextView.addObserver(self.observer!, forKeyPath: "contentSize", options:[.new], context: nil)
        }
        
        self.deleteImage.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4.0)
        let lineView = UIView()
        lineView.backgroundColor = .lightGray
        lineView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(lineView)
        NSLayoutConstraint(item: lineView,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: self.imageView,
                           attribute: .leading,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
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
    }
}
