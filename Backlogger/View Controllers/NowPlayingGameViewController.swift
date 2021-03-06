//
//  NowPlayingGameViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import Kingfisher
import RealmSwift

protocol NowPlayingGameViewDelegate {
    func didDelete(viewController: NowPlayingGameViewController, uuid: String)
    func notesTyping(textView: UITextView)
}

class NowPlayingGameViewController: UIViewController {
    @IBOutlet weak var coverImageView:       UIImageView?
    @IBOutlet weak var detailsContainerView: UIView?
    @IBOutlet weak var blurView:             UIVisualEffectView?
    @IBOutlet weak var deleteView:           UIVisualEffectView?
    @IBOutlet weak var containerView:        UIView?
    @IBOutlet weak var shadowView:           UIView?
    @IBOutlet weak var detailsPanRecognizer: PanDirectionGestureRecognizer?
    @IBOutlet weak var hideTapRecognizer:    UITapGestureRecognizer?
    
    @IBOutlet weak var blurViewTopConstraint: NSLayoutConstraint?
    
    var delegate: NowPlayingGameViewDelegate?
    
    let gameDetailOverlayController = GameDetailOverlayViewController()
    
    fileprivate var _game: Game?
    var detailUrl: String?
    
    fileprivate var isInEditMode = false
    
    var mainImage: UIImage?
    
    var game: Game? {
        get {
            return self._game
        }
        set(newGame) {
            self._game = newGame
            if let gameField = self._game?.gameFields {
                if !gameField.isInvalidated && !gameField.hasDetails {
                    gameField.updateGameDetails { result in
                        if result.error != nil {
                            NSLog("\((result.error?.localizedDescription)!)")
                            return
                        }
                        self.addDetails(withRefresh: false)
                    }
                }
            }
            self.gameDetailOverlayController.game = newGame
        }
    }
    
    enum DetailState {
        case hidden
        case minimal
        case percent
        case full
    }
    
    fileprivate var blurViewState = DetailState.minimal
    fileprivate var blurViewMinimalY: CGFloat = 0.0
    
    fileprivate var animator: UIDynamicAnimator!
    fileprivate var gravity: UIGravityBehavior!
    fileprivate var collision: UICollisionBehavior!
    
