//
//  CollectionViewCell.swift
//  Backlogger
//
//  Created by Alex Busman on 6/26/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class CharacterCell: UICollectionViewCell {
    @IBOutlet weak var characterImageView: UIImageView?
    @IBOutlet weak var characterLabel: UILabel?
    @IBOutlet weak var blurView: UIVisualEffectView?
    @IBOutlet weak var blurImage: UIImageView?
    
    var characterImage: UIImage?
    
    override func prepareForReuse() {
        self.characterImageView?.image = nil
        self.characterImage = nil
        self.blurView?.isHidden = true
    }
    
    func showImage() {
        if let image = self.characterImage {
            self.characterImageView?.image = image
            self.blurView?.isHidden = true
        } else {
            self.characterImageView?.image = #imageLiteral(resourceName: "new_playlist")
            self.blurView?.isHidden = false
            self.blurImage?.image = #imageLiteral(resourceName: "character")
        }
    }
    
    func hideImage() {
        self.blurView?.isHidden = false
        self.characterImageView?.image = #imageLiteral(resourceName: "new_playlist")
    }
}
