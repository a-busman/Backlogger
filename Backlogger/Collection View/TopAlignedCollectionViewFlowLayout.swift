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
        
        let currentXOffset = collectionView.contentOffset.x
        
        let approximatePage = currentXOffset / self.pageWidth
        let currentPage = (velocity.x < 0.0) ? floor(approximatePage) : ceil(approximatePage)
        
        var newProposedContentOffset = proposedContentOffset
        
        let flickedPages = round(velocity.x / self.flickVelocity)
        
        if (flickedPages != 0.0) {
            newProposedContentOffset.x = (currentPage + flickedPages) * self.pageWidth
            self.currentPage = Int(currentPage + flickedPages)
        } else {
            newProposedContentOffset.x = currentPage * self.pageWidth
            self.currentPage = Int(currentPage)
        }
        
        return newProposedContentOffset
    }
    
    var pageWidth: CGFloat {
        return itemSize.width - 40.0
    }
    
    var flickVelocity: CGFloat {
        return 2.0
    }
}
