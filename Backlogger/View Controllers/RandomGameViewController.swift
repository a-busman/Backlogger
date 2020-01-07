//
//  RandomGameViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/2/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class RandomGameViewController: UIViewController {
    
    @IBOutlet weak var rerollBlurView: UIVisualEffectView?
    @IBOutlet weak var filterBlurView: UIVisualEffectView?
    @IBOutlet weak var bottomBlurViewConstraint: NSLayoutConstraint?
    @IBOutlet weak var filterLabelConstraint: NSLayoutConstraint?
    let rootGameView = UIView()
    let gameView = NowPlayingGameViewController()
    let gameBlurView = UIVisualEffectView()
    var games: Results<Game>!
    
    let MINIMIZED_FILTER_VIEW_SIZE: CGFloat = 64
    let DEFAULT_FILTER_LABEL_OFFSET: CGFloat = 10
    var maxFilterViewSize: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        autoreleasepool {
            guard let realm = try? Realm() else { return }
            self.games = realm.objects(Game.self)
        }
        
        self.gameView.game = getRandomGame()
        self.gameView.addDetails(withRefresh: false)
        self.gameView.view.translatesAutoresizingMaskIntoConstraints = false
        self.rootGameView.translatesAutoresizingMaskIntoConstraints = false
        self.gameBlurView.translatesAutoresizingMaskIntoConstraints = false
        self.rootGameView.addSubview(self.gameView.view)
        self.rootGameView.addSubview(self.gameBlurView)
        self.view.insertSubview(self.rootGameView, belowSubview: self.filterBlurView!)
        self.gameBlurView.effect = UIBlurEffect(style: .light)
        self.gameBlurView.layer.cornerRadius = 10.0
        self.gameBlurView.clipsToBounds = true
        self.gameBlurView.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.rootGameView.bottomAnchor.constraint(equalTo: self.rerollBlurView!.topAnchor, constant: -10).isActive = true
        self.rootGameView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0).isActive = true
        self.rootGameView.heightAnchor.constraint(equalTo: self.rootGameView.widthAnchor, multiplier: 14/9).isActive = true
        self.rootGameView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
        self.rootGameView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30).isActive = true
        self.gameView.view.bottomAnchor.constraint(equalTo: self.rootGameView.bottomAnchor).isActive = true
        self.gameView.view.topAnchor.constraint(equalTo: self.rootGameView.topAnchor).isActive = true
        self.gameView.view.leadingAnchor.constraint(equalTo: self.rootGameView.leadingAnchor).isActive = true
        self.gameView.view.trailingAnchor.constraint(equalTo: self.rootGameView.trailingAnchor).isActive = true
        self.gameBlurView.bottomAnchor.constraint(equalTo: self.rootGameView.bottomAnchor, constant: -10).isActive = true
        self.gameBlurView.topAnchor.constraint(equalTo: self.rootGameView.topAnchor, constant: 10).isActive = true
        self.gameBlurView.leadingAnchor.constraint(equalTo: self.rootGameView.leadingAnchor, constant: 10).isActive = true
        self.gameBlurView.trailingAnchor.constraint(equalTo: self.rootGameView.trailingAnchor, constant: -10).isActive = true
        self.gameView.detailsPanRecognizer?.isEnabled = false
        self.gameView.hideTapRecognizer?.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.maxFilterViewSize = self.view.bounds.height - 100.0
    }

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func rerollTapped(_ sender: UIGestureRecognizer) {
        var generator: UIFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        (generator as! UIImpactFeedbackGenerator).impactOccurred()
        self.gameBlurView.alpha = 0.0
        self.gameBlurView.isHidden = false
        UIView.animate(withDuration: 0.25, animations: {
            self.gameBlurView.alpha = 1.0
            self.rootGameView.alpha = 0.0
            self.rootGameView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { _ in
            generator = UINotificationFeedbackGenerator()
            (generator as! UINotificationFeedbackGenerator).notificationOccurred(.success)
            self.gameView.game = self.getRandomGame()
            self.gameView.addDetails(withRefresh: true)
            UIView.animate(withDuration: 0.25, animations: {
                self.gameBlurView.alpha = 0.0
                self.rootGameView.alpha = 1.0
                self.rootGameView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        })
    }

    func getRandomGame() -> Game? {
        return self.games[Int.random(in: 0..<self.games.count)]
    }
    
    @IBAction func didDragFilters(_ sender: UIPanGestureRecognizer)
    {
        
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: self.view)
            var newY: CGFloat = 0.0
            var labelY: CGFloat = self.DEFAULT_FILTER_LABEL_OFFSET
            
            if self.bottomBlurViewConstraint!.constant + translation.y > self.maxFilterViewSize {
                newY = self.bottomBlurViewConstraint!.constant + (translation.y / 2.0)
            } else {
                if self.bottomBlurViewConstraint!.constant + translation.y < self.MINIMIZED_FILTER_VIEW_SIZE {
                labelY = self.filterLabelConstraint!.constant + translation.y
                }
                newY = self.bottomBlurViewConstraint!.constant + translation.y
            }
            self.filterLabelConstraint?.constant = labelY
            self.bottomBlurViewConstraint?.constant = newY
            sender.setTranslation(CGPoint.zero, in: self.view)
            self.view.layoutIfNeeded()
        } else if sender.state == .ended {
            let velocity = sender.velocity(in: self.view).y
            NSLog("velocity \(velocity)")
            if self.bottomBlurViewConstraint!.constant > self.maxFilterViewSize {
                self.bottomBlurViewConstraint?.constant = self.maxFilterViewSize
                UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            } else if (self.bottomBlurViewConstraint!.constant > (self.maxFilterViewSize / 2.0) && velocity > -300) || velocity > 300 {
                self.bottomBlurViewConstraint?.constant = self.maxFilterViewSize
                let minVelocity = min(Double(velocity), 1000.0)
                
                let animationTime: TimeInterval = (-0.6 * ((minVelocity - 300)/700) + 1.0)
                
                UIView.animate(withDuration: animationTime, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            } else if (self.bottomBlurViewConstraint!.constant < (self.maxFilterViewSize / 2.0) && velocity < 300) || velocity < -300 {
                let minVelocity = min(Double(velocity * -1.0), 1000.0)
                let animationTime: TimeInterval = (-0.6 * ((minVelocity - 300)/700) + 1.0)
                self.bottomBlurViewConstraint?.constant = self.MINIMIZED_FILTER_VIEW_SIZE
                    self.filterLabelConstraint?.constant = self.DEFAULT_FILTER_LABEL_OFFSET
                UIView.animate(withDuration: animationTime,
                               delay: 0.0,
                               usingSpringWithDamping: 1.0,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: { self.view.layoutIfNeeded()
                },
                               completion: nil)
            }
        }
    }
}
