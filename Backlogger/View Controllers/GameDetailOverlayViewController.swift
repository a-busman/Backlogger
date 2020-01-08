//
//  GameDetailOverlayViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

protocol GameDetailOverlayViewControllerDelegate {
    func didTapDetails()
    func didDelete(viewController: GameDetailOverlayViewController, uuid: String)
    func notesTyping(textView: UITextView)
}

class GameDetailOverlayViewController: UIViewController {
    @IBOutlet weak var titleLabel:           UILabel?
    @IBOutlet weak var completionPercentage: UILabel?
    @IBOutlet weak var platformLabel:        UILabel?
    @IBOutlet weak var progressSliderView:   UISlider?
    @IBOutlet weak var completionView:       UIView?
    @IBOutlet weak var completionCheckImage: UIImageView?
    @IBOutlet weak var completionLabel:      UILabel?
    @IBOutlet weak var detailsGestureView:   UIView?
    @IBOutlet weak var pullTabView:          UIView?
    @IBOutlet weak var playPauseButton:      UIButton?
    @IBOutlet weak var favouriteButton:      UIButton?
    @IBOutlet weak var finishedButton:       UIButton?
    @IBOutlet weak var ratingContainerView:  UIView?
    @IBOutlet weak var notesTextView:        UITextView?
    @IBOutlet weak var starStackView:        UIStackView?
    
    var delegate: GameDetailOverlayViewControllerDelegate?
    
    private var _game:  Game?
    
    enum ButtonState {
        case heldDown
        case down
        case up
    }
    
    enum StatsButtonState {
        case selected
        case normal
    }
    
    private var buttonState = ButtonState.up
    
    private var playButtonState = StatsButtonState.selected
    private var favouriteButtonState = StatsButtonState.normal
    private var finishedButtonState = StatsButtonState.normal
    
    let imageCellReuseIdentifier = "image_cell"
    
    enum CompletionState {
        case finished
        case inProgress
    }

    private var completionState = CompletionState.inProgress
    
