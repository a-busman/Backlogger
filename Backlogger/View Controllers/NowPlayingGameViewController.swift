//
//  NowPlayingGameViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class NowPlayingGameViewController: UIViewController {
    @IBOutlet weak var coverImageView:       UIImageView?
    @IBOutlet weak var detailsContainerView: UIView?
    @IBOutlet weak var titleLabel:           UILabel?
    @IBOutlet weak var completionPercentage: UILabel?
    @IBOutlet weak var platformLabel:        UILabel?
    @IBOutlet weak var containerView:        UIView?
    @IBOutlet weak var shadowView:           UIView?
    
    var detailsViewHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        self.shadowView?.layer.shadowOpacity = 0.8
        self.shadowView?.layer.shadowRadius = 5.0
        self.shadowView?.layer.shadowColor = UIColor.black.cgColor
        self.shadowView?.layer.shadowPath = UIBezierPath(rect: (self.shadowView?.bounds)!).cgPath
        self.shadowView?.layer.shadowOffset = CGSize.zero
    }
    
    @IBAction func handleTap(recognizer:UITapGestureRecognizer) {
        if detailsViewHidden {
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseOut,
                           animations: {
                               self.detailsContainerView?.center.y -= 75
                           },
                           completion: nil)
            detailsViewHidden = false
        } else {
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                               self.detailsContainerView?.center.y += 75
                           },
                           completion: nil)
            detailsViewHidden = true
        }
    }
}
