//
//  GameDetailsViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/24/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift
import Kingfisher

protocol GameDetailsViewControllerDelegate {
    func gamesCreated(gameField: GameField)
}

class GameDetailsViewController: UIViewController, ConsoleSelectionTableViewControllerDelegate, UITextViewDelegate {
    @IBOutlet weak var mainImageView:          UIImageView?
    @IBOutlet weak var titleLabel:             UILabel?
    @IBOutlet weak var yearLabel:              UILabel?
    @IBOutlet weak var platformButton:         UIButton?
    @IBOutlet weak var headerView:             UIVisualEffectView?
    @IBOutlet weak var headerContent:          UIView?
    @IBOutlet weak var shadowView:             UIView?
    @IBOutlet weak var detailsScrollView:      UIScrollView?
    @IBOutlet weak var detailsContentView:     UIView?
    @IBOutlet weak var descriptionView:        UILabel?
    @IBOutlet weak var imagesTitleLabel:       UILabel?
    @IBOutlet weak var imageCollectionView:    UICollectionView?
    @IBOutlet weak var informationTitleLabel:  UILabel?
    @IBOutlet weak var publisherLabel:         UILabel?
    @IBOutlet weak var developerLabel:         UILabel?
    @IBOutlet weak var platformsLabel:         UILabel?
    @IBOutlet weak var genresLabel:            UILabel?
    @IBOutlet weak var activityIndicator:      UIActivityIndicatorView?
    @IBOutlet weak var activityBackground:     UIView?
    @IBOutlet weak var addSymbolImage:         UIImageView?
    @IBOutlet weak var addLabel:               UILabel?
    @IBOutlet weak var addBackground:          UIView?
    @IBOutlet weak var statsButton:            UIView?
    @IBOutlet weak var progressIcon:           UIView?
    @IBOutlet weak var statsEffectView:        UIVisualEffectView?
    @IBOutlet weak var statsScrollView:        UIScrollView?
    @IBOutlet weak var statsLabel:             UILabel?
    @IBOutlet weak var percentageBlurView:     UIVisualEffectView?
    @IBOutlet weak var percentageVibrancyView: UIVisualEffectView?
    @IBOutlet weak var percentageLabel:        UILabel?
    @IBOutlet weak var playPauseButton:        UIButton?
    @IBOutlet weak var favouriteButton:        UIButton?
    @IBOutlet weak var finishedButton:         UIButton?
    @IBOutlet weak var completionLabel:        UILabel?
    @IBOutlet weak var completionImageView:    UIImageView?
    @IBOutlet weak var ratingContainerView:    UIView?
    @IBOutlet weak var notesTextView:          UITextView?
    @IBOutlet weak var progressSlider:         UISlider?

    @IBOutlet weak var firstStar:  UIImageView?
    @IBOutlet weak var secondStar: UIImageView?
    @IBOutlet weak var thirdStar:  UIImageView?
    @IBOutlet weak var fourthStar: UIImageView?
    @IBOutlet weak var fifthStar:  UIImageView?
    
    @IBOutlet weak var doneButton: UIBarButtonItem?
    
    var toastOverlay = ToastOverlayViewController()
    
    @IBOutlet weak var informationTopConstraint: NSLayoutConstraint?
    
    var images: [UIImage]?
    
    let imageCellReuseIdentifier = "image_cell"

    let headerBorder = CALayer()
    
    private var _selectedPlatforms = [Platform]()
    
    private var _state: State?
    
    private var _gameField: GameField?
    
    private var _game: Game?
    
    var gameFieldId: Int?
    
    var delegate: GameDetailsViewControllerDelegate?
    
    enum State {
        case addToLibrary
        case partialAddToLibrary
        case inLibrary
    }
    
    enum ViewState {
        case hidden
        case visible
    }
    
    enum ButtonState {
        case heldDown
        case down
        case up
    }
    
    enum StatsButtonState {
        case selected
        case normal
    }
    
    private var statsState = ViewState.hidden
    private var artViewProgressState = ViewState.hidden
    
    private var buttonState = ButtonState.up
    
    private var playButtonState = StatsButtonState.normal
    private var favouriteButtonState = StatsButtonState.normal
    private var finishedButtonState = StatsButtonState.normal
    
    private var percentTimer: Timer?
    
    var state: State? {
        get {
            return self._state
        }
        set(newState) {
            self._state = newState
        }
    }
    
