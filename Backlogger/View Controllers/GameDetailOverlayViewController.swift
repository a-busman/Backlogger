//
//  GameDetailOverlayViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class GameDetailOverlayViewController: UIViewController {
    @IBOutlet weak var titleLabel:           UILabel?
    @IBOutlet weak var completionPercentage: UILabel?
    @IBOutlet weak var platformLabel:        UILabel?
    @IBOutlet weak var progressSliderView:   UISlider?
    @IBOutlet weak var scrollView:           UIScrollView?
    @IBOutlet weak var contentView:          UIView?
    @IBOutlet weak var descriptionLabel:     UILabel?
    @IBOutlet weak var imageScrollView:      UIScrollView?
    @IBOutlet weak var publisherLabel:       UILabel?
    @IBOutlet weak var developerLabel:       UILabel?
    @IBOutlet weak var platformsLabel:       UILabel?
    @IBOutlet weak var genresLabel:          UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView?.delegate = self
        scrollView?.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 5.0, 0.0)
    }
    
    @IBAction func handleSlider(sender: UISlider) {
        let remainder = Int(sender.value) % 10
        var newValue: Int = 0
        if remainder < 5 {
            newValue = Int(sender.value) - remainder
        } else {
            newValue = Int(sender.value) + 10 - remainder
        }
        sender.value = Float(newValue)
        completionPercentage?.text = String(format: "%d%%", newValue)
    }
}

extension GameDetailOverlayViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}
