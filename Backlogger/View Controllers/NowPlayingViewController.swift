//
//  NowPlayingViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class NowPlayingViewController: UIViewController, NowPlayingGameViewDelegate {
    
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var addBarButtonItem:  UIBarButtonItem?
    @IBOutlet weak var pageControl:       UIPageControl?
    @IBOutlet weak var collectionView:    UICollectionView?
    @IBOutlet weak var addBackgroundView: UIView?
    @IBOutlet weak var visibleView:       UIView?
    @IBOutlet weak var upNextTableView:   UITableView?
    @IBOutlet weak var blurView:          UIVisualEffectView?
    @IBOutlet weak var dimView:           UIView?
    
    @IBOutlet weak var blurTopLayoutConstraint: NSLayoutConstraint?
    
    var flowLayout: TopAlignedCollectionViewFlowLayout {
        return self.collectionView?.collectionViewLayout as! TopAlignedCollectionViewFlowLayout
    }
    
    static var shouldRefresh = false
    
    var nowPlayingPlaylist: Playlist!
    var upNextPlaylist: Playlist!
    
    var currentIndex = 0
    var inEditMode = false
    
    let reuseIdentifier = "cell"
    
    var longPressGesture : UILongPressGestureRecognizer? = nil
    
    private var isWiggling = false
    private var movingIndexPath: IndexPath? = nil
    
    var movingTableIndexPath: IndexPath?
    
    var orderedViewControllers: [NowPlayingGameViewController] = []
    var games: [Game] = []
    var gamesUpNext: [Game] = []
    var gameIds: [String] = []
    
    enum UpNextState {
        case minimal
        case full
    }
    
    fileprivate var _isDismissing = false
    fileprivate var _blurViewState = UpNextState.minimal
    
    var currentlyTypingTextView: UITextView?
    
    var blurViewState: UpNextState {
        get {
            return self._blurViewState
        }
        set(newValue) {
            switch (newValue) {
            case .minimal:
                self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
                self.dimView?.isUserInteractionEnabled = false
                break
            case .full:
                self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = false
                self.dimView?.isUserInteractionEnabled = true
                break
            }
            self._blurViewState = newValue
        }
    }
    private var blurViewMinimalY: CGFloat = 0.0
    
    let cellReuseIdentifier = "playlist_detail_cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.upNextTableView?.register(UINib(nibName: "PlaylistAddTableCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.upNextTableView?.separatorColor = .lightGray
        //self.upNextTableView?.separatorInset = UIEdgeInsetsMake(0, 75, 0, 0)
        self.upNextTableView?.contentInset.bottom = 55.0
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFirstGame), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = .white
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(NowPlayingViewController.handleLongGesture))
        self.collectionView?.addGestureRecognizer(longPressGesture!)
        self.longPressGesture?.isEnabled = false
        
        self.loadPlaylists()

        if self.games.count > 0 {
            let newButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(handleTapEdit))
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton
            self.addBackgroundView?.isHidden = true
        } else {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
            self.addBackgroundView?.isHidden = false
        }
        if self.orderedViewControllers.count > 0 && !self._isDismissing {
            self.collectionView?.scrollToItem(at: IndexPath(item: self.currentIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
        self._isDismissing = false
        self.pageControl?.numberOfPages = orderedViewControllers.count
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= (keyboardSize.height - (self.tabBarController?.tabBar.frame.height)! - 50.0)
            }
        }
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = false
        UIView.setAnimationsEnabled(false)
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissKeyboard))
        UIView.setAnimationsEnabled(true)
    }
    
    func dismissKeyboard(sender: UIBarButtonItem) {
        self.currentlyTypingTextView?.resignFirstResponder()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height - (self.tabBarController?.tabBar.frame.height)! - 50.0
            }
        }
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = true
        UIView.setAnimationsEnabled(false)
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addTapped))
        UIView.setAnimationsEnabled(true)
    }
    
    func refreshFirstGame() {
        if self.tabBarController?.selectedIndex == 0 {
            let _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
                if let firstGameController = self.orderedViewControllers.first {
                    autoreleasepool {
                        let realm = try! Realm()
                        let game = realm.object(ofType: Game.self, forPrimaryKey: firstGameController.game!.uuid)
                        firstGameController.game = game
                    }}
                }
            )
        }
    }
    
    func loadPlaylists() {
        autoreleasepool {
            let realm = try! Realm()
            let playlists = realm.objects(Playlist.self)
            let nowPlaying = playlists.filter("isNowPlaying = true")
            let upNext = playlists.filter("isUpNext = true")
            if nowPlaying.count == 0 {
                self.nowPlayingPlaylist = Playlist()
                self.nowPlayingPlaylist.isNowPlaying = true
                self.nowPlayingPlaylist.add()
            } else {
                self.nowPlayingPlaylist = nowPlaying.first!
            }
            if upNext.count == 0 {
                self.upNextPlaylist = Playlist()
                self.upNextPlaylist.isUpNext = true
                self.upNextPlaylist.add()
            } else {
                self.upNextPlaylist = upNext.first!
            }
            self.games = Array(self.nowPlayingPlaylist.games)
            self.gamesUpNext = Array(self.upNextPlaylist.games)
        }
        var newGameIds = [String]()
        for game in self.games {
            if let gameField = game.gameFields {
                if !gameField.hasDetails {
                    gameField.updateGameDetails { result in
                        if let error = result.error {
                            NSLog("error: \(error.localizedDescription)")
                            return
                        }
                    }
                }
            }
            newGameIds.append(game.uuid)
        }
        if !NowPlayingViewController.containSameElements(newGameIds, self.gameIds) || self.gameIds.count == 0 {
            self.orderedViewControllers.removeAll()
            for game in self.games {
                let vc = NowPlayingGameViewController()
                vc.game = game
            
                self.orderedViewControllers.append(vc)
                vc.addDetails()
            }
            self.gameIds = newGameIds
            self.collectionView?.reloadData()
        } else {
            for (i, game) in self.games.enumerated() {
                self.orderedViewControllers[i].game = game
            }
        }
        
        self.upNextTableView?.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        let size = (self.collectionView?.frame.size)!
        collectionView?.backgroundColor = .clear
        flowLayout.itemSize = size
        collectionView?.contentInset.top = 0.0
        collectionView?.contentInset.bottom = 0.0
        collectionView?.reloadData()
    }
    
    func saveNowPlaying() {
        self.nowPlayingPlaylist.update {
            self.nowPlayingPlaylist.games.removeAll()
            self.nowPlayingPlaylist.games.append(contentsOf: self.games)
        }
    }
    
    fileprivate class func containSameElements<T: Comparable>(_ array1: [T], _ array2: [T]) -> Bool {
        guard array1.count == array2.count else {
            return false
        }
        return array1.sorted() == array2.sorted()
    }
    
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: self.collectionView!)
        self.movingIndexPath = collectionView?.indexPathForItem(at: location)
        let cell = (self.collectionView?.cellForItem(at: self.movingIndexPath!))!
        switch(gesture.state) {
            
        case .began:
            guard let indexPath = self.movingIndexPath else { break }
            self.setEditing(true, animated: true)
            self.removeWiggleAnimation(from: cell)
            UIView.animate(withDuration: 0.25,
                           delay: 0.0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 1.0,
                           options: .curveEaseOut,
                           animations: {
                            cell.contentView.alpha = 0.8
                            cell.contentView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            },
                           completion: nil)
            collectionView?.beginInteractiveMovementForItem(at: indexPath)
        case .changed:
            collectionView?.updateInteractiveMovementTargetPosition(location)
        case .ended:
            UIView.animate(withDuration: 0.25,
                           delay: 0.0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 1.0,
                           options: .curveEaseOut,
                           animations: {
                            cell.contentView.alpha = 1.0
                            cell.contentView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            },
                           completion: nil)
            self.addWiggleAnimation(to: cell)
            collectionView?.endInteractiveMovement()
            self.scroll(to: (self.movingIndexPath?.item)!)
        default:
            UIView.animate(withDuration: 0.25,
                           delay: 0.0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 1.0,
                           options: .curveEaseOut,
                           animations: {
                            cell.contentView.alpha = 1.0
                            cell.contentView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            },
                           completion: nil)
            self.addWiggleAnimation(to: cell)
            collectionView?.cancelInteractiveMovement()
            self.scroll(to: (self.movingIndexPath?.item)!)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addToNowPlaying" {
            let newNavController = segue.destination as! UINavigationController
            let addToPlaylistViewController = newNavController.topViewController as! AddToPlaylistViewController
            addToPlaylistViewController.delegate = self
            addToPlaylistViewController.title = "Add to Now Playing"
        }
    }
    
    @IBAction func handleTapEdit(sender: UIBarButtonItem) {
        self.navigationController?.navigationBar.tintColor = .white
        if self._blurViewState == .full {
            let newButton = UIBarButtonItem(barButtonSystemItem: self.upNextTableView!.isEditing ? .edit : .done, target: self, action: #selector(handleTapEdit))
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton
            self.upNextTableView?.setEditing(!self.upNextTableView!.isEditing, animated: true)
            self.inEditMode = self.upNextTableView!.isEditing
        } else {
            if self.inEditMode == true {
                self.stopWiggle()
                self.longPressGesture?.isEnabled = false
                self.inEditMode = false
                if self.games.count > 0 {
                    let newButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(handleTapEdit))
                    self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton
                } else {
                    self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
                }
                self.addBarButtonItem?.isEnabled = true
            } else {
                let newButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleTapEdit))
                newButton.tintColor = .white
                self.startWiggle()
                self.longPressGesture?.isEnabled = true
                self.inEditMode = true
                self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton

                self.addBarButtonItem?.isEnabled = false
            }
            for vc in orderedViewControllers {
                vc.setEditMode(editMode: self.inEditMode, animated: true)
            }
        }
    }
    
    @IBAction func moveViewLeftRight(sender: UIPageControl) {
        // Move to Right
        self.scroll(to: sender.currentPage)
    }
    
    private func scroll(to index: Int) {
        self.flowLayout.currentPage = index
        var newOffset: CGFloat = 0.0
        
        if (index < self.currentIndex) {
            newOffset = self.flowLayout.pageWidth * CGFloat(self.flowLayout.currentPage)
        } else {
            newOffset = self.flowLayout.pageWidth * CGFloat(self.flowLayout.currentPage) + self.flowLayout.sectionInset.left + self.flowLayout.sectionInset.right
        }
        self.currentIndex = index
        // Account for header
        self.collectionView?.scrollRectToVisible(CGRect(x: newOffset, y: (self.collectionView?.bounds.origin.y)!, width: self.flowLayout.pageWidth, height: (self.collectionView?.frame.height)!), animated: true)
    }
    
    private func startWiggle() {
        for cell in (self.collectionView?.visibleCells)! {
            addWiggleAnimation(to: cell as UICollectionViewCell)
        }
        self.isWiggling = true
    }
    
    private func stopWiggle() {
        for cell in (self.collectionView?.visibleCells)! {
            cell.layer.removeAnimation(forKey: "rotation")
            cell.layer.removeAnimation(forKey: "bounce")
        }
        self.isWiggling = false
    }
    
    func addWiggleAnimation(to cell: UICollectionViewCell) {
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        cell.layer.add(rotationAnimation(), forKey: "rotation")
        cell.layer.add(bounceAnimation(), forKey: "bounce")
        CATransaction.commit()
    }
    
    func removeWiggleAnimation(from cell: UICollectionViewCell) {
        cell.layer.removeAnimation(forKey: "rotation")
        cell.layer.removeAnimation(forKey: "bounce")
    }
    
    private func rotationAnimation() -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        let angle = CGFloat(0.01)
        let duration = TimeInterval(0.1)
        let variance = Double(0.025)
        animation.values = [angle, -angle]
        animation.autoreverses = true
        animation.duration = self.randomizeInterval(interval: duration, withVariance: variance)
        animation.repeatCount = Float.infinity
        return animation
    }
    
    private func bounceAnimation() -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        let bounce = CGFloat(1.0)
        let duration = TimeInterval(0.12)
        let variance = Double(0.025)
        animation.values = [bounce, -bounce]
        animation.autoreverses = true
        animation.duration = self.randomizeInterval(interval: duration, withVariance: variance)
        animation.repeatCount = Float.infinity
        return animation
    }
    
    private func randomizeInterval(interval: TimeInterval, withVariance variance:Double) -> TimeInterval {
        let random = (Double(arc4random_uniform(1000)) - 500.0) / 500.0
        return interval + variance * random;
    }
    
    func notesTyping(textView: UITextView) {
        self.currentlyTypingTextView = textView
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneTyping))
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = false
    }
    
    func doneTyping(sender: UIBarButtonItem) {
        self.currentlyTypingTextView?.resignFirstResponder()
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addTapped))
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = true
    }
    
    func addTapped(sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "addToNowPlaying", sender: sender)
    }
    
    func didDelete(viewController: NowPlayingGameViewController, uuid: String) {
        for i in 0..<self.orderedViewControllers.count {
            if self.orderedViewControllers[i].game?.uuid == uuid {
                let _ = self.orderedViewControllers.remove(at: i)
                let game = self.games.remove(at: i)
                let _ = self.gameIds.remove(at: i)
                game.update {
                    game.nowPlaying = false
                }
                self.collectionView?.deleteItems(at: [IndexPath(item: i, section: 0)])
                self.pageControl?.numberOfPages -= 1
                break
            }
        }
        if self.games.count == 0 {
            if self.inEditMode {
                self.handleTapEdit(sender: UIBarButtonItem())
            } else {
                self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
            }
            UIView.transition(with: self.addBackgroundView!, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.addBackgroundView?.isHidden = false
            }, completion: nil)
        }
        self.updatePlaylist()
    }
    
    func updatePlaylist() {
        self.nowPlayingPlaylist.update {
            self.nowPlayingPlaylist.games.removeAll()
            self.nowPlayingPlaylist.games.append(contentsOf: self.games)
        }
    }
    
    // MARK: handleTapDetails
    
    @IBAction func handleTapDimView(sender: UITapGestureRecognizer) {
        if self.inEditMode {
            self.handleTapEdit(sender: UIBarButtonItem())
        }
        self.blurTopLayoutConstraint?.constant = -50.0
        self.blurViewState = .minimal

        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.dimView?.alpha = 0.0
                        self.visibleView?.layoutIfNeeded()
        },
                       completion: nil)
    }
    
    @IBAction func handleTapDetails(sender: UITapGestureRecognizer) {
        if self.gamesUpNext.count == 0 {
            return
        }
        if self.inEditMode {
            self.handleTapEdit(sender: UIBarButtonItem())
        }
        let maxHeight = max(-self.visibleView!.bounds.height * 0.9, 55.0 * CGFloat(-self.gamesUpNext.count) - 50.0)

        var newAlpha: CGFloat = 0.0
        // Show percent slider
        switch (self._blurViewState) {
        case .minimal:
            self.blurTopLayoutConstraint?.constant = maxHeight
            self.blurViewState = .full
            newAlpha = 0.5
            break
        case .full:
            self.blurTopLayoutConstraint?.constant = -50.0
            self.blurViewState = .minimal
            break
        }
        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.dimView?.alpha = newAlpha
                        self.visibleView?.layoutIfNeeded()
        },
                       completion: nil)
    }
    
    // MARK: handlePanDetails
    
    @IBAction func handlePanDetails(recognizer:UIPanGestureRecognizer) {
        if self.inEditMode {
            self.handleTapEdit(sender: UIBarButtonItem())
        }
        let maxHeight = max(-self.visibleView!.bounds.height * 0.9, 55.0 * CGFloat(-self.gamesUpNext.count) - 50.0)
        // Update view when user drags it around
        if recognizer.state == .began || recognizer.state == .changed {
            let translation = recognizer.translation(in: self.visibleView!)
            var newY: CGFloat = 0.0
            var newAlpha: CGFloat = 0.0
            // If above the limit, resist pan
            if self.blurTopLayoutConstraint!.constant + translation.y < maxHeight {
                newY = self.blurTopLayoutConstraint!.constant + (translation.y / 2.0)
                newAlpha = 0.5
            } else {
                newY = self.blurTopLayoutConstraint!.constant + translation.y
                newAlpha = ((newY + 50.0) / (maxHeight + 50.0)) / 2.0
            }
            self.blurTopLayoutConstraint?.constant = newY
            if self.gamesUpNext.count > 0 {
                self.dimView?.alpha = newAlpha
            }
            recognizer.setTranslation(CGPoint.zero, in: self.visibleView!)
            self.visibleView?.layoutIfNeeded()
            self.dimView?.isUserInteractionEnabled = false
            
            // When the pan ends, determine where the view should go
        } else if recognizer.state == .ended {
            let velocity = recognizer.velocity(in: self.visibleView!).y
            
            // If the view is above the top, spring down to a full view
            if self.blurTopLayoutConstraint!.constant < maxHeight {
                self.blurTopLayoutConstraint?.constant = maxHeight

                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.6,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: {
                                if self.gamesUpNext.count > 0 {
                                    self.dimView?.alpha = 0.5
                                }
                                self.visibleView?.layoutIfNeeded()
                },
                               completion: nil)
                if self.gamesUpNext.count == 0 {
                    self.blurViewState = .minimal
                } else {
                    self.blurViewState = .full
                }
                
                // If the view is above middle, or if the user was swiping up when they ended, fling to top and collide with top boundary
            } else if (self.blurTopLayoutConstraint!.constant < (maxHeight / 2.0) && velocity < 300) || velocity < -300 {
                self.blurTopLayoutConstraint?.constant = maxHeight
                let animationTime: TimeInterval = ((0.4 - 1.0) * (min(Double(velocity * -1.0), 1000.0) - 300)/(1000 - 300) + 1.0)
                UIView.animate(withDuration: animationTime,
                               delay: 0.0,
                               usingSpringWithDamping: 1.0,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: {
                                if self.gamesUpNext.count > 0 {
                                    self.dimView?.alpha = 0.5
                                }
                                self.visibleView?.layoutIfNeeded()
                },
                               completion: nil)
                if self.gamesUpNext.count == 0 {
                    self.blurViewState = .minimal
                } else {
                    self.blurViewState = .full
                }
                
                // If the view is below the middle, or if the user was swiping down when they ended, return to minimal state with a spring bounce
            } else if (self.blurTopLayoutConstraint!.constant > (maxHeight / 2.0) && velocity > -300) || velocity > 300 {
                let animationTime: TimeInterval = ((0.4 - 1.0) * (min(Double(velocity), 1000.0) - 300)/(1000 - 300) + 1.0)
                self.blurTopLayoutConstraint?.constant = -50
                UIView.animate(withDuration: animationTime,
                               delay: 0.0,
                               usingSpringWithDamping: 0.6,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: {
                                self.dimView?.alpha = 0.0
                                self.visibleView?.layoutIfNeeded()
                },
                               completion: nil)
                self.blurViewState = .minimal
            }
        }
    }
}

