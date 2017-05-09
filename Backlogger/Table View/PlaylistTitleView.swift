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

    var titleDelegate: UITextViewDelegate?
    var observer: NSObject?
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleTextView.text = "Playlist Name"
        self.titleTextView.textColor = .lightGray
        self.titleTextView.delegate = self.titleDelegate
        if self.observer != nil {
            self.titleTextView.addObserver(self.observer!, forKeyPath: "contentSize", options:[.new], context: nil)
        }
    }
}
