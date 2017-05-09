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

class NowPlayingGameViewController: UIViewController, GameDetailOverlayViewControllerDelegate {
    @IBOutlet weak var coverImageView:       UIImageView?
    @IBOutlet weak var detailsContainerView: UIView?
    @IBOutlet weak var blurView:             UIVisualEffectView?
    @IBOutlet weak var deleteView:           UIVisualEffectView?
    @IBOutlet weak var containerView:        UIView?
    @IBOutlet weak var shadowView:           UIView?
    @IBOutlet weak var detailsPanRecognizer: PanDirectionGestureRecognizer?
    @IBOutlet weak var hideTapRecognizer:    UITapGestureRecognizer?
    @IBOutlet weak var statsButtonView:      UIView?
    @IBOutlet weak var moreIcon:             UIImageView?
    @IBOutlet weak var statsBlurView:        UIVisualEffectView?
    @IBOutlet weak var playPauseButton:      UIButton?
    @IBOutlet weak var favouriteButton:      UIButton?
    @IBOutlet weak var finishedButton:       UIButton?
    @IBOutlet weak var statsContainerView:   UIView?
    @IBOutlet weak var ratingContainerView:  UIView?
    @IBOutlet weak var notesTextView:        UITextView?
    
    @IBOutlet weak var statsButtonLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var statsButtonBottomConstraint:  NSLayoutConstraint?
    
    @IBOutlet weak var firstStar:  UIImageView?
    @IBOutlet weak var secondStar: UIImageView?
    @IBOutlet weak var thirdStar:  UIImageView?
    @IBOutlet weak var fourthStar: UIImageView?
    @IBOutlet weak var fifthStar:  UIImageView?
    
    var delegate: NowPlayingGameViewDelegate?
    
    let gameDetailOverlayController = GameDetailOverlayViewController()
    
    private var _game: Game?
    var detailUrl: String?
    
    private var isInEditMode = false
    
    var game: Game? {
        get {
            return self._game
        }
        set(newGame) {
            self._game = newGame
            if let gameField = self._game?.gameFields {
                if !gameField.hasDetails {
                    gameField.updateGameDetails { result in
                        if result.error != nil {
                            NSLog("\((result.error?.localizedDescription)!)")
                            return
                        }
                        self.addDetails()
                    }
                }
            }
        }
    }
    
    enum DetailState {
        case hidden
        case minimal
        case percent
        case full
    }
    
    enum StatsState {
        case hidden
        case visible
    }
    
    enum ButtonState {
        case heldDown
        case down
        case up
    }
    
    enum StatsButtonState {
        case selected
        case normal
    }
    
    private var statsState = StatsState.hidden
    
    private var buttonState = ButtonState.up
    
    private var playButtonState = StatsButtonState.selected
    private var favouriteButtonState = StatsButtonState.normal
    private var finishedButtonState = StatsButtonState.normal
    
    private var blurViewState = DetailState.minimal
    private var blurViewMinimalY: CGFloat = 0.0
    
    private var animator: UIDynamicAnimator!
    private var gravity: UIGravityBehavior!
    private var collision: UICollisionBehavior!
    
    private let MINIMUM_TRANSFORM: CGFloat = 0.001
    private let MAXIMUM_TRANSOFRM: CGFloat = 1.0
    
