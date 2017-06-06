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
    
    private var _blurViewState = UpNextState.minimal
    
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
        self.upNextTableView?.tableFooterView = UIView(frame: .zero)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.tintColor = .white
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(NowPlayingViewController.handleLongGesture))
        self.collectionView?.addGestureRecognizer(longPressGesture!)
        self.longPressGesture?.isEnabled = false
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
        if self.games.count > 0 {
            let newButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(handleTapEdit))
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton
            self.addBackgroundView?.isHidden = true
        } else {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
            self.addBackgroundView?.isHidden = false
        }
        
        for game in self.games {
            newGameIds.append(game.uuid)
        }
        
        // Don't regenerate if games weren't changed.
        if !NowPlayingViewController.containSameElements(newGameIds, self.gameIds) {
            self.orderedViewControllers.removeAll()
            for game in self.games {
                let vc = NowPlayingGameViewController()
                vc.game = game
                
                self.orderedViewControllers.append(vc)
                vc.addDetails()
            }
            self.gameIds = newGameIds
            self.collectionView?.reloadData()
        }
        self.pageControl?.numberOfPages = orderedViewControllers.count
        
        self.upNextTableView?.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        let size = (self.collectionView?.frame.size)!
        collectionView?.backgroundColor = .clear
        flowLayout.itemSize = size
        collectionView?.contentInset.top = 0.0
        collectionView?.contentInset.bottom = 0.0
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
    
    @IBAction func handleTapEdit(sender:UIBarButtonItem) {
        self.navigationController?.navigationBar.tintColor = .white
        if self._blurViewState == .full {
            let newButton = UIBarButtonItem(barButtonSystemItem: self.upNextTableView!.isEditing ? .edit : .done, target: self, action: #selector(handleTapEdit))
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton
            self.upNextTableView?.setEditing(!self.upNextTableView!.isEditing, animated: true)
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
    
    func didDelete(viewController: NowPlayingGameViewController, uuid: String) {
        for i in 0..<self.orderedViewControllers.count {
            if self.orderedViewControllers[i].game?.uuid == uuid {
                self.orderedViewControllers.remove(at: i)
                let game = self.games.remove(at: i)
                game.update {
                    game.nowPlaying = false
                }
                self.collectionView?.deleteItems(at: [IndexPath(item: i, section: 0)])
                self.pageControl?.numberOfPages -= 1
                break
            }
        }
        if self.games.count <= 0 {
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
        if self.inEditMode {
            self.handleTapEdit(sender: UIBarButtonItem())
        }
        var newAlpha: CGFloat = 0.0
        // Show percent slider
        switch (self._blurViewState) {
        case .minimal:
            self.blurTopLayoutConstraint?.constant = -self.visibleView!.bounds.height * 0.75
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
        // Update view when user drags it around
        if recognizer.state == .began || recognizer.state == .changed {
            let translation = recognizer.translation(in: self.visibleView!)
            var newY: CGFloat = 0.0
            var newAlpha: CGFloat = 0.0
            // If above the limit, resist pan
            if self.blurTopLayoutConstraint!.constant + translation.y < (-self.visibleView!.bounds.height * 0.75) {
                newY = self.blurTopLayoutConstraint!.constant + (translation.y / 2.0)
                newAlpha = 0.5
            } else {
                newY = self.blurTopLayoutConstraint!.constant + translation.y
                newAlpha = (newY / (-self.visibleView!.bounds.height * 0.75)) / 2.0
            }
            self.blurTopLayoutConstraint?.constant = newY
            self.dimView?.alpha = newAlpha
            recognizer.setTranslation(CGPoint.zero, in: self.visibleView!)
            self.visibleView?.layoutIfNeeded()
            self.dimView?.isUserInteractionEnabled = false
            
            // When the pan ends, determine where the view should go
        } else if recognizer.state == .ended {
            let velocity = recognizer.velocity(in: self.visibleView!).y
            
            // If the view is above the top, spring down to a full view
            if self.blurTopLayoutConstraint!.constant < (-self.visibleView!.bounds.height * 0.75) {
                self.blurTopLayoutConstraint?.constant = -self.visibleView!.bounds.height * 0.75
                UIView.animate(withDuration: 0.4,
                               delay: 0.0,
                               usingSpringWithDamping: 0.6,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: {
                                self.dimView?.alpha = 0.5
                                self.visibleView?.layoutIfNeeded()
                },
                               completion: nil)
                self.blurViewState = .full
                
                // If the view is above middle, or if the user was swiping up when they ended, fling to top and collide with top boundary
            } else if (self.blurTopLayoutConstraint!.constant < (-self.visibleView!.bounds.height * 0.375) && velocity < 300) || velocity < -300 {
                self.blurTopLayoutConstraint?.constant = -self.visibleView!.bounds.height * 0.75
                let animationTime: TimeInterval = ((0.4 - 1.0) * (min(Double(velocity * -1.0), 1000.0) - 300)/(1000 - 300) + 1.0)
                UIView.animate(withDuration: animationTime,
                               delay: 0.0,
                               usingSpringWithDamping: 1.0,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: {
                                self.dimView?.alpha = 0.5
                                self.visibleView?.layoutIfNeeded()
                },
                               completion: nil)
                self.blurViewState = .full
                
                // If the view is below the middle, or if the user was swiping down when they ended, return to minimal state with a spring bounce
            } else if (self.blurTopLayoutConstraint!.constant > (-self.visibleView!.bounds.height * 0.375) && velocity > -300) || velocity > 300 {
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

extension NowPlayingViewController: UITableViewDataSource, UITableViewDelegate, PlaylistAddTableCellDelegate {
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
            self.upNextTableView?.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PlaylistAddTableCell
        cell.showsReorderControl = true
        cell.backgroundColor = .clear
        var indent: CGFloat = 0.0
        if indexPath.row < self.gamesUpNext.count - 1 {
            indent = 67.0
        }
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = UIEdgeInsetsMake(0, indent, 0, 0)
        }
        if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
            cell.layoutMargins = .zero
        }
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.preservesSuperviewLayoutMargins = false
        }

        let game = self.gamesUpNext[indexPath.row]
        cell.playlistState = .remove
        cell.delegate = self
        cell.game = game
        cell.isHandleHidden = false
        if let smallUrl = game.gameFields?.image?.smallUrl {
            cell.imageUrl = URL(string: smallUrl)
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
        }

        return cell
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        return
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let game = self.gamesUpNext.remove(at: sourceIndexPath.row)
        self.gamesUpNext.insert(game, at: destinationIndexPath.row)
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        return cellSnapshot
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
    }
    
    //func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    //    NSLog("moved")
    //}
}
