//
//  LibraryViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class LibraryViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView?
    
    var flowLayout: UICollectionViewFlowLayout {
        return self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    let reuseIdentifier = "console_cell"

    
    var orderedViewControllers: [ConsoleViewController] = [ConsoleViewController(),
                                                           ConsoleViewController(),
                                                           ConsoleViewController(),
                                                           ConsoleViewController(),
                                                           ConsoleViewController(),
                                                           ConsoleViewController(),
                                                           ConsoleViewController(),
                                                           ConsoleViewController()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let size = (self.collectionView?.frame.size)!
        collectionView?.backgroundColor = .clear
        
        flowLayout.itemSize = CGSize(width: size.width / 2.0, height: size.width / 2.0)
    }
}

extension LibraryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.orderedViewControllers.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let consoleViewController = self.orderedViewControllers[indexPath.item]
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        let consoleView = (consoleViewController.view)!
        consoleView.translatesAutoresizingMaskIntoConstraints = false
        consoleView.setNeedsLayout()
        consoleView.layoutIfNeeded()
        cell.contentView.addSubview(consoleView)
        //cell.bounds.size = (self.collectionView?.bounds.size)!
        
        NSLayoutConstraint(item: consoleView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: consoleView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: consoleView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: consoleView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = (self.collectionView?.frame.size)!
        size.width = (size.width / 2.0)
        size.height = size.width
        return size
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt source: IndexPath, to destination: IndexPath) {
        let game = self.orderedViewControllers.remove(at: source.item)
        self.orderedViewControllers.insert(game, at: destination.item)
    }
}