    init() {
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
        self.gameDetailOverlayController.delegate = self
        self.detailsPanRecognizer?.direction = .vertical
        self.shadowView?.isUserInteractionEnabled = true
        self.statsBlurView?.effect = nil
        self.statsBlurView?.isHidden = true
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
                GameField.getGameDetail(withUrl: self.detailUrl!, { result in
                    if let error = result.error {
                        NSLog("error loading details: \(error.localizedDescription)")
                    }
                    self.addDetails()
                })
            }
        } else {
            self.addDetails()
        }
        self.gameDetailOverlayController.detailsGestureView?.addGestureRecognizer(self.detailsPanRecognizer!)
    }
    
    // MARK: viewDidLayoutSubviews
    
    override func viewDidLayoutSubviews() {
        self.shadowView?.layer.shadowOpacity = 0.8
        self.shadowView?.layer.shadowRadius = 5.0
        self.shadowView?.layer.shadowColor = UIColor.black.cgColor
        self.shadowView?.layer.shadowPath = UIBezierPath(roundedRect: (self.shadowView?.bounds)!, cornerRadius: 10).cgPath
        self.shadowView?.layer.shadowOffset = CGSize.zero
        
        self.statsButtonView?.layer.shadowOpacity = 0.8
        self.statsButtonView?.layer.shadowRadius = 5.0
        self.statsButtonView?.layer.shadowColor = UIColor.black.cgColor
        self.statsButtonView?.layer.shadowPath = UIBezierPath(roundedRect: (self.statsButtonView?.bounds)!, cornerRadius: 40).cgPath
        self.statsButtonView?.layer.shadowOffset = CGSize.zero
        
        if self.blurViewMinimalY != 0.0 {
            self.blurViewState = .minimal
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
        currentGame.gameFields?.getImage(withSize: .SuperUrl, { result in
            if let error = result.error {
                NSLog("\(error)")
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
            self.notesTextView?.resignFirstResponder()
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
        if self.statsState != .hidden {
            handleTapMore(sender: UITapGestureRecognizer())
        }
        else if self.blurViewState != .minimal {
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
        delegate?.didDelete(viewController: self, uuid: (self.game?.uuid)!)
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
    
    func didTapDetails() {
        if !self.isInEditMode && self.statsState != .visible {
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
    }
    
    // MARK: handlePanDetails
    
    @IBAction func handlePanDetails(recognizer:UIPanGestureRecognizer) {
        
        // Set inital y of blur view in minimal mode to get reference to move back to
        if recognizer.state == .began {
            if self.blurViewState == .minimal {
                self.blurViewMinimalY = (self.blurView?.center.y)!
            }
            self.statsButtonBottomConstraint?.constant = 0
            self.statsButtonLeadingConstraint?.constant = 0
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
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
                                                                 y: self.view.frame.origin.y + 8),
                                                   to: CGPoint(x: self.view.frame.origin.x + self.view.frame.width,
                                                               y: self.view.frame.origin.y + 8))
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
                    self.statsButtonBottomConstraint?.constant = 40
                    self.statsButtonLeadingConstraint?.constant = -40
                    UIView.animate(withDuration: 0.2, animations: {
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    @IBAction func handleTapMore(sender: UIGestureRecognizer) {
        if statsState == .hidden {
            if self.blurViewState == .minimal {
                didTapDetails()
            }
            self.statsBlurView?.isHidden = false
            self.detailsPanRecognizer?.isEnabled = false
            UIView.transition(with: self.moreIcon!,
                              duration:0.2,
                              options: .transitionCrossDissolve,
                              animations: { self.moreIcon?.image = #imageLiteral(resourceName: "x_symbol") },
                              completion: nil)
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                self.statsBlurView?.effect = UIBlurEffect(style: .light)
                self.gameDetailOverlayController.pullTabView?.alpha = 0.0
                self.statsContainerView?.alpha = 1.0
            }, completion: nil)
            statsState = .visible
        } else {
            UIView.transition(with: self.moreIcon!,
                              duration:0.2,
                              options: .transitionCrossDissolve,
                              animations: { self.moreIcon?.image = #imageLiteral(resourceName: "more") },
                              completion: nil)
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                self.statsBlurView?.effect = nil
                self.gameDetailOverlayController.pullTabView?.alpha = 1.0
                self.statsContainerView?.alpha = 0.0
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self.detailsPanRecognizer?.isEnabled = true
                    self.statsBlurView?.isHidden = true
                })
            })
            statsState = .hidden
            didTapDetails()
            self.notesTextView?.resignFirstResponder()
        }
    }
    
    @IBAction func statsControlTouchDown(sender: UIButton!) {
        self.notesTextView?.resignFirstResponder()
        if self.buttonState == .up {
            self.buttonState = .down
        } else if self.buttonState == .down {
            self.buttonState = .heldDown
            UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)})
        }
    }
    
    @IBAction func statsControlTouchUpInside(sender: UIButton!) {
        switch sender.tag {
        case 1:
            if self.favouriteButtonState == .selected {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart-empty"), for: .normal)
                self.favouriteButtonState = .normal
                self._game?.update {
                    self._game?.favourite = false
                }
            } else {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                self.favouriteButtonState = .selected
                self._game?.update {
                    self._game?.favourite = true
                }
            }
        case 2:
            if self.playButtonState == .selected {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "play-black"), for: .normal)
                self.playButtonState = .normal
                self._game?.update {
                    self._game?.nowPlaying = false
                }
                let actions = UIAlertController(title: "Remove from Now Playing?", message: nil, preferredStyle: .alert)
                actions.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in self.delegate?.didDelete(viewController: self, uuid: (self.game?.uuid)!)}))
                actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(actions, animated: true, completion: nil)
                if self.finishedButtonState != .selected {
                    self.gameDetailOverlayController.completionLabel?.text = "Incomplete"
                    self.gameDetailOverlayController.completionCheckImage?.image = #imageLiteral(resourceName: "empty_check")
                }
            } else {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                self.playButtonState = .selected
                self._game?.update {
                    self._game?.nowPlaying = true
                }
                if self.finishedButtonState != .selected {
                    self.gameDetailOverlayController.completionLabel?.text = "In Progress"
                    self.gameDetailOverlayController.completionCheckImage?.image = #imageLiteral(resourceName: "check_light_filled")
                }
            }
        case 3:
            if self.finishedButtonState == .selected {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-empty-black"), for: .normal)
                self.finishedButtonState = .normal
                self._game?.update {
                    self._game?.finished = false
                }
                if self.playButtonState != .selected {
                    self.gameDetailOverlayController.completionLabel?.text = "Incomplete"
                    self.gameDetailOverlayController.completionCheckImage?.image = #imageLiteral(resourceName: "empty_check")
                } else {
                    self.gameDetailOverlayController.completionLabel?.text = "In Progress"
                    self.gameDetailOverlayController.completionCheckImage?.image = #imageLiteral(resourceName: "check_light_filled")
                }
            } else {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-black"), for: .normal)
                self.finishedButtonState = .selected
                self._game?.update {
                    self._game?.finished = true
                }
                self.gameDetailOverlayController.completionLabel?.text = "Complete"
                self.gameDetailOverlayController.completionCheckImage?.image = #imageLiteral(resourceName: "check_light")
            }
        default:
            break
        }
        
        UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)}, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform.identity})
        })
        self.buttonState = .up
    }
    
    @IBAction func statsControlTouchDragExit(sender: UIButton!) {
        self.buttonState = .up
        UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform.identity})
        self.notesTextView?.resignFirstResponder()
    }
    
    @IBAction func ratingPanHandler(sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self.ratingContainerView!)
        let starIndex = Int(location.x / ((self.ratingContainerView?.bounds.width)! / 5.0))
        if starIndex < 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-white")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-black")
        }
        self.notesTextView?.resignFirstResponder()
    }
    
    @IBAction func ratingTapHandler(sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.ratingContainerView!)
        let starIndex = Int(location.x / ((self.ratingContainerView?.bounds.width)! / 5.0))
        
        if starIndex <= 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-black")
        }
        self.notesTextView?.resignFirstResponder()
    }
}