    var gameField: GameField? {
        get {
            return self._gameField
        }
        set(newGame) {
            self._gameField = newGame
            self.titleLabel?.text = newGame?.name
            var yearLabelText = ""
            if let releaseDate = newGame?.releaseDate {
                if !releaseDate.isEmpty {
                    let index = releaseDate.index(releaseDate.startIndex, offsetBy: 4)
                    yearLabelText = releaseDate.substring(to: index)
                } else {
                    if let expectedDate = newGame?.expectedDate {
                        if expectedDate > 0 {
                            yearLabelText = String(expectedDate)
                        }
                    }
                }
            }
            self.yearLabel?.text = yearLabelText
        }
    }
    
    var game: Game? {
        get {
            return self._game
        }
        set(newGame) {
            self._game = newGame
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        autoreleasepool {
            let realm = try? Realm()
            if let gameFieldId = self.gameFieldId {
                if self._gameField == nil {
                    self._gameField = realm?.object(ofType: GameField.self, forPrimaryKey: gameFieldId)
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        if self._state == .addToLibrary {
            self.statsButton?.alpha = 0.0
            self.progressIcon?.alpha = 0.0
        } else {
            if self._state == .partialAddToLibrary {
                self.platformButton?.isEnabled = true
                self.statsButton?.alpha = (self.gameField?.ownedGames.count)! > 1 ? 0.0 : 1.0
                self.addLabel?.text = (self.gameField?.ownedGames.count)! > 1 ? "REMOVE ALL" : "REMOVE"
            } else {
                self.addLabel?.text = "REMOVE"
                self.statsButton?.alpha = 1.0
            }
            self.progressIcon?.alpha = 1.0
            self.addSymbolImage?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4.0)
            self.addBackground?.backgroundColor = .red
            self.showPercentage()
            self.percentTimer?.invalidate()
            self.percentTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(hidePercentage), userInfo: nil, repeats: false)
        }
        self.statsEffectView?.effect = nil
        self.statsEffectView?.isHidden = true
        self.statsScrollView?.alpha = 0.0
        self.statsButton?.layer.borderWidth = 1.0
        self.statsButton?.layer.borderColor = Util.appColor.cgColor
        
        self.percentageBlurView?.effect = nil
        self.percentageVibrancyView?.effect = nil
        self.percentageLabel?.alpha = 0.0
        
        var gameFields: GameField?
        gameFields = self._gameField ?? GameField()
        self.images = []
        if !(gameFields?.hasDetails)! {
            gameFields?.updateGameDetails { result in
                if let error = result.error {
                    NSLog("error: \(error.localizedDescription)")
                    return
                }
                self.updateGameDetails()
            }
        } else {
            self.updateGameDetails()
        }
        if let titleString = gameFields?.name {
            self.titleLabel?.text = titleString
        }
        var yearLabelText = ""
        if let releaseDate = gameFields?.releaseDate {
            if !releaseDate.isEmpty {
                let index = releaseDate.index(releaseDate.startIndex, offsetBy: 4)
                yearLabelText = releaseDate.substring(to: index)
            } else {
                if let expectedDate = gameFields?.expectedDate {
                    if expectedDate > 0 {
                        yearLabelText = String(expectedDate)
                    }
                }
            }
        }
        if yearLabelText == "" {
            yearLabelText = "Release Year Unknown"
        }
        self.yearLabel?.text = yearLabelText
        
        
        for game in (self.gameField?.ownedGames)! {
            self._selectedPlatforms.append(game.platform!)
        }
        
        var platformString = ""
        if self._state! != .inLibrary {
            if let gameList = self.gameField?.ownedGames {
                let aGameList = Array(gameList)
                if aGameList.count > 0 {
                    for i in 0..<(aGameList.endIndex - 1) {
                        let game = aGameList[i]
                        if (game.platform?.name?.characters.count)! < 10 {
                            platformString += (game.platform?.name)! + " • "
                        } else {
                            platformString += (game.platform?.abbreviation)! + " • "
                        }
                    }
                    let lastGame = aGameList[aGameList.endIndex - 1]
                    if (lastGame.platform?.name?.characters.count)! < 10 {
                        platformString += (lastGame.platform?.name)!
                    } else {
                        platformString += (lastGame.platform?.abbreviation)!
                    }
                }
            }
        } else {
            if (self._game?.platform?.name?.characters.count)! < 10 {
                platformString += (self._game?.platform?.name)!
            } else {
                platformString += (self._game?.platform?.abbreviation)!
            }
        }
        UIView.setAnimationsEnabled(false)
        self.platformButton?.setTitle(platformString, for: .normal)
        UIView.setAnimationsEnabled(true)
        if let mediumUrl = self._gameField?.image?.mediumUrl {
            self.mainImageView?.kf.setImage(with: URL(string: mediumUrl), placeholder: #imageLiteral(resourceName: "info_image_placeholder"), completionHandler: {
                (image, error, cacheType, imageUrl) in
                if image != nil {
                    if cacheType == .none {
                        UIView.transition(with: self.mainImageView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                            self.mainImageView?.image = image
                        }, completion: nil)
                    } else {
                        self.mainImageView?.image = image
                    }
                }
            })
        } else {
            self.mainImageView?.image = #imageLiteral(resourceName: "info_image_placeholder")
        }

        self.descriptionView?.text = gameFields?.deck
        self.toastOverlay.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(toastOverlay.view)
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerX,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerY,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 250.0
            ).isActive = true
        NSLayoutConstraint(item: toastOverlay.view,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 250.0
            ).isActive = true
        if let game = self._game {
            if !game.favourite {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart-empty"), for: .normal)
                self.favouriteButtonState = .normal
            } else {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                self.favouriteButtonState = .selected
            }
            if !game.nowPlaying {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "play-black"), for: .normal)
                self.playButtonState = .normal
                if self.finishedButtonState != .selected {
                    self.completionLabel?.text = "Incomplete"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-empty")
                }
            } else {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                self.playButtonState = .selected
                if self.finishedButtonState != .selected {
                    self.completionLabel?.text = "In Progress"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-filled")
                }
            }
            if !game.finished {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-empty-black"), for: .normal)
                self.finishedButtonState = .normal
                if self.playButtonState != .selected {
                    self.completionLabel?.text = "Incomplete"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-empty")
                } else {
                    self.completionLabel?.text = "In Progress"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-filled")
                }
            } else {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-black"), for: .normal)
                self.finishedButtonState = .selected
                self.completionLabel?.text = "Complete"
                self.completionImageView?.image = #imageLiteral(resourceName: "check")
            }
            self.firstStar?.image  = #imageLiteral(resourceName: "star-white")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            switch (game.rating) {
            case 0:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-white")
                self.secondStar?.image = #imageLiteral(resourceName: "star-white")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
                self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
                self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
                break
            case 1:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
                break
            case 2:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
                self.secondStar?.image = #imageLiteral(resourceName: "star-black")
                break
            case 3:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
                self.secondStar?.image = #imageLiteral(resourceName: "star-black")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
                break
            case 4:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
                self.secondStar?.image = #imageLiteral(resourceName: "star-black")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
                self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
                break
            case 5:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
                self.secondStar?.image = #imageLiteral(resourceName: "star-black")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
                self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
                self.fifthStar?.image  = #imageLiteral(resourceName: "star-black")
                break
            default:
                break
            }
            self.progressSlider?.value = Float((self._game?.progress)!)
            self.percentageLabel?.text = "\((self._game?.progress)!)%"
            self.notesTextView?.text = self._game?.notes
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.detailsScrollView?.scrollIndicatorInsets = UIEdgeInsets(top: (self.headerView?.bounds.height)! + 25.0 + (self.navigationController?.navigationBar.bounds.height ?? -20.0), left: 0, bottom: self.tabBarController?.tabBar.bounds.height ?? 0.0, right: 0)
        self.detailsScrollView?.contentInset = UIEdgeInsets(top: (self.headerView?.bounds.height)! + 25.0 + (self.navigationController?.navigationBar.bounds.height ?? -20.0), left: 0.0, bottom: self.tabBarController?.tabBar.bounds.height ?? 0.0, right: 0.0)
        
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        bottomBorder.frame = CGRect(x:0, y:(self.headerView?.frame.size.height)! - 0.5, width: (self.headerView?.frame.size.width)!, height: 0.5)
        self.headerView?.layer.addSublayer(bottomBorder)
    }
    override var previewActionItems: [UIPreviewActionItem] {
        if self._state != .inLibrary {
            return [UIPreviewAction(title: "Add", style: .default, handler: {[unowned self] (_, _) -> Void in
            })]
        } else {
            return []
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
        if self.isMovingFromParentViewController {
            self.delegate?.gamesCreated(gameField: self._gameField!)
        }
    }
    
    private func updateGameDetails() {
        self.imageCollectionView?.reloadData()
        let gameFields = self._gameField
        if let images = gameFields?.images {
            if images.count == 0 {
                self.imagesTitleLabel?.isHidden = true
                self.imageCollectionView?.isHidden = true
                self.informationTopConstraint?.isActive = false
                self.informationTopConstraint = NSLayoutConstraint(item: self.informationTitleLabel!, attribute: .top, relatedBy: .equal, toItem: self.descriptionView!, attribute: .bottom, multiplier: 1.0, constant: 5.0)
                self.informationTopConstraint?.isActive = true
            }
        } else {
            self.imagesTitleLabel?.isHidden = true
            self.imageCollectionView?.isHidden = true
            self.informationTopConstraint?.isActive = false
            self.informationTitleLabel?.removeConstraint(self.informationTopConstraint!)
            self.informationTopConstraint = NSLayoutConstraint(item: self.informationTitleLabel!, attribute: .top, relatedBy: .equal, toItem: self.descriptionView!, attribute: .bottom, multiplier: 1.0, constant: 5.0)
            self.informationTopConstraint?.isActive = true
        }
        var platformString = ""
        if let platforms = gameFields?.platforms {
            if platforms.count > 0 {
                if platforms.count > 1 {
                    for platform in platforms[0..<platforms.endIndex - 1] {
                        if platform.name!.characters.count < 10 {
                            platformString += platform.name! + ", "
                        } else {
                            platformString += platform.abbreviation! + ", "
                        }
                    }
                }
                if platforms[platforms.endIndex - 1].name!.characters.count < 10 {
                    platformString += (platforms.last?.name)!
                } else {
                    platformString += (platforms.last?.abbreviation)!
                }
            }
        }
        if platformString == "" {
            platformString = "N/A"
        }
        self.platformsLabel?.text = platformString
        
        var developersString = ""
        if let developers = gameFields?.developers {
            if developers.count > 0 {
                if developers.count > 1 {
                    for developer in developers[0..<developers.endIndex - 1] {
                        developersString += developer.name! + ", "
                    }
                }
                developersString += (developers.last?.name)!
            }
        }
        if developersString == "" {
            developersString = "N/A"
        }
        self.developerLabel?.text = developersString
        
        var publishersString = ""
        if let publishers = gameFields?.publishers {
            if publishers.count > 0 {
                if publishers.count > 1 {
                    for publisher in publishers[0..<publishers.endIndex - 1] {
                        publishersString += publisher.name! + ", "
                    }
                }
                publishersString += (publishers.last?.name)!
            }
        }
        if publishersString == "" {
            publishersString = "N/A"
        }
        self.publisherLabel?.text = publishersString
        
        var genresString = ""
        if let genres = gameFields?.genres {
            if genres.count > 0 {
                if genres.count > 1 {
                    for genre in genres[0..<genres.endIndex - 1] {
                        genresString += genre.name! + ", "
                    }
                }
                genresString += (genres.last?.name)!
            }
        }
        if genresString == "" {
            genresString = "N/A"
        }
        self.genresLabel?.text = genresString
        
        self.activityIndicator?.stopAnimating()
        self.activityBackground?.isHidden = true
        self.detailsScrollView?.isHidden = false
    }

    func textViewDidChange(_ textView: UITextView) {
        self._game?.update {
            self._game?.notes = textView.text
        }
    }

    @IBAction func addTapped(sender: UITapGestureRecognizer?) {
        if self.state == .addToLibrary {
            let consoleSelection = ConsoleSelectionTableViewController()
            consoleSelection.delegate = self
            consoleSelection.gameField = self._gameField
            self.navigationController?.pushViewController(consoleSelection, animated: true)
        } else {
            var gameFieldCopy: GameField?
            let endIndex = (self._gameField?.ownedGames.endIndex)!
            // All links are broken at this point
            for (i, game) in (self._gameField?.ownedGames.enumerated())! {
                if (i == endIndex - 1) {
                    gameFieldCopy = game.deleteWithGameFieldCopy()
                } else {
                    game.delete()
                }
            }

            UIView.setAnimationsEnabled(false)
            self.platformButton?.setTitle("", for: .normal)
            UIView.setAnimationsEnabled(true)
            self.platformButton?.isEnabled = false
            self._gameField = gameFieldCopy
            self.transitionToAdd()
        }
    }
    
    @IBAction func platformsTapped(sender: UIButton!) {
        let consoleSelection = ConsoleSelectionTableViewController()
        consoleSelection.delegate = self
        consoleSelection.gameField = self._gameField
        self.navigationController?.pushViewController(consoleSelection, animated: true)
    }
    
    private func transitionToRemove() {
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "checkmark"), text: "Added to Library")
        self.state = .inLibrary
        if game != nil || self._gameField?.ownedGames.count == 1 {
            self.addLabel?.text = "REMOVE"
        } else {
            self.addLabel?.text = "REMOVE ALL"
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.addSymbolImage?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4.0)
            self.addBackground?.backgroundColor = .red
            if self._gameField?.ownedGames.count == 1 {
                self.statsButton?.alpha = 1.0
            }
            self.progressIcon?.alpha = 1.0
            self.view.layoutIfNeeded()
        })
    }
    
    private func transitionToAdd() {
        self.state = .addToLibrary
        self.addLabel?.text = "ADD"
        UIView.animate(withDuration: 0.2, animations: {
            self.addSymbolImage?.transform = CGAffineTransform(rotationAngle: 0.0)
            self.addBackground?.backgroundColor = Util.appColor
            self.statsButton?.alpha = 0.0
            self.progressIcon?.alpha = 0.0
            self.view.layoutIfNeeded()
        })
        if self.statsState == .visible {
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.statsButton?.backgroundColor = Util.appColor
                            self.statsLabel?.textColor = .white
                            self.statsScrollView?.alpha = 0.0
                            self.statsEffectView?.effect = nil
            },
                           completion: { _ in
                            self.statsEffectView?.isHidden = true
            })
            self.statsState = .hidden
        }
    }
    
    private func showStatsButton() {
        UIView.animate(withDuration: 0.2, animations: {
            self.statsButton?.alpha = 1.0
        })
    }
    
    private func hideStatsButton() {
        UIView.animate(withDuration: 0.2, animations: {
            self.statsButton?.alpha = 0.0
        })
    }
    
    @IBAction func moreTapped(sender: UITapGestureRecognizer) {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actions.addAction(UIAlertAction(title: "Add to...", style: .default, handler: nil))
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)

    }
    
    @IBAction func statsTapped(sender: UITapGestureRecognizer) {
        if self.statsState == .hidden {
            self.statsEffectView?.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.statsButton?.backgroundColor = .white
                self.statsLabel?.textColor = Util.appColor
                self.statsScrollView?.alpha = 1.0
                self.statsEffectView?.effect = UIBlurEffect(style: .extraLight)
            })
            self.statsState = .visible
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.statsButton?.backgroundColor = Util.appColor
                self.statsLabel?.textColor = .white
                self.statsScrollView?.alpha = 0.0
                self.statsEffectView?.effect = nil
            }, completion: { _ in
                self.statsEffectView?.isHidden = true
            })
            self.statsState = .hidden
        }
    }
    
    @IBAction func artTapped(sender: UITapGestureRecognizer) {
        if self.state != .addToLibrary {
            if self.artViewProgressState == .hidden {
                self.showPercentage()
                self.percentTimer?.invalidate()
                self.percentTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(hidePercentage), userInfo: nil, repeats: false)
            } else {
                self.hidePercentage()
            }
        }
        self.notesTextView?.resignFirstResponder()
    }
    
    @IBAction func statsControlTouchDown(sender: UIButton!) {
        if self.buttonState == .up {
            self.buttonState = .down
        } else if self.buttonState == .down {
            self.buttonState = .heldDown
            UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)})
        }
    }
    
    @IBAction func statsControlTouchUpInside(sender: UIButton!) {
        switch sender.tag {
        case 1:
            if self.favouriteButtonState == .selected {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart-empty"), for: .normal)
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
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "play-black"), for: .normal)
                self.playButtonState = .normal
                if self.finishedButtonState != .selected {
                    self.completionLabel?.text = "Incomplete"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-empty")
                }
                self._game?.update {
                    self._game?.nowPlaying = false
                }
            } else {
                self.playPauseButton?.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                self.playButtonState = .selected
                if self.finishedButtonState != .selected {
                    self.completionLabel?.text = "In Progress"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-filled")
                }
                self._game?.update {
                    self._game?.nowPlaying = true
                }
            }
        case 3:
            if self.finishedButtonState == .selected {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-empty-black"), for: .normal)
                self.finishedButtonState = .normal
                if self.playButtonState != .selected {
                    self.completionLabel?.text = "Incomplete"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-empty")
                } else {
                    self.completionLabel?.text = "In Progress"
                    self.completionImageView?.image = #imageLiteral(resourceName: "check-filled")
                }
                self._game?.update {
                    self._game?.finished = false
                }
            } else {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-black"), for: .normal)
                self.finishedButtonState = .selected
                self.completionLabel?.text = "Complete"
                self.completionImageView?.image = #imageLiteral(resourceName: "check")
                self._game?.update {
                    self._game?.finished = true
                }
            }
        default:
            break
        }

        UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)}, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform.identity})
        })
        self.buttonState = .up
        self.notesTextView?.resignFirstResponder()
    }
    
    @IBAction func statsControlTouchDragExit(sender: UIButton!) {
        self.buttonState = .up
        UIView.animate(withDuration: 0.1, animations: {sender.transform = CGAffineTransform.identity})
        self.notesTextView?.resignFirstResponder()
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
        self.percentageLabel?.text = "\(newValue)%"
        if self.artViewProgressState == .hidden {
            self.showPercentage()
            self.percentTimer?.invalidate()
            self.percentTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(hidePercentage), userInfo: nil, repeats: false)
        } else {
            self.percentTimer?.invalidate()
            self.percentTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(hidePercentage), userInfo: nil, repeats: false)
        }
        self._game?.update {
            self._game?.progress = newValue
        }
        self.notesTextView?.resignFirstResponder()
    }
    
    private func showPercentage() {
        UIView.animate(withDuration: 0.2, animations: {
            self.percentageBlurView?.effect = UIBlurEffect(style: .dark)
            self.percentageVibrancyView?.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
            self.percentageLabel?.alpha = 1.0
        })
        self.artViewProgressState = .visible
    }
    
    @objc private func hidePercentage() {
        UIView.animate(withDuration: 0.2, animations: {
            self.percentageBlurView?.effect = nil
            self.percentageVibrancyView?.effect = nil
            self.percentageLabel?.alpha = 0.0
        }, completion: { _ in
            //self.percentageBlurView?.isHidden = true
        })
        self.percentTimer?.invalidate()
        artViewProgressState = .hidden
    }
    
    @IBAction func ratingPanHandler(sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self.ratingContainerView!)
        let starIndex = Int(location.x / ((self.ratingContainerView?.bounds.width)! / 5.0))
        var rating = 0
        if starIndex < 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-white")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 1
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 2
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 3
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 4
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-black")
            rating = 5
        }
        self._game?.update {
            self._game?.rating = rating
        }
        self.notesTextView?.resignFirstResponder()
    }
    
    @IBAction func ratingTapHandler(sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.ratingContainerView!)
        let starIndex = Int(location.x / ((self.ratingContainerView?.bounds.width)! / 5.0))

        var rating = 0
        if starIndex <= 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 1
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 2
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 3
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
            rating = 4
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-black")
            rating = 5
        }
        self._game?.update {
            self._game?.rating = rating
        }
        self.notesTextView?.resignFirstResponder()
    }
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= (keyboardSize.height - (self.tabBarController?.tabBar.frame.height)!)
            }
        }
        self.doneButton?.isEnabled = true
        UIView.animate(withDuration: 0.2, animations: {self.doneButton?.title = "Done"})
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height - (self.tabBarController?.tabBar.frame.height)!
            }
        }
        self.doneButton?.isEnabled = false
        UIView.animate(withDuration: 0.2, animations: {self.doneButton?.title = " "})
    }
    
    @IBAction func handleTapDone() {
        self.notesTextView?.resignFirstResponder()
    }
    
    func didSelectConsoles(_ consoles: [Platform]) {
        self._selectedPlatforms = consoles
        var currentPlatformList: [Platform] = [Platform]()
        var newGameList = [Game]()
        var gameField = self._gameField?.deepCopy()
        
        if consoles.count > 0 {
            for game in (self._gameField?.ownedGames)! {
                if !consoles.contains(game.platform!) {
                    game.delete()
                } else {
                    newGameList.append(game)
                    currentPlatformList.append(game.platform!)
                }
            }

            var platformString = ""

            if consoles.count > 1 {
                for platform in consoles[0..<consoles.endIndex - 1] {

                    if !currentPlatformList.contains(platform) {
                        let newGameToSave = Game()
                        newGameToSave.inLibrary = true
                        newGameToSave.add(gameField, platform)
                        newGameList.append(newGameToSave)
                    }
                    if (platform.name?.characters.count)! < 10 {
                        platformString += platform.name! + " • "
                    } else {
                        platformString += platform.abbreviation! + " • "
                    }
                }
            }
            let platform = consoles[consoles.endIndex - 1]
            
            if !currentPlatformList.contains(platform) {
                let newGameToSave = Game()
                newGameToSave.inLibrary = true
                newGameToSave.add(gameField, platform)
                newGameList.append(newGameToSave)
            }
            if (platform.name?.characters.count)! < 10 {
                platformString += platform.name!
            } else {
                platformString += platform.abbreviation!
            }
            UIView.setAnimationsEnabled(false)
            self.platformButton?.setTitle(platformString, for: .normal)
            UIView.setAnimationsEnabled(true)
            self.platformButton?.isEnabled = true
            
            autoreleasepool {
                let realm = try? Realm()
                self._gameField = realm?.object(ofType: GameField.self, forPrimaryKey: (gameField?.idNumber)!) // get updated link
            }
            
            if self._state == .addToLibrary {
                self.transitionToRemove()
                if consoles.count == 1 {
                    self.showStatsButton()
                }
            } else {
                self.transitionToRemove()
                if consoles.count > 1 {
                    self.hideStatsButton()
                } else {
                    self.showStatsButton()
                }
            }
        } else {
            for (index, game) in (self._gameField?.ownedGames.enumerated())! {
                if index == ((self._gameField?.ownedGames.count)! - 1) {
                    gameField = game.deleteWithGameFieldCopy()
                } else {
                    game.delete()
                }
            }
            self._gameField = gameField
            UIView.setAnimationsEnabled(false)
            self.platformButton?.setTitle("", for: .normal)
            UIView.setAnimationsEnabled(true)
            self.platformButton?.isEnabled = false
            self.transitionToAdd()
        }
    }
}

