//
//  PlaylistDescriptionView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/7/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class PlaylistDescriptionCell: UIViewController {
    @IBOutlet weak var descriptionTextView: UITextView?
    
    var descriptionDelegate: UITextViewDelegate?
    var observer: NSObject?
    
    var _descriptionString: String = ""
    
    var descriptionString: String {
        get {
            self._descriptionString = self.descriptionTextView!.text
            return self._descriptionString
        }
        set(newValue) {
            self._descriptionString = newValue
            self.descriptionTextView?.text = newValue
            self.descriptionTextView?.textColor = .black
        }
    }
    
    private var _isEditable = false
    var isEditable: Bool {
        get {
            return self._isEditable
        }
        set(newValue) {
            self._isEditable = newValue
            self.descriptionTextView?.isEditable = newValue
            self.descriptionTextView?.isSelectable = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self._descriptionString == "" {
            self.descriptionTextView?.text = "Description"
            self.descriptionTextView?.textColor = .lightGray
        } else {
            self.descriptionTextView?.text = self._descriptionString
            self.descriptionTextView?.textColor = .black
        }
        self.descriptionTextView?.delegate = self.descriptionDelegate
        self.descriptionTextView?.isEditable = self._isEditable
        self.descriptionTextView?.isSelectable = self._isEditable
        if self.observer != nil {
            self.descriptionTextView?.addObserver(self.observer!, forKeyPath: "contentSize", options:[.new], context: nil)
        }
    }
}
