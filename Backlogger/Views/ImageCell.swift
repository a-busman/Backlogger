//
//  ImageCell.swift
//  Backlogger
//
//  Created by Alex Busman on 2/22/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit.UICollectionViewCell

class ImageCell: UICollectionViewCell {
    override func prepareForReuse() {
        layer.removeAllAnimations()
        for view in contentView.subviews {
            view.removeFromSuperview()
        }
    }
}