extension GameDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gameField?.images.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = (self.imageCollectionView?.frame.size)!
        size.width = size.height
        return size
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        self.imageCollectionView?.register(UINib(nibName: "ImageCell", bundle: Bundle.main), forCellWithReuseIdentifier: imageCellReuseIdentifier)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageCellReuseIdentifier, for: indexPath)
        let cellView = UIView()
        cellView.backgroundColor = .lightGray
        cellView.clipsToBounds = true
        cellView.layer.cornerRadius = 5.0
        cell.clipsToBounds = false
        cellView.translatesAutoresizingMaskIntoConstraints = false
        
        cell.contentView.addSubview(cellView)
        NSLayoutConstraint(item: cellView,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .leading,
                           multiplier: 1.0,
                           constant: 5.0
            ).isActive = true
        NSLayoutConstraint(item: cellView,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .trailing,
                           multiplier: 1.0,
                           constant: -5.0
            ).isActive = true
        NSLayoutConstraint(item: cellView,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .top,
                           multiplier: 1.0,
                           constant: 5.0
            ).isActive = true
        NSLayoutConstraint(item: cellView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: -5.0
            ).isActive = true
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 5.0
        imageView.clipsToBounds = true
        
        cellView.addSubview(imageView)
        NSLayoutConstraint(item: imageView,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: cellView,
                           attribute: .leading,
                           multiplier: 1.0,
                           constant: 0.5
            ).isActive = true
        NSLayoutConstraint(item: imageView,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: cellView,
                           attribute: .trailing,
                           multiplier: 1.0,
                           constant: -0.5
            ).isActive = true
        NSLayoutConstraint(item: imageView,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: cellView,
                           attribute: .top,
                           multiplier: 1.0,
                           constant: 0.5
            ).isActive = true
        NSLayoutConstraint(item: imageView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: cellView,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: -0.5
            ).isActive = true
        if let mediumUrl = self.gameField?.images[indexPath.item].mediumUrl {
            imageView.kf.setImage(with: URL(string: mediumUrl), placeholder: #imageLiteral(resourceName: "info_image_placeholder"), completionHandler: {
                (image, error, cacheType, imageUrl) in
                if image != nil {
                    UIView.transition(with: imageView,
                                      duration:0.5,
                                      options: .transitionCrossDissolve,
                                      animations: { imageView.image = image },
                                      completion: nil)
                }
            })
        } else {
            imageView.image = #imageLiteral(resourceName: "info_image_placeholder")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
