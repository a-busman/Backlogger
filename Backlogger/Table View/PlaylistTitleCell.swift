//
//  PlaylistTitleView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/4/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

protocol PlaylistTitleCellDelegate {
    func moreTapped(sender: UITapGestureRecognizer)
    func artTapped(sender: UITapGestureRecognizer)
}

class PlaylistTitleCell: UIViewController {
    @IBOutlet weak var artView:       UIImageView?
    @IBOutlet weak var titleTextView: UITextView?
    @IBOutlet weak var blurView:      UIVisualEffectView?
    @IBOutlet weak var moreButton:    UIView?
    @IBOutlet weak var imageBorder:   UIView?
    @IBOutlet weak var titleLabel:    UILabel?
    @IBOutlet weak var cameraBorder:  UIView?
    @IBOutlet weak var cameraView:    UIView?
    
    var tapRecognizer:    UITapGestureRecognizer?
    var cameraTapRecognizer: UITapGestureRecognizer?
    
    var titleDelegate: UITextViewDelegate?
    var observer: NSObject?
    
    var delegate: PlaylistTitleCellDelegate?
    
    var artImage: UIImage?
    
    private var _titleString: String = ""
    
    var titleString: String {
        get {
            self._titleString = self.titleTextView!.text
            return self._titleString
        }
        set(newValue) {
            self._titleString = newValue
            self.titleLabel?.text = newValue
            self.titleTextView?.text = newValue
            self.titleTextView?.textColor = .black
        }
    }
    private var _isEditable = false
    var isEditable: Bool {
        get {
            return self._isEditable
        }
        set(newValue) {
            self._isEditable = newValue
            self.titleTextView?.isHidden = !self._isEditable
            self.titleLabel?.isHidden = self._isEditable
        }
    }
    
    func showImage() {
        if let image = self.artImage {
            self.artView?.image = image
            self.blurView?.isHidden = true
        }
    }
    
    func hideImage() {
        self.blurView?.isHidden = false
        self.artView?.image = #imageLiteral(resourceName: "new_playlist")
    }
    
    func showCamera() {
        self.cameraBorder?.isHidden = false
        UIView.animate(withDuration: 0.25, animations: {
            self.cameraBorder?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    func hideCamera() {
        UIView.animate(withDuration: 0.25, animations: {
            self.cameraBorder?.transform = CGAffineTransform(scaleX: 0.00000001, y: 0.00000001)
        }, completion: { _ in
            self.cameraBorder?.isHidden = true
        })
    }
    
    @objc func moreTapped(sender: UITapGestureRecognizer) {
        self.delegate?.moreTapped(sender: sender)
    }
    
    @objc func artTapped(sender: UITapGestureRecognizer) {
        self.delegate?.artTapped(sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.moreTapped))
        self.cameraTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.artTapped))
        self.moreButton?.addGestureRecognizer(self.tapRecognizer!)
        self.cameraBorder?.addGestureRecognizer(self.cameraTapRecognizer!)
        if self._titleString == "" {
            self.titleTextView?.text = "Playlist Name"
            self.titleTextView?.textColor = .lightGray
        } else {
            self.titleLabel?.text = self._titleString
            self.titleTextView?.text = self._titleString
            self.titleTextView?.textColor = .black
        }
        self.titleTextView?.delegate = self.titleDelegate
        self.titleTextView?.isHidden = !self._isEditable
        self.titleLabel?.isHidden = self._isEditable
        if self.observer != nil {
            self.titleTextView?.addObserver(self.observer!, forKeyPath: "contentSize", options:[.new], context: nil)
        }
        self.cameraBorder?.transform = CGAffineTransform(scaleX: 0.00000001, y: 0.00000001)
        self.cameraBorder?.isHidden = true
        self.cameraBorder?.layer.shadowColor = UIColor.black.cgColor
        self.cameraBorder?.layer.shadowOffset = CGSize(width: 0.0, height: 10.0)
        self.cameraBorder?.layer.shadowOpacity = 1.0
        self.cameraBorder?.layer.shadowRadius = 20.0
    }
}
