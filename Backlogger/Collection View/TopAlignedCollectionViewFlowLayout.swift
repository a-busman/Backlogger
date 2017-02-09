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
                        TopAlignedCollectionViewFlowLayout.alignToTopForSameLineElements(sameLineElements: sameLineElements)
                        sameLineElements.removeAll()
                    }
                    sameLineElements.append(element)
                }
            }
            TopAlignedCollectionViewFlowLayout.alignToTopForSameLineElements(sameLineElements: sameLineElements) // align one more time for the last line
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
    
    private class func alignToTopForSameLineElements(sameLineElements: [UICollectionViewLayoutAttributes])
    {
        if sameLineElements.count < 1
        {
            return
        }
        let sorted = sameLineElements.sorted { (obj1: UICollectionViewLayoutAttributes, obj2: UICollectionViewLayoutAttributes) -> Bool in
            
            let height1 = obj1.frame.size.height
            let height2 = obj2.frame.size.height
            let delta = height1 - height2
            return delta <= 0
        }
        if let tallest = sorted.last
        {
            for obj in sameLineElements
            {
                obj.frame = obj.frame.offsetBy(dx: 0, dy: tallest.frame.origin.y - obj.frame.origin.y)
            }
        }
    }
}