    fileprivate let MINIMUM_TRANSFORM: CGFloat = 0.001
    fileprivate let MAXIMUM_TRANSOFRM: CGFloat = 1.0
    fileprivate let MINIMUM_BLUR_TOP: CGFloat = -65.0
    fileprivate var didLayout = false
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(detailUrl: String) {
        self.detailUrl = detailUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gameDetailOverlayController.delegate = self
        self.detailsPanRecognizer?.direction = .vertical
        self.shadowView?.isUserInteractionEnabled = true
        if let detailView = gameDetailOverlayController.view {
            self.detailsContainerView?.addSubview(detailView)
            detailView.translatesAutoresizingMaskIntoConstraints = false
            
            detailView.topAnchor.constraint(equalTo: self.detailsContainerView!.topAnchor).isActive = true
            detailView.bottomAnchor.constraint(equalTo: self.detailsContainerView!.bottomAnchor, constant: -100.0).isActive = true
            detailView.leadingAnchor.constraint(equalTo: self.detailsContainerView!.leadingAnchor).isActive = true
            detailView.trailingAnchor.constraint(equalTo: self.detailsContainerView!.trailingAnchor).isActive = true
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
                    self.addDetails(withRefresh: false)
                })
            }
        } else {
            self.addDetails(withRefresh: false)
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
        if self.blurViewMinimalY == 0.0 && self.didLayout {
            self.blurViewState = .minimal
        }
        self.didLayout = true
        self.deleteView?.transform = CGAffineTransform(scaleX: self.isInEditMode ? MAXIMUM_TRANSOFRM : MINIMUM_TRANSFORM,
                                                       y: self.isInEditMode ? MAXIMUM_TRANSOFRM : MINIMUM_TRANSFORM)
    }
    
    func hideView() {
        self.view.mask = UIView(frame: .zero)
    }
    
    func showView() {
        let view = UIView(frame: self.view.frame)
        view.backgroundColor = .white
        self.view.mask = view
    }
    
    func animateGrowing(initialFrame: CGRect) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0.0, y: self.view.center.y - (initialFrame.height / 2), width: initialFrame.width, height: initialFrame.height)
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradientLayer.locations = [0.0, 0.1, 0.9, 1.0]
        //gradientLayer.anchorPoint = self.view.center
        let gradientAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        gradientAnimation.fromValue = initialFrame.height
        gradientAnimation.toValue = self.view.bounds.size.height + 300
        gradientAnimation.duration = 0.5
        gradientAnimation.isRemovedOnCompletion = false
        gradientAnimation.fillMode = CAMediaTimingFillMode.forwards
        let maskView = UIView(frame: self.view.frame)
        maskView.backgroundColor = .clear

        maskView.layer.addSublayer(gradientLayer)
        
        let whiteView = UIView(frame: self.view.frame)
        whiteView.backgroundColor = .white
        self.view.addSubview(whiteView)
        self.view.mask = maskView
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            self.view.mask = nil
        })
        gradientLayer.add(gradientAnimation, forKey: "bounds.size.height")
        CATransaction.commit()
        UIView.animate(withDuration: 0.5, animations: {
            whiteView.alpha = 0.0
        }, completion: { _ in
            whiteView.removeFromSuperview()
        })
    }
    
    func addDetails(withRefresh refresh: Bool) {
        guard let currentGame = self.game else {
            NSLog("no game to get details from")
            return
        }
        if let image = self.mainImage, !refresh {
            self.coverImageView?.image = image
        } else {
            if let superUrl = currentGame.gameFields?.image?.superUrl {
                self.coverImageView?.kf.setImage(with: URL(string: superUrl), placeholder: #imageLiteral(resourceName: "now_playing_placeholder"), completionHandler: {
                    result in
                    switch result {
                    case .success(let value):
                        if value.cacheType == .none {
                            UIView.transition(with: self.coverImageView!,
                                              duration:0.5,
                                              options: .transitionCrossDissolve,
                                              animations: { self.coverImageView?.image = value.image },
                                              completion: nil)
                        } else {
                            self.coverImageView?.image = value.image
                        }
                        self.mainImage = value.image
                    case .failure(let error):
                        NSLog("Error: \(error)")
                    }
                })
            } else {
                self.coverImageView?.image = #imageLiteral(resourceName: "now_playing_placeholder")
            }
        }
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
                self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP
                self.blurViewState = .minimal
            }
            self.isInEditMode = editMode
            self.detailsPanRecognizer?.isEnabled = !editMode
            self.hideTapRecognizer?.isEnabled = !editMode
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
            self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP
            UIView.animate(withDuration: 0.2,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                            self.view.layoutIfNeeded()
            },
                           completion: { complete in self.blurViewState = .minimal })
            
        }
    }
    
    // MARK: deleteTap
    
    @IBAction func deleteTap(recognizer:UITapGestureRecognizer) {
        // Send UUID to delegate
        delegate?.didDelete(viewController: self, uuid: (self.game?.uuid)!)
    }

    // MARK: handleTapArt
    
    @IBAction func handleTapArt(recognizer:UITapGestureRecognizer) {
        
        switch (self.blurViewState) {
        case .hidden:
            self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP
            self.blurViewState = .minimal
        case .minimal:
            self.blurViewTopConstraint?.constant = 0.0
            self.blurViewState = .hidden
        case .percent:
            self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP
            self.blurViewState = .minimal
        default:
            self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP
            self.blurViewState = .minimal
        }
        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.view.layoutIfNeeded()
        },
                       completion: nil)
    }

    // MARK: handlePanDetails
    
    @IBAction func handlePanDetails(recognizer:UIPanGestureRecognizer) {
        
        // Set inital y of blur view in minimal mode to get reference to move back to
        if recognizer.state == .began {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
        // Update view when user drags it around
        if recognizer.state == .began || recognizer.state == .changed {
            let translation = recognizer.translation(in: self.view)
            self.animator.removeAllBehaviors()
            if let view = self.blurView {
                var newY: CGFloat = 0.0
                
                // If above the limit, resist pan
                if view.center.y - 50 + translation.y < self.view.center.y {
                    newY = self.blurViewTopConstraint!.constant + (translation.y / 2.0)
                } else {
                    newY = self.blurViewTopConstraint!.constant + translation.y
                }
                self.blurViewTopConstraint?.constant = newY
            }
            recognizer.setTranslation(CGPoint.zero, in: self.view)
            self.view.layoutIfNeeded()
            
        // When the pan ends, determine where the view should go
        } else if recognizer.state == .ended {
            let velocity = recognizer.velocity(in: self.view).y
            if let view = self.blurView {
                
                // If the view is above the top, spring down to a full view
                if view.center.y < self.view.center.y {
                    self.blurViewTopConstraint?.constant = -self.coverImageView!.frame.height
                    UIView.animate(withDuration: 0.4,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.6,
                                   initialSpringVelocity: 1.0,
                                   options: .curveEaseOut,
                                   animations: {
                                       self.view.layoutIfNeeded()
                                   },
                                   completion: nil)
                    self.blurViewState = .full
                    
                // If the view is above middle, or if the user was swiping up when they ended, fling to top and collide with top boundary
                } else if (view.center.y < self.view.bounds.maxY && velocity < 300) || velocity < -300 {
                    self.animator.updateItem(usingCurrentState: view)
                    self.gravity.gravityDirection = CGVector(dx: 0.0, dy: max(min(velocity / 300, -1.0), -10.0))
                    if self.animator.behaviors.count == 0 {
                        self.collision.addBoundary(withIdentifier: NSString(string: "top"),
                                                   from: CGPoint(x: self.view.frame.minX, y: 8),
                                                   to: CGPoint(x: self.view.frame.maxX, y: 8))
                        self.animator.addBehavior(self.collision)
                        self.animator.addBehavior(self.gravity)
                    }
                    self.blurViewTopConstraint?.constant = -self.coverImageView!.frame.height
                    self.blurViewState = .full
                    
                // If the view is below the middle, or if the user was swiping down when they ended, return to minimal state with a spring bounce
                } else if (view.center.y > self.view.bounds.maxY && velocity > -300) || velocity > 300 {
                    let minVelocity = min(Double(velocity), 1000.0)
                    let animationTime: TimeInterval = ((-0.6) * ((minVelocity - 300)/700) + 1.0)
                    self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP
                    UIView.animate(withDuration: animationTime,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.6,
                                   initialSpringVelocity: 1.0,
                                   options: .curveEaseOut,
                                   animations: {
                                    self.view.layoutIfNeeded()

                                   },
                                   completion: nil)
                    self.blurViewState = .minimal
                }
            }
        }
    }
}

extension NowPlayingGameViewController: GameDetailOverlayViewControllerDelegate {
    func didDelete(viewController: GameDetailOverlayViewController, uuid: String) {
        self.delegate?.didDelete(viewController: self, uuid: uuid)
    }
    
    func didTapDetails() {
        if !self.isInEditMode {
            // Show percent slider
            if self.blurViewState == .minimal {
                self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP - 40.0
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 1.0,
                               initialSpringVelocity: 0,
                               options: .curveEaseIn,
                               animations: {
                                self.view.layoutIfNeeded()
                },
                               completion: nil)
                self.blurViewState = .percent
                
                // Hide percent slider
            } else if self.blurViewState == .percent {
                self.blurViewTopConstraint?.constant = self.MINIMUM_BLUR_TOP
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 1.0,
                               initialSpringVelocity: 0,
                               options: .curveEaseIn,
                               animations: {
                                self.view.layoutIfNeeded()
                },
                               completion: nil)
                self.blurViewState = .minimal
            }
        }
    }
    
    func notesTyping(textView: UITextView) {
        self.delegate?.notesTyping(textView: textView)
    }
}

extension NowPlayingGameViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self._game?.update {
            self._game?.notes = textView.text
        }
    }
}
