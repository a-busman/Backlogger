//
//  GameInterfaceController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/20/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import WatchKit

protocol GameInterfaceDelegate {
    func didChange(game: WatchGame)
}

class GameInterfaceController: WKInterfaceController {
    var game: WatchGame?
    var delegate: GameInterfaceDelegate?
    
    @IBOutlet weak var finishedSwitch: WKInterfaceSwitch!
    @IBOutlet weak var favoriteSwitch: WKInterfaceSwitch!
    @IBOutlet weak var progressBar:    WKInterfaceSlider!
    @IBOutlet weak var progressLabel:  WKInterfaceLabel!
    @IBOutlet weak var ratingGroup:    WKInterfaceGroup!
    @IBOutlet weak var star1Image:     WKInterfaceImage!
    @IBOutlet weak var star2Image:     WKInterfaceImage!
    @IBOutlet weak var star3Image:     WKInterfaceImage!
    @IBOutlet weak var star4Image:     WKInterfaceImage!
    @IBOutlet weak var star5Image:     WKInterfaceImage!
    
    var starImages: [WKInterfaceImage] = []

    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if let dictContext = context as? [String : Any], let gameContext = dictContext["game"] as? WatchGame {
            self.delegate = dictContext["delegate"] as? GameInterfaceDelegate
            self.game = gameContext
            self.setTitle(gameContext.name)
            self.finishedSwitch.setOn(self.game!.complete)
            self.progressBar.setValue(Float(self.game!.progress))
            self.favoriteSwitch.setOn(self.game!.favorite)
            self.progressLabel.setText("\(self.game!.progress)%")
            self.starImages.append(self.star1Image)
            self.starImages.append(self.star2Image)
            self.starImages.append(self.star3Image)
            self.starImages.append(self.star4Image)
            self.starImages.append(self.star5Image)
            self.updateStars(self.game!.rating - 1)
        }
    }
    override func willActivate() {
        super.willActivate()
    }
    
    override func willDisappear() {
        super.willDisappear()
        if self.game != nil {
            self.delegate?.didChange(game: self.game!)
        }
    }
    
    @IBAction func finishedChanged(value: Bool) {
        self.game?.complete = value
    }
    
    @IBAction func favoriteChanged(value: Bool) {
        self.game?.favorite = value
    }
    
    @IBAction func progressBarChanged(value: Float) {
        self.game?.progress = Int(value)
        self.progressLabel.setText("\(Int(value))%")
    }
    
    @IBAction func ratingHandler(sender: WKGestureRecognizer) {
        let location = sender.locationInObject()
        let starIndex = Int(location.x / 23.0) // group width = 115, 115 / 5 = 23
        self.updateStars(starIndex)
        self.game?.rating = max(min(starIndex + 1, 5), 0)
    }
    
    private func updateStars(_ index: Int) {
        for (i, star) in self.starImages.enumerated() {
            if index >= i {
                star.setImage(UIImage(systemName: "star.fill"))
            } else {
                star.setImage(UIImage(systemName: "star"))
            }
        }
    }
}