extension NowPlayingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gamesUpNext.count
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.gamesUpNext.remove(at: indexPath.row)
            self.upNextPlaylist.update {
                self.upNextPlaylist.games.removeAll()
                self.upNextPlaylist.games.append(contentsOf: self.gamesUpNext)
            }
            self.upNextTableView?.deleteRows(at: [indexPath], with: .automatic)
            
            if self.gamesUpNext.count == 0 {
                self.handleTapDimView(sender: UITapGestureRecognizer())
                self.upNextTableView?.reloadData()
                return
            }
            let maxHeight = max(-self.visibleView!.bounds.height * 0.9, 55.0 * CGFloat(-self.gamesUpNext.count) - 50.0)
            self.blurTopLayoutConstraint?.constant = maxHeight

            UIView.animate(withDuration: 0.4,
               delay: 0.0,
               usingSpringWithDamping: 1.0,
               initialSpringVelocity: 0,
               options: .curveEaseIn,
               animations: {
                self.visibleView?.layoutIfNeeded()
            },
               completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PlaylistAddTableCell
        cell.showsReorderControl = true
        cell.backgroundColor = .clear

        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = UIEdgeInsetsMake(0, 67.0, 0, 0)
        }
        if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
            cell.layoutMargins = .zero
        }
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.preservesSuperviewLayoutMargins = false
        }

        let game = self.gamesUpNext[indexPath.row]
        cell.playlistState = .remove
        cell.game = game
        cell.isHandleHidden = false
        if let smallUrl = game.gameFields?.image?.smallUrl {
            cell.cacheCompletionHandler = {
                (image, error, cacheType, imageUrl) in
                if image != nil {
                    if cacheType == .none {
                        UIView.transition(with: cell.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                            cell.set(image: image!)
                        }, completion: nil)
                    } else {
                        cell.set(image: image!)
                    }
                }
            }
            if let url = URL(string: smallUrl) {
                cell.loadImage(url: url)
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let game = self.gamesUpNext.remove(at: sourceIndexPath.row)
        self.gamesUpNext.insert(game, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if self.gamesUpNext.count > 0 {
            return 0.5
        } else {
            return 30.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.gamesUpNext.count > 0 {
            return UIView(frame: .zero)
        } else {
            let gamesLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: 30.0))
            gamesLabel.text = "Add games to Up Next from your library."
            gamesLabel.textAlignment = .center
            gamesLabel.textColor = .lightGray
            return gamesLabel
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! PlaylistAddTableCell
        tableView.deselectRow(at: indexPath, animated: true)
        let center = CGPoint(x: cell.center.x, y: cell.center.y + self.navigationController!.navigationBar.frame.maxY + self.blurView!.frame.minY + tableView.frame.minY)
        let snapshotView = self.snapshotOfCell(cell.contentView)
        let whiteView = UIView(frame: snapshotView.frame)
        let shadowView = UIView(frame: snapshotView.frame)
        whiteView.backgroundColor = .white
        whiteView.alpha = 0.0
        snapshotView.addSubview(whiteView)
        shadowView.addSubview(snapshotView)
        shadowView.layer.shadowRadius = 20.0
        shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 20.0)
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.5
        shadowView.backgroundColor = .white
        shadowView.center = center
        self.view.addSubview(shadowView)
        
        self.handleTapDimView(sender: UITapGestureRecognizer())
        var game: Game?
        self.upNextPlaylist?.update {
            game = self.upNextPlaylist!.games.remove(at: indexPath.row)
        }
        self.nowPlayingPlaylist?.update {
            self.nowPlayingPlaylist!.games.append(game!)
        }
        game?.update {
            game?.nowPlaying = true
        }
        self.loadPlaylists()
        let newCell = self.orderedViewControllers.last
        newCell?.hideView()
        
        snapshotView.clipsToBounds = true
        
        let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        cornerRadiusAnimation.fromValue = 0.0
        cornerRadiusAnimation.toValue = 5.0
        cornerRadiusAnimation.duration = 0.5
        cornerRadiusAnimation.isRemovedOnCompletion = false
        cornerRadiusAnimation.fillMode = kCAFillModeForwards
        
        snapshotView.layer.add(cornerRadiusAnimation, forKey: "cornerRadius")
        shadowView.layer.add(cornerRadiusAnimation, forKey: "cornerRadius")
        
        let distanceAnimation = CABasicAnimation(keyPath: "shadowOffset")
        distanceAnimation.fromValue = CGSize(width: 0.0, height: 20.0)
        distanceAnimation.toValue = CGSize(width: 0.0, height: 0.0)
        distanceAnimation.duration = 0.5
        distanceAnimation.isRemovedOnCompletion = false
        distanceAnimation.fillMode = kCAFillModeForwards
        
        let shadowRadiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        shadowRadiusAnimation.fromValue = 20.0
        shadowRadiusAnimation.toValue = 1.0
        shadowRadiusAnimation.duration = 0.5
        shadowRadiusAnimation.isRemovedOnCompletion = false
        shadowRadiusAnimation.fillMode = kCAFillModeForwards

        UIView.transition(with: self.addBackgroundView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
            let newButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.handleTapEdit))
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton
            self.addBackgroundView?.isHidden = true
        }, completion: nil)
        UIView.animate(withDuration: 0.5, animations: {
            shadowView.center = self.view.center
            shadowView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            shadowView.layer.add(distanceAnimation, forKey: "shadowOffset")
            shadowView.layer.add(shadowRadiusAnimation, forKey: "shadowRadius")
            UIView.animate(withDuration: 0.5, animations: {
                whiteView.alpha = 1.0
                shadowView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: { _ in
                newCell?.animateGrowing(initialFrame: shadowView.frame)
                shadowView.removeFromSuperview()
            })
        })
        self.pageControl?.numberOfPages = self.orderedViewControllers.count
        self.pageControl?.currentPage = self.orderedViewControllers.count
        self.collectionView?.scrollToItem(at: IndexPath(item: self.orderedViewControllers.count - 1, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        let visualView = UIVisualEffectView(frame: inputView.frame)
        visualView.effect = UIBlurEffect(style: .extraLight)
        visualView.translatesAutoresizingMaskIntoConstraints = false
        
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        visualView.addSubview(cellSnapshot)
        return visualView
    }
    
}

extension NowPlayingViewController: AddToPlaylistViewControllerDelegate {
    func didChoose(games: List<Game>) {
        for game in games {
            game.update {
                game.nowPlaying = true
            }
        }
        self.games += games.map{$0}
        self.saveNowPlaying()
    }
    func dismissView(_ vc: AddToPlaylistViewController) {
        self._isDismissing = true
        vc.dismiss(animated: true, completion: nil)
    }
}

extension NowPlayingViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.orderedViewControllers.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! NowPlayingGameViewCell
        let nowPlayingViewController = self.orderedViewControllers[indexPath.item]
        if nowPlayingViewController.delegate == nil {
            nowPlayingViewController.delegate = self
        }
        
        let nowPlayingView = (nowPlayingViewController.view)!
        nowPlayingView.setNeedsLayout()
        nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        cell.contentView.addSubview(nowPlayingView)

        NSLayoutConstraint(item: nowPlayingView,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .leading,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: nowPlayingView,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .trailing,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: nowPlayingView,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .top,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: nowPlayingView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        
        if inEditMode {
            self.addWiggleAnimation(to: cell as UICollectionViewCell)
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = (self.collectionView?.frame.size)!
        size.height -= 40
        size.width -= 40
        return size
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.pageControl?.currentPage = self.flowLayout.currentPage
        self.currentIndex = self.flowLayout.currentPage
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt source: IndexPath, to destination: IndexPath) {
        let gameVc = self.orderedViewControllers.remove(at: source.item)
        let game = self.games.remove(at: source.item)
        self.games.insert(game, at: destination.item)
        
        self.updatePlaylist()
        
        self.orderedViewControllers.insert(gameVc, at: destination.item)
        self.pageControl?.currentPage = destination.item
    }
}
