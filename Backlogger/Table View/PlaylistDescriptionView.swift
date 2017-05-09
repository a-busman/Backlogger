//
//  PlaylistDescriptionView.swift
//  Backlogger
//
//  Created by Alex Busman on 5/7/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class PlaylistDescriptionView: UIViewController {
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var descriptionDelegate: UITextViewDelegate?
    var observer: NSObject?
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.descriptionTextView.text = "Description"
        self.descriptionTextView.textColor = .lightGray
        self.descriptionTextView.delegate = self.descriptionDelegate
        if self.observer != nil {
            self.descriptionTextView.addObserver(self.observer!, forKeyPath: "contentSize", options:[.new], context: nil)
        }
    }
}
