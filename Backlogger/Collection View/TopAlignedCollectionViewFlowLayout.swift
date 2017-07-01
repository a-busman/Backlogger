//
//  TopAlignedCollectionViewFlowLayout.swift
//  Backlogger
//
//  Created by Alex Busman on 2/8/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit.UICollectionViewFlowLayout

class TopAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout
{
    var currentPage: Int = 0
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        if let attrs = super.layoutAttributesForElements(in: rect)
        {
            var baseline: CGFloat = 50
            var sameLineElements = [UICollectionViewLayoutAttributes]()
            for element in attrs
            {
                if element.representedElementCategory == .cell
                {
                    let frame = element.frame
                    let centerY = frame.midY
                    if abs(centerY - baseline) > 1
                    {
                        baseline = centerY
                        sameLineElements.removeAll()
                    }
                    sameLineElements.append(element)
                }
            }
            return attrs
        }
        return nil
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        let totalPages = collectionView.contentSize.width / (self.pageWidth + 40.0)
        if proposedContentOffset.x >= (collectionView.contentSize.width - collectionView.bounds.width) {
            self.currentPage = Int(totalPages)
            return proposedContentOffset
        }
        let proposedPage = floor((proposedContentOffset.x + (self.pageWidth / 2.0)) / self.pageWidth)
        
        var newProposedContentOffset = proposedContentOffset
        
        newProposedContentOffset.x = proposedPage * self.pageWidth
        self.currentPage = Int(proposedPage)
        
        return newProposedContentOffset
    }
    
    var pageWidth: CGFloat {
        return itemSize.width - 40.0
    }
}

class ImageCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        
        if proposedContentOffset.x >= (collectionView.contentSize.width - collectionView.bounds.width) {
            return proposedContentOffset
        }
        let proposedPage = floor((proposedContentOffset.x + (self.pageWidth / 2.0)) / self.pageWidth)
        
        var newProposedContentOffset = proposedContentOffset
        
        newProposedContentOffset.x = proposedPage * self.pageWidth
        
        return newProposedContentOffset
    }
    
    var pageWidth: CGFloat {
        return itemSize.width + minimumInteritemSpacing
    }
}
