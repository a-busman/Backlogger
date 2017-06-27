//
//  CollectionViewCell.swift
//  Backlogger
//
//  Created by Alex Busman on 6/26/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class CharacterCell: UICollectionViewCell {
    @IBOutlet weak var characterBorder: UIView?
    @IBOutlet weak var characterLabel: UILabel?
    @IBOutlet weak var blurView: UIVisualEffectView?
    @IBOutlet weak var blurImage: UIImageView?
    
    var characterImage: UIImage?
    
    override func prepareForReuse() {
        self.characterImage = nil
        self.blurView?.isHidden = true
        if let imageView = self.characterBorder?.viewWithTag(9000) as? UIImageView {
            imageView.removeFromSuperview()
        }
    }
    
    func showImage() {
        self.blurView?.isHidden = true
    }
    
    func hideImage() {
        self.blurView?.isHidden = false
    }
}
