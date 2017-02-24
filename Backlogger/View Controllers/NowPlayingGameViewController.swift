//
//  NowPlayingGameViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

protocol NowPlayingGameViewDelegate {
    func didDelete(viewController: NowPlayingGameViewController, uuid: String)
}

class NowPlayingGameViewController: UIViewController {
    @IBOutlet weak var coverImageView:       UIImageView?
    @IBOutlet weak var detailsContainerView: UIView?
    @IBOutlet weak var blurView:             UIVisualEffectView?
    @IBOutlet weak var deleteView:           UIVisualEffectView?
    @IBOutlet weak var containerView:        UIView?
    @IBOutlet weak var shadowView:           UIView?
    @IBOutlet weak var detailsGestureView:   UIView?
    @IBOutlet weak var detailsPanRecognizer: PanDirectionGestureRecognizer?
    @IBOutlet weak var hideTapRecognizer:    UITapGestureRecognizer?
    @IBOutlet weak var detailsTapRecognizer: UITapGestureRecognizer?
    
    var delegate: NowPlayingGameViewDelegate?
    
    let gameDetailOverlayController = GameDetailOverlayViewController()
    
    var game: Game?
    var detailUrl: String?
    
    private var isInEditMode = false
    
    enum DetailState {
        case hidden
        case minimal
        case percent
        case full
    }
    
    private var blurViewState = DetailState.minimal
    private var blurViewMinimalY: CGFloat = 0.0
    
    private var animator: UIDynamicAnimator!
    private var gravity: UIGravityBehavior!
    private var collision: UICollisionBehavior!
    
    var gameId: String = ""
    let uuid = UUID().uuidString
    
    private let MINIMUM_TRANSFORM: CGFloat = 0.001
    private let MAXIMUM_TRANSOFRM: CGFloat = 1.0
    
    init(gameId: String) {
        self.gameId = gameId
        super.init(nibName: nil, bundle: nil)
    }
    
    init(detailUrl: String) {
        self.detailUrl = detailUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.detailsPanRecognizer?.direction = .vertical
        self.shadowView?.isUserInteractionEnabled = true
        if let detailView = gameDetailOverlayController.view {
            self.detailsContainerView?.addSubview(detailView)
            detailView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint(item: detailView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self.detailsContainerView,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 0
                ).isActive = true
            NSLayoutConstraint(item: detailView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self.detailsContainerView,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: -100
                ).isActive = true
            NSLayoutConstraint(item: detailView,
                               attribute: .leading,
                               relatedBy: .equal,
                               toItem: self.detailsContainerView,
                               attribute: .leading,
                               multiplier: 1.0,
                               constant: 0
                ).isActive = true
            NSLayoutConstraint(item: detailView,
                               attribute: .trailing,
                               relatedBy: .equal,
                               toItem: self.detailsContainerView,
                               attribute: .trailing,
                               multiplier: 1.0,
                               constant: 0
                ).isActive = true
        }
        self.animator = UIDynamicAnimator(referenceView: self.view)
        self.gravity = UIGravityBehavior(items: [self.blurView!])
        self.collision = UICollisionBehavior(items: [self.blurView!])
        
        if game == nil {
            if self.detailUrl != nil {
                Game.getGameDetail(withUrl: self.detailUrl!, { result in
                    if let error = result.error {
                        NSLog("error loading details: \(error.localizedDescription)")
                    }
                    self.addDetails()
                })
            }
        } else {
            self.addDetails()
        }
    }
    
    // MARK: viewDidLayoutSubviews
    
    override func viewDidLayoutSubviews() {
        self.shadowView?.layer.shadowOpacity = 0.8
        self.shadowView?.layer.shadowRadius = 5.0
        self.shadowView?.layer.shadowColor = UIColor.black.cgColor
        self.shadowView?.layer.shadowPath = UIBezierPath(rect: (self.shadowView?.bounds)!).cgPath
        self.shadowView?.layer.shadowOffset = CGSize.zero
        self.detailsContainerView?.bringSubview(toFront: self.detailsGestureView!)
        if self.blurViewMinimalY != 0.0 {
            self.blurViewState = .minimal
            NSLog("\(self.blurViewMinimalY)")
            self.blurView?.center.y = self.blurViewMinimalY
        }
        self.deleteView?.transform = CGAffineTransform(scaleX: self.isInEditMode ? MAXIMUM_TRANSOFRM : MINIMUM_TRANSFORM,
                                                       y: self.isInEditMode ? MAXIMUM_TRANSOFRM : MINIMUM_TRANSFORM)
    }
    
    func addDetails() {
        guard let currentGame = self.game else {
            NSLog("no game to get details from")
            return
        }
        currentGame.getImage(withSize: .SuperUrl, { result in
            if let error = result.error {
                print(error)
            } else {
                if let imageView = self.coverImageView {
                    UIView.transition(with: imageView,
                                      duration:0.5,
                                      options: .transitionCrossDissolve,
                                      animations: { imageView.image = result.value! },
                                      completion: nil)
                } else {
                    self.coverImageView?.image = result.value!
                }
            }
        })
        self.gameDetailOverlayController.game = currentGame
    }
    
