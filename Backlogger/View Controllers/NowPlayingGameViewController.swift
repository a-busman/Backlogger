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
    @IBOutlet weak var blurView:             UIVisualEffectView?
    @IBOutlet weak var containerView:        UIView?
    @IBOutlet weak var shadowView:           UIView?
    @IBOutlet weak var detailsGestureView:   UIView?
    
    var gameDetailOverlayController = GameDetailOverlayViewController()
    
    enum DetailState {
        case hidden
        case minimal
        case percent
        case full
    }
    
    var blurViewState = DetailState.minimal
    var blurViewMinimalY: CGFloat = 0.0
    var blurViewPercentY: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let detailView = gameDetailOverlayController.view
        self.detailsContainerView?.addSubview(detailView!)
        detailView?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: detailView!, attribute: .top, relatedBy: .equal, toItem: self.detailsContainerView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: detailView!, attribute: .bottom, relatedBy: .equal, toItem: self.detailsContainerView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: detailView!, attribute: .leading, relatedBy: .equal, toItem: self.detailsContainerView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: detailView!, attribute: .trailing, relatedBy: .equal, toItem: self.detailsContainerView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        
    }
    
    override func viewDidLayoutSubviews() {
        self.shadowView?.layer.shadowOpacity = 0.8
        self.shadowView?.layer.shadowRadius = 5.0
        self.shadowView?.layer.shadowColor = UIColor.black.cgColor
        self.shadowView?.layer.shadowPath = UIBezierPath(rect: (self.shadowView?.bounds)!).cgPath
        self.shadowView?.layer.shadowOffset = CGSize.zero
        self.detailsContainerView?.bringSubview(toFront: self.detailsGestureView!)
        self.blurView?.contentView.frame = CGRect(x: (self.blurView?.contentView.frame.minX)!, y: (self.blurView?.contentView.frame.minY)!, width: (self.blurView?.contentView.frame.width)!, height: (self.blurView?.frame.height)! - 100)
    }
    
    @IBAction func handleTapArt(recognizer:UITapGestureRecognizer) {
        if self.blurViewState == .hidden {
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseOut,
                           animations: {
                               self.blurView?.center.y -= 75
                           },
                           completion: nil)
            self.blurViewState = .minimal
        } else if self.blurViewState == .minimal {
            self.blurViewMinimalY = (self.blurView?.center.y)!
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                               self.blurView?.center.y += 75
                           },
                           completion: nil)
            self.blurViewState = .hidden
        }
    }
    
    @IBAction func handleTapDetails(recognizer:UITapGestureRecognizer) {
        if self.blurViewState == .minimal {
            self.blurViewMinimalY = (self.blurView?.center.y)!
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                               self.blurView?.center.y -= 40
                           },
                           completion: nil)
            self.blurViewState = .percent
        } else if self.blurViewState == .percent {
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                               self.blurView?.center.y += 40
                           },
                           completion: nil)
            self.blurViewState = .minimal
        }
    }
    
    @IBAction func handlePanDetails(recognizer:UIPanGestureRecognizer) {
        if recognizer.state == .began {
            if self.blurViewState == .minimal {
                self.blurViewMinimalY = (self.blurView?.center.y)!
            }
        }
        if recognizer.state == .began || recognizer.state == .changed {
            let translation = recognizer.translation(in: self.view)
            if let view = self.blurView {
                var newY: CGFloat = 0.0
                if view.center.y - 50 + translation.y < self.view.center.y {
                    newY = view.center.y + (translation.y / 2.0)
                } else {
                    newY = view.center.y + translation.y
                }
                view.center = CGPoint(x:view.center.x,
                                      y:newY)
            }
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        } else if recognizer.state == .ended {
            if let view = self.blurView {
                if view.center.y < self.view.center.y {
                    UIView.animate(withDuration: 0.4,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.6,
                                   initialSpringVelocity: 1.0,
                                   options: .curveEaseOut,
                                   animations: {
                                       self.blurView?.center.y = (self.coverImageView?.center.y)! + 50
                                   },
                                   completion: nil)
                    self.blurViewState = .full
                } else if (view.center.y < self.view.bounds.maxY && recognizer.velocity(in: self.view).y < 300) || recognizer.velocity(in: self.view).y < -300{
                    UIView.animate(withDuration: 0.4,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.6,
                                   initialSpringVelocity: 1.0,
                                   options: .curveEaseOut,
                                   animations: {
                                       self.blurView?.center.y = (self.coverImageView?.center.y)! + 50
                                   },
                                   completion: nil)
                    self.blurViewState = .full
                } else if (view.center.y > self.view.bounds.maxY && recognizer.velocity(in: self.view).y > -300) || recognizer.velocity(in: self.view).y > 300 {
                    UIView.animate(withDuration: 0.4,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.6,
                                   initialSpringVelocity: 1.0,
                                   options: .curveEaseOut,
                                   animations: {
                                       self.blurView?.center.y = self.blurViewMinimalY
                                   },
                                   completion: nil)
                    self.blurViewState = .minimal
                }
            }
        }
    }
}