    var game: Game? {
        get {
            return self._game
        }
        set(newGame) {
            self._game = newGame
            self.updateStats()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateStats()
        
    }
    
    func updateStats() {
        self.titleLabel?.text = self._game?.gameFields?.name
        
        completionPercentage?.text = "\(self._game!.progress)%"
        progressSliderView?.value = Float(self._game!.progress)
        self.platformLabel?.text = (self._game?.platform?.name)!

        if self._game!.finished == true {
            self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light")
            self.completionLabel?.text = "Finished"
        } else {
            self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light_filled")
            self.completionLabel?.text = "In Progress"
        }
        if let game = self._game {
            if !game.favourite {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart-empty-white"), for: .normal)
                self.favouriteButtonState = .normal
            } else {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                self.favouriteButtonState = .selected
            }
            if !game.nowPlaying {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "play-white"), for: .normal)
                self.playButtonState = .normal
            } else {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "pause-white"), for: .normal)
                self.playButtonState = .selected
            }
            if !game.finished {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-empty-white"), for: .normal)
                self.finishedButtonState = .normal
            } else {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-green"), for: .normal)
                self.finishedButtonState = .selected
            }
            for (i, star) in self.starStackView!.arrangedSubviews.enumerated() {
                if let starImage = star as? UIImageView {
                    if game.rating > i {
                        starImage.image = #imageLiteral(resourceName: "star-yellow")
                    } else {
                        starImage.image = #imageLiteral(resourceName: "star-white")
                    }
                }
            }
            self.notesTextView?.text = self._game?.notes
        }
    }
    
    func updateFinished() {
        if (self._game?.finished)! == true {
            self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light")
            self.completionLabel?.text = "In Progress"
        } else {
            self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light_filled")
            self.completionLabel?.text = "Finished"
        }
    }
    
    @IBAction func handleSlider(sender: UISlider) {
        let remainder = Int(sender.value) % 5
        let generator = UISelectionFeedbackGenerator()
        var newValue: Int = 0
        if remainder < 2 {
            newValue = Int(sender.value) - remainder
        } else {
            newValue = Int(sender.value) + 5 - remainder
        }
        sender.value = Float(newValue)
        if let game = self._game, game.progress != newValue {
            generator.selectionChanged()
            self.completionPercentage?.text = "\(newValue)%"
            game.update {
                game.progress = newValue
            }
        }
    }
    
    @IBAction func tappedDetails(sender: UITapGestureRecognizer) {
        delegate?.didTapDetails()
    }
    
    @IBAction func ratingHandler(sender: UIGestureRecognizer) {
        let location = sender.location(in: self.ratingContainerView!)
        let starIndex = Int(location.x / ((self.ratingContainerView?.bounds.width)! / 5.0))
        updateStars(starIndex)
    }
    
    private func updateStars(_ index: Int) {
        for (i, star) in self.starStackView!.arrangedSubviews.enumerated() {
            if let starImage = star as? UIImageView {
                if index >= i {
                    starImage.image = #imageLiteral(resourceName: "star-yellow")
                } else {
                    starImage.image = #imageLiteral(resourceName: "star-white")
                }
            }
        }

        if let game = self._game, game.rating != index + 1 {
            UISelectionFeedbackGenerator().selectionChanged()
            game.update {
                game.rating = index + 1
            }
        }
        self.notesTextView?.resignFirstResponder()
    }
    
    @IBAction func statsControlTouchUpInside(sender: UIButton!) {
        switch sender.tag {
        case 1:
            if self.favouriteButtonState == .selected {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart-empty-white"), for: .normal)
                self.favouriteButtonState = .normal
                self._game?.update {
                    self._game?.favourite = false
                }
            } else {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                self.favouriteButtonState = .selected
                self._game?.update {
                    self._game?.favourite = true
                }
            }
        case 2:
            if self.playButtonState == .selected {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "play-white"), for: .normal)
                self.playButtonState = .normal
                self._game?.update {
                    self._game?.nowPlaying = false
                }
                // Update in Now Playing playlist
                autoreleasepool {
                    let realm = try! Realm()
                    let nowPlayingPlaylist = realm.objects(Playlist.self).filter("isNowPlaying = true").first
                    if nowPlayingPlaylist != nil {
                        if let index = nowPlayingPlaylist?.games.firstIndex(where: { (item) -> Bool in
                            item.uuid == self._game!.uuid
                        }) {
                            nowPlayingPlaylist?.update {
                                nowPlayingPlaylist?.games.remove(at: index)
                            }
                        }
                    }
                }
                let actions = UIAlertController(title: "Remove from Now Playing?", message: nil, preferredStyle: .alert)
                actions.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in self.delegate?.didDelete(viewController: self, uuid: (self.game?.uuid)!)}))
                actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(actions, animated: true, completion: nil)
                if self.finishedButtonState != .selected {
                    self.completionLabel?.text = "Incomplete"
                    self.completionCheckImage?.image = #imageLiteral(resourceName: "empty_check")
                }
            } else {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "pause-white"), for: .normal)
                self.playButtonState = .selected
                self._game?.update {
                    self._game?.nowPlaying = true
                }
                // Update in Now Playing playlist
                autoreleasepool {
                    let realm = try! Realm()
                    let nowPlayingPlaylist = realm.objects(Playlist.self).filter("isNowPlaying = true").first
                    if nowPlayingPlaylist != nil {
                        nowPlayingPlaylist?.update {
                            nowPlayingPlaylist?.games.append(self._game!)
                        }
                    }
                }
                if self.finishedButtonState != .selected {
                    self.completionLabel?.text = "In Progress"
                    self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light_filled")
                }
            }
        case 3:
            if self.finishedButtonState == .selected {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-empty-white"), for: .normal)
                self.finishedButtonState = .normal
                self._game?.update {
                    self._game?.finished = false
                }
                if self.playButtonState != .selected {
                    self.completionLabel?.text = "Incomplete"
                    self.completionCheckImage?.image = #imageLiteral(resourceName: "empty_check")
                } else {
                    self.completionLabel?.text = "In Progress"
                    self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light_filled")
                }
            } else {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-green"), for: .normal)
                self.finishedButtonState = .selected
                self._game?.update {
                    self._game?.finished = true
                }
                self.completionLabel?.text = "Finished"
                self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light")
            }
        default:
            break
        }
        
        UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)}, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform.identity})
        })
        self.buttonState = .up
    }
    
    @IBAction func statsControlTouchDown(sender: UIButton!) {
        self.notesTextView?.resignFirstResponder()
        if self.buttonState == .up {
            self.buttonState = .down
        } else if self.buttonState == .down {
            self.buttonState = .heldDown
            UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)})
        }
    }
    
    @IBAction func statsControlTouchDragExit(sender: UIButton!) {
        self.buttonState = .up
        UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform.identity})
        self.notesTextView?.resignFirstResponder()
    }
}

extension GameDetailOverlayViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.notesTyping(textView: textView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.game?.update {
            self.game?.notes = textView.text
        }
    }
}