    // MARK: setEditMode
    
    func setEditMode(editMode: Bool, animated: Bool) {
        if self.isInEditMode != editMode {
            if animated {
                // When view can be seen, we should animate the X circle growing and shrinking
                self.transitionToEditMode(editMode: editMode)
            } else {
                self.deleteView?.transform = CGAffineTransform(scaleX: editMode ? MAXIMUM_TRANSOFRM : MINIMUM_TRANSFORM,
                                                               y: editMode ? MAXIMUM_TRANSOFRM : MINIMUM_TRANSFORM)
            }
            self.isInEditMode = editMode
            self.detailsPanRecognizer?.isEnabled = !editMode
            self.hideTapRecognizer?.isEnabled = !editMode
            self.detailsTapRecognizer?.isEnabled = !editMode
        }
    }
    
    // MARK: transitionToEditMode
    
    private func transitionToEditMode(editMode: Bool) {
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.deleteView?.transform = CGAffineTransform(scaleX: editMode ? self.MAXIMUM_TRANSOFRM : self.MINIMUM_TRANSFORM,
                                                                       y: editMode ? self.MAXIMUM_TRANSOFRM : self.MINIMUM_TRANSFORM)
                       },
                       completion: nil)
        if self.blurViewState != .minimal {
            UIView.animate(withDuration: 0.2,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                            self.blurView?.center.y = self.blurViewMinimalY
            },
                           completion: nil)
            self.blurViewState = .minimal
        }
    }
    
    // MARK: deleteTap
    
    @IBAction func deleteTap(recognizer:UITapGestureRecognizer) {
        // Send UUID to delegate
        delegate?.didDelete(viewController: self, uuid: self.uuid)
    }

    // MARK: handleTapArt
    
    @IBAction func handleTapArt(recognizer:UITapGestureRecognizer) {
        
        // Show minimal details bar
        if self.blurViewState == .hidden {
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseOut,
                           animations: {
                               self.blurView?.center.y -= 65
                           },
                           completion: nil)
            self.blurViewState = .minimal
            
        // Hide all details and just show cover art
        } else if self.blurViewState == .minimal {
            self.blurViewMinimalY = (self.blurView?.center.y)!
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                               self.blurView?.center.y += 65
                           },
                           completion: nil)
            self.blurViewState = .hidden
        }
    }
    
    // MARK: handleTapDetails
    
    @IBAction func handleTapDetails(recognizer:UITapGestureRecognizer) {
        
        // Show percent slider
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
            
        // Hide percent slider
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
    
    // MARK: handlePanDetails
    
    @IBAction func handlePanDetails(recognizer:UIPanGestureRecognizer) {
        
        // Set inital y of blur view in minimal mode to get reference to move back to
        if recognizer.state == .began {
            if self.blurViewState == .minimal {
                self.blurViewMinimalY = (self.blurView?.center.y)!
            }
        }
        
        // Update view when user drags it around
        if recognizer.state == .began || recognizer.state == .changed {
            let translation = recognizer.translation(in: self.view)
            if let view = self.blurView {
                var newY: CGFloat = 0.0
                
                // If above the limit, resist pan
                if view.center.y - 50 + translation.y < self.view.center.y {
                    newY = view.center.y + (translation.y / 2.0)
                } else {
                    newY = view.center.y + translation.y
                }
                view.center = CGPoint(x:view.center.x,
                                      y:newY)
            }
            recognizer.setTranslation(CGPoint.zero, in: self.view)
            
        // When the pan ends, determine where the view should go
        } else if recognizer.state == .ended {
            let velocity = recognizer.velocity(in: self.view).y
            if let view = self.blurView {
                
                // If the view is above the top, spring down to a full view
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
                    
                // If the view is above middle, or if the user was swiping up when they ended, fling to top and collide with top boundary
                } else if (view.center.y < self.view.bounds.maxY && velocity < 300) || velocity < -300 {
                    self.animator.updateItem(usingCurrentState: view)
                    self.gravity.gravityDirection = CGVector(dx: 0.0, dy: max(min(velocity / 300, -1.0), -10.0))
                    if self.animator.behaviors.count == 0 {
                        self.collision.addBoundary(withIdentifier: NSString(string: "top"),
                                                   from: CGPoint(x: self.view.frame.origin.x,
                                                                 y: self.view.frame.origin.y + 5),
                                                   to: CGPoint(x: self.view.frame.origin.x + self.view.frame.width,
                                                               y: self.view.frame.origin.y + 5))
                        self.animator.addBehavior(self.collision)
                        self.animator.addBehavior(self.gravity)
                    }
                    self.blurViewState = .full
                    
                // If the view is below the middle, or if the user was swiping down when they ended, return to minimal state with a spring bounce
                } else if (view.center.y > self.view.bounds.maxY && velocity > -300) || velocity > 300 {
                    let animationTime: TimeInterval = ((0.4 - 1.0) * (min(Double(velocity), 1000.0) - 300)/(1000 - 300) + 1.0)
                    UIView.animate(withDuration: animationTime,
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
