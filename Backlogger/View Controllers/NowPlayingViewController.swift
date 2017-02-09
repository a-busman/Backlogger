//
//  NowPlayingViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class NowPlayingViewController: UIViewController, NowPlayingGameViewDelegate {
    
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var addBarButtonItem:  UIBarButtonItem?
    @IBOutlet weak var pageControl:       UIPageControl?
    @IBOutlet weak var collectionView:    UICollectionView?
    
    var flowLayout: TopAlignedCollectionViewFlowLayout {
        return self.collectionView?.collectionViewLayout as! TopAlignedCollectionViewFlowLayout
    }
    
    var currentIndex = 0
    var inEditMode = false
    
    let reuseIdentifier = "cell"
    
    var longPressGesture : UILongPressGestureRecognizer? = nil
    
    private var isWiggling = false
    private var movingIndexPath: IndexPath? = nil
    
    var orderedViewControllers: [NowPlayingGameViewController] = [NowPlayingGameViewController(gameId: "1"),
                                                                  NowPlayingGameViewController(gameId: "2"),
                                                                  NowPlayingGameViewController(gameId: "3"),
                                                                  NowPlayingGameViewController(gameId: "4")]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pageControl?.numberOfPages = orderedViewControllers.count
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(NowPlayingViewController.handleLongGesture))
        self.collectionView?.addGestureRecognizer(longPressGesture!)
        self.longPressGesture?.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        let size = (self.collectionView?.frame.size)!
        collectionView?.backgroundColor = .clear
        flowLayout.itemSize = size
        collectionView?.contentInset.top = 0.0
        collectionView?.contentInset.bottom = 0.0
    }
    
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: self.collectionView!)
        self.movingIndexPath = collectionView?.indexPathForItem(at: location)
        let cell = (self.collectionView?.cellForItem(at: self.movingIndexPath!))!
        switch(gesture.state) {
            
        case .began:
            guard let indexPath = movingIndexPath else { break }
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
        if self.inEditMode == true {
            let newButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(handleTapEdit))
            newButton.tintColor = .white
            self.stopWiggle()
            self.longPressGesture?.isEnabled = false
            self.inEditMode = false
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newButton
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
        for i in 0..<orderedViewControllers.count {
            if orderedViewControllers[i].uuid == uuid {
                orderedViewControllers.remove(at: i)
                self.collectionView?.deleteItems(at: [IndexPath(item: i, section: 0)])
                self.pageControl?.numberOfPages -= 1
                break
            }
        }
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

        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        let nowPlayingView = (nowPlayingViewController.view)!
        nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingView.setNeedsLayout()
        nowPlayingView.layoutIfNeeded()

        cell.contentView.addSubview(nowPlayingView)
        //cell.bounds.size = (self.collectionView?.bounds.size)!

        NSLayoutConstraint(item: nowPlayingView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: nowPlayingView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: nowPlayingView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: nowPlayingView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        
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
        let game = self.orderedViewControllers.remove(at: source.item)
        self.orderedViewControllers.insert(game, at: destination.item)
    }
    
    //func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    //    NSLog("moved")
    //}
}
