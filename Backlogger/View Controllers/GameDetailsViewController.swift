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
import ImageViewer

extension UIImageView : DisplaceableView {}

protocol GameDetailsViewControllerDelegate {
    func gamesCreated(gameField: GameField)
}

class GameDetailsViewController: UIViewController, ConsoleSelectionTableViewControllerDelegate, UITextViewDelegate, PlaylistViewControllerDelegate {
    @IBOutlet weak var mainImageView:            UIImageView?
    @IBOutlet weak var titleLabel:               UILabel?
    @IBOutlet weak var yearLabel:                UILabel?
    @IBOutlet weak var platformButton:           UIButton?
    @IBOutlet weak var headerView:               UIVisualEffectView?
    @IBOutlet weak var headerContent:            UIView?
    @IBOutlet weak var shadowView:               UIView?
    @IBOutlet weak var detailsScrollView:        UIScrollView?
    @IBOutlet weak var detailsContentView:       UIView?
    @IBOutlet weak var descriptionView:          UILabel?
    @IBOutlet weak var imagesTitleLabel:         UILabel?
    @IBOutlet weak var imageCollectionView:      UICollectionView?
    @IBOutlet weak var informationTitleLabel:    UILabel?
    @IBOutlet weak var publisherLabel:           UILabel?
    @IBOutlet weak var developerLabel:           UILabel?
    @IBOutlet weak var platformsLabel:           UILabel?
    @IBOutlet weak var genresLabel:              UILabel?
    @IBOutlet weak var activityIndicator:        UIActivityIndicatorView?
    @IBOutlet weak var activityBackground:       UIView?
    @IBOutlet weak var addSymbolImage:           UIImageView?
    @IBOutlet weak var addLabel:                 UILabel?
    @IBOutlet weak var addBackground:            UIView?
    @IBOutlet weak var statsButton:              UIView?
    @IBOutlet weak var progressIcon:             UIView?
    @IBOutlet weak var statsEffectView:          UIVisualEffectView?
    @IBOutlet weak var statsScrollView:          UIScrollView?
    @IBOutlet weak var statsLabel:               UILabel?
    @IBOutlet weak var percentageBlurView:       UIVisualEffectView?
    @IBOutlet weak var percentageVibrancyView:   UIVisualEffectView?
    @IBOutlet weak var percentageLabel:          UILabel?
    @IBOutlet weak var playPauseButton:          UIButton?
    @IBOutlet weak var favouriteButton:          UIButton?
    @IBOutlet weak var finishedButton:           UIButton?
    @IBOutlet weak var completionLabel:          UILabel?
    @IBOutlet weak var completionImageView:      UIImageView?
    @IBOutlet weak var ratingContainerView:      UIView?
    @IBOutlet weak var notesTextView:            UITextView?
    @IBOutlet weak var progressSlider:           UISlider?
    @IBOutlet weak var moreButton:               UIView?
    @IBOutlet weak var charactersCollectionView: UICollectionView?
    @IBOutlet weak var charactersTitleLabel:     UILabel?

    @IBOutlet weak var firstStar:  UIImageView?
    @IBOutlet weak var secondStar: UIImageView?
    @IBOutlet weak var thirdStar:  UIImageView?
    @IBOutlet weak var fourthStar: UIImageView?
    @IBOutlet weak var fifthStar:  UIImageView?
    
    @IBOutlet weak var doneButton: UIBarButtonItem?
    
    @IBOutlet weak var steamLogo:      UIImageView?
    @IBOutlet weak var steamUserLabel: UILabel?
    
    @IBOutlet weak var networkConnectionLabel: UILabel?
    
    var characterImageViews: [UIImageView] = []
    let queue = DispatchQueue(label: "character.loading.queue")
    
    var toastOverlay = ToastOverlayViewController()
    
    @IBOutlet weak var informationTopConstraint:         NSLayoutConstraint?
    @IBOutlet weak var statsLeadingToLeadingConstraint:  NSLayoutConstraint?
    @IBOutlet weak var statsLeadingToTrailingConstraint: NSLayoutConstraint?
    @IBOutlet weak var headingTopConstraint:             NSLayoutConstraint?
    @IBOutlet weak var bottomConstraint:                 NSLayoutConstraint?
    @IBOutlet weak var headerHeightConstraint:           NSLayoutConstraint?
    @IBOutlet weak var shadowLeadingConstraint:          NSLayoutConstraint?
    @IBOutlet weak var shadowTopConstraint:              NSLayoutConstraint?
    @IBOutlet weak var shadowBottomConstraint:           NSLayoutConstraint?
    @IBOutlet weak var platformTopConstraint:            NSLayoutConstraint?
    
    let maximumShadowSpacing: CGFloat = 10.0
    let minimumShadowSpacing: CGFloat = 5.0
    
    let maximumShadowBottom: CGFloat = 25.0
    let minimumShadowBottom: CGFloat = 5.0
    
    let minimumHeaderHeight: CGFloat = 55.0
    let maximumHeaderHeight: CGFloat = (UIDevice().type == .iPhone5  ||
                                        UIDevice().type == .iPhone5S ||
                                        UIDevice().type == .iPhone5C ||
                                        UIDevice().type == .iPhoneSE ||
                                        UIScreen.main.bounds.width == 320.0) ?
                                        123.0 : 175.0
    
    var peekHeadingTopConstraint: NSLayoutConstraint?
    
    struct DataItem {
        let imageView: UIImageView
        var galleryItem: GalleryItem
    }
    
    var images: [Int: DataItem] = [:]
    
    let imageCellReuseIdentifier = "image_cell"
    let characterCellReuseIdentifier = "character_cell"

    let headerBorder = CALayer()
    
    private var _selectedPlatforms = [Platform]()
    
    private var _state: State?
    
    private var _gameField: GameField?
    
    private var _game: Game?
    
    var gameFieldId: Int?
    
    var delegate: GameDetailsViewControllerDelegate?
    
    var showAddButton = true
    var hideStats = false
    
    var isAddingToPlaylist  = false
    var isAddingToPlayNext  = false
    var isAddingToPlayLater = false
    var isExiting = false
    
    var addRemoveClosure:      ((UIPreviewAction, UIViewController) -> Void)?
    var addToPlaylistClosure:  ((UIPreviewAction, UIViewController) -> Void)?
    var addToPlayNextClosure:  ((UIPreviewAction, UIViewController) -> Void)?
    var addToPlayLaterClosure: ((UIPreviewAction, UIViewController) -> Void)?
    
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
        let screenSize = UIScreen.main.bounds
        NSLog("\(screenSize.width)x\(screenSize.height)")
        let setGameField = self._gameField?.deepCopy()
        if UIScreen.main.bounds.width == 320.0 {
            self.titleLabel?.numberOfLines = 2
            self.yearLabel?.isHidden = true
        }
        autoreleasepool {
            let realm = try? Realm()
            if let gameFieldId = self.gameFieldId {
                self._gameField = realm?.object(ofType: GameField.self, forPrimaryKey: gameFieldId)
                if self._gameField == nil && setGameField != nil{
                    self._gameField = setGameField
                }
            }
        }
        if self._game == nil {
            if self._gameField!.ownedGames.count > 0 {
                self._state = .partialAddToLibrary
            } else {
                self._state = .addToLibrary
            }
        } else {
            self._state = .inLibrary
            if self._game!.platform!.idNumber == Steam.steamPlatformIdNumber {
                let username = UserDefaults.standard.value(forKey: "steamName") as! String
                self.steamUserLabel?.text = username
                self.steamUserLabel?.isHidden = false
                self.steamLogo?.isHidden = false
            }
        }
        
        self.addBackground?.isHidden = !self.showAddButton

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
        if !(gameFields?.hasDetails)! && Util.isInternetAvailable() {
            gameFields?.updateGameDetails { result in
                if let error = result.error {
                    NSLog("error: \(error.localizedDescription)")
                    self.networkConnectionLabel?.isHidden = false
                    self.activityBackground?.isHidden = true
                    self.activityIndicator?.stopAnimating()
                    return
                }
                if gameFields!.characters.count > 0 {
                    for character in gameFields!.characters {
                        if !character.hasImage {
                            let characterId = character.idNumber
                            self.queue.async {
                                if !self.isExiting {
                                    character.updateDetails(id: characterId) { result in
                                        if let error = result.error {
                                            NSLog("error: \(error.localizedDescription)")
                                            return
                                        }
                                        if !self.isExiting {
                                            character.updateDetailsFromJson(json: result.value! as! [String: Any], fromDb: true)
                                            self.charactersCollectionView?.reloadData()
                                        }
                                    }
                                }
                            }
                        } else {
                            self.charactersCollectionView?.reloadData()
                            self.updateGameDetails()
                        }
                    }
                } else {
                    self.charactersCollectionView?.isHidden = true
                    self.charactersTitleLabel?.isHidden = true
                    self.bottomConstraint?.isActive = false
                    NSLayoutConstraint(item: self.detailsContentView!, attribute: .bottom, relatedBy: .equal, toItem: self.genresLabel, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
                }
                self.updateGameDetails()
            }
        } else if !Util.isInternetAvailable() {
            self.networkConnectionLabel?.isHidden = false
            self.activityBackground?.isHidden = true
            self.activityIndicator?.stopAnimating()
        } else {
            if gameFields!.characters.count > 0 {
                for character in gameFields!.characters {
                    if !character.hasImage {
                        let characterId = character.idNumber
                        self.queue.async {
                            if !self.isExiting {
                                character.updateDetails(id: characterId) { result in
                                    if let error = result.error {
                                        NSLog("error: \(error.localizedDescription)")
                                        return
                                    }
                                    if !self.isExiting {
                                        character.updateDetailsFromJson(json: result.value! as! [String: Any], fromDb: true)
                                        self.charactersCollectionView?.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.charactersCollectionView?.isHidden = true
                self.charactersTitleLabel?.isHidden = true
                self.bottomConstraint?.isActive = false
                NSLayoutConstraint(item: self.detailsContentView!, attribute: .bottom, relatedBy: .equal, toItem: self.genresLabel, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
            }
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
                           constant: 300.0
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
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-green"), for: .normal)
                self.finishedButtonState = .selected
                self.completionLabel?.text = "Complete"
                self.completionImageView?.image = #imageLiteral(resourceName: "check")
            }
            self.firstStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            switch (game.rating) {
            case 0:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-empty-black")
                self.secondStar?.image = #imageLiteral(resourceName: "star-empty-black")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-empty-black")
                self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
                self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
                break
            case 1:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
                break
            case 2:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
                self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
                break
            case 3:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
                self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
                break
            case 4:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
                self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
                self.fourthStar?.image = #imageLiteral(resourceName: "star-yellow")
                break
            case 5:
                self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
                self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
                self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
                self.fourthStar?.image = #imageLiteral(resourceName: "star-yellow")
                self.fifthStar?.image  = #imageLiteral(resourceName: "star-yellow")
                break
            default:
                break
            }
            self.progressSlider?.value = Float((self._game?.progress)!)
            self.percentageLabel?.text = "\((self._game?.progress)!)%"
            self.notesTextView?.text = self._game?.notes
        }
        
        self.imageCollectionView?.register(UINib(nibName: "ImageCell", bundle: Bundle.main), forCellWithReuseIdentifier: self.imageCellReuseIdentifier)
        self.charactersCollectionView?.register(UINib(nibName: "CharacterCell", bundle: Bundle.main), forCellWithReuseIdentifier: self.characterCellReuseIdentifier)
    }
    
    override func viewDidLayoutSubviews() {
        self.detailsScrollView?.scrollIndicatorInsets = UIEdgeInsets(top: self.maximumHeaderHeight + 20.0 + (self.navigationController?.navigationBar.bounds.height ?? -20.0), left: 0, bottom: self.tabBarController?.tabBar.bounds.height ?? 0.0, right: 0)
        self.detailsScrollView?.contentInset = UIEdgeInsets(top: self.maximumHeaderHeight + 25.0 + (self.navigationController?.navigationBar.bounds.height ?? -20.0), left: 0.0, bottom: self.tabBarController?.tabBar.bounds.height ?? 0.0, right: 0.0)

        self.statsLeadingToTrailingConstraint?.isActive = !self.hideStats
        self.statsLeadingToLeadingConstraint?.isActive = self.hideStats
        self.statsButton?.isHidden = self.hideStats
        
        if UIScreen.main.bounds.width == 320.0 {
            self.platformTopConstraint?.constant = -20.5
        }
    }
    override var previewActionItems: [UIPreviewActionItem] {
        var addString: String
        var style: UIPreviewActionStyle
        switch self._state! {
        case .addToLibrary:
            addString = "Add"
            style = .default
            break
        case .partialAddToLibrary:
            addString = "Add More..."
            style = .default
            break
        case .inLibrary:
            addString = "Remove From Library"
            style = .destructive
            break
        }
        let addRemove = UIPreviewAction(title: addString, style: style, handler: self.addRemoveClosure!)
        if style == .destructive {
            addRemove.setValue(#imageLiteral(resourceName: "trash_red"), forKey: "image")
        } else {
            //addRemove.setValue(#imageLiteral(resourceName: "add_symbol_blue"), forKey: "image")
        }
        let addToPlaylist = UIPreviewAction(title: "Add to Playlist...", style: .default, handler: self.addToPlaylistClosure!)
        addToPlaylist.setValue(#imageLiteral(resourceName: "add_to_playlist"), forKey: "image")
        let playNext = UIPreviewAction(title: "Play Next", style: .default, handler: self.addToPlayNextClosure!)
        playNext.setValue(#imageLiteral(resourceName: "play_next"), forKey: "image")
        let playLater = UIPreviewAction(title: "Play Later", style: .default, handler: self.addToPlayLaterClosure!)
        playLater.setValue(#imageLiteral(resourceName: "add_to_queue"), forKey: "image")
        if let game = self._game {
            for playlist in game.linkedPlaylists {
                if playlist.isUpNext || playlist.isNowPlaying {
                    return [addRemove, addToPlaylist]
                }
            }
        }
        return [addRemove, addToPlaylist, playNext, playLater]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        if !self.showAddButton && self._game!.isInvalidated {
            self.navigationController?.popViewController(animated: false)
        }
        if self.navigationController == nil {
            self.headingTopConstraint?.isActive = false
            self.peekHeadingTopConstraint = NSLayoutConstraint(item: self.headerView!, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0.0)
            self.peekHeadingTopConstraint?.isActive = true
        } else {
            self.peekHeadingTopConstraint?.isActive = false
            self.headingTopConstraint = NSLayoutConstraint(item: self.headerView!, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
            self.headingTopConstraint?.isActive = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        if self.isMovingFromParentViewController {
            self.isExiting = true
            self.delegate?.gamesCreated(gameField: self._gameField!)
        }
    }
    
    private func updateGameDetails() {
        self.charactersCollectionView?.reloadData()
        // Download all images at once
        var gameField: GameField
        if self._game == nil {
            gameField = self._gameField!
        } else {
            gameField = self._game!.gameFields!
        }
        for (i, image) in gameField.images.enumerated() {
            let imageView = UIImageView()
            var newUrl: String
            if let url = image.superUrl {
                newUrl = url
            } else if let url = image.mediumUrl {
                newUrl = url
            } else if let url = image.screenUrl {
                newUrl = url
            } else {
                newUrl = ""
                imageView.image = #imageLiteral(resourceName: "info_image_placeholder")
            }
            let image = imageView.image ?? UIImage()
            let galleryItem = GalleryItem.image { $0(image) }
            let item: DataItem = DataItem(imageView: imageView, galleryItem: galleryItem)
            self.images[i] = item
            if imageView.image == nil {
                imageView.kf.setImage(with: URL(string: newUrl), placeholder: #imageLiteral(resourceName: "info_image_placeholder"), completionHandler: {
                    (image, error, cacheType, imageUrl) in
                    if image != nil {
                        if cacheType == .none {
                            UIView.transition(with: imageView,
                                              duration:0.5,
                                              options: .transitionCrossDissolve,
                                              animations: { imageView.image = image },
                                              completion: nil)
                        } else {
                            imageView.image = image
                        }
                        self.images[i]?.galleryItem = GalleryItem.image { $0(image) }
                    }
                })
            }
        }
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
        if self.state == .addToLibrary || self.isAddingToPlayLater || self.isAddingToPlayNext || self.isAddingToPlaylist {
            let consoleSelection = ConsoleSelectionTableViewController(style: .grouped)
            consoleSelection.delegate = self
            consoleSelection.gameField = self._gameField
            if self.isAddingToPlayLater || self.isAddingToPlayNext || self.isAddingToPlaylist {
                consoleSelection.playlist = true
            }
            self.navigationController?.pushViewController(consoleSelection, animated: true)
        } else {
            if self._game != nil {
                self._game?.delete()
                self.navigationController?.popViewController(animated: true)
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
    }
    
    @IBAction func platformsTapped(sender: UIButton!) {
        let consoleSelection = ConsoleSelectionTableViewController(style: .grouped)
        consoleSelection.delegate = self
        consoleSelection.gameField = self._gameField
        self.navigationController?.pushViewController(consoleSelection, animated: true)
    }
    
    private func transitionToRemove() {
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "checkmark"), title: "Added to Library", description: nil)
        self.state = .partialAddToLibrary
        if self._gameField?.ownedGames.count == 1 || (self._gameField == nil && self._game != nil) {
            self.addLabel?.text = "REMOVE"
        } else {
            self.addLabel?.text = "REMOVE ALL"
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.addSymbolImage?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4.0)
            self.addBackground?.backgroundColor = .red
            if self._gameField?.ownedGames.count == 1 {
                self.statsButton?.alpha = 1.0
            } else {
                self.statsButton?.alpha = 0.0
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
        let addAction = UIAlertAction(title: "Add to Playlist", style: .default, handler: self.handleAddToPlaylist)
        let playNextAction = UIAlertAction(title: "Play Next", style: .default, handler: self.handlePlayNext)
        let queueAction = UIAlertAction(title: "Play Later", style: .default, handler: self.handlePlayLater)
        addAction.setValue(#imageLiteral(resourceName: "add_to_playlist"), forKey: "image")
        playNextAction.setValue(#imageLiteral(resourceName: "play_next"), forKey: "image")
        queueAction.setValue(#imageLiteral(resourceName: "add_to_queue"), forKey: "image")
        var inNowPlaying = false
        
        if let game = self._game {
            for playlist in game.linkedPlaylists {
                if playlist.isUpNext || playlist.isNowPlaying {
                    inNowPlaying = true
                    break
                }
            }
        }
        
        actions.addAction(addAction)
        if !inNowPlaying {
            actions.addAction(playNextAction)
            actions.addAction(queueAction)
        }
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actions.popoverPresentationController?.sourceView = self.moreButton
        actions.popoverPresentationController?.sourceRect = self.moreButton!.bounds

        self.present(actions, animated: true, completion: nil)

    }
    
    func chosePlaylist(vc: PlaylistViewController, playlist: Playlist, games: [Game], isNew: Bool) {
        if !isNew {
            playlist.update {
                playlist.games.append(contentsOf: games)
            }
        }
        vc.presentingViewController?.dismiss(animated: true, completion: {
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_playlist_large"), title: "Added to Playlist", description: "Added to \"\(playlist.name!)\".")
        })
        vc.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func handleAddToPlaylist(sender: UIAlertAction) {
        self.isAddingToPlaylist = true
        if self._state! == .addToLibrary {
            self.addTapped(sender: nil)
        } else if self._state! == .inLibrary {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistNavigation") as! UINavigationController
            let playlistVc = vc.viewControllers.first as! PlaylistViewController
            playlistVc.addingGames = [self._game!]
            playlistVc.isAddingGames = true
            playlistVc.delegate = self
            self.present(vc, animated: true, completion: nil)
        } else {
            self.addTapped(sender: nil)
        }
    }
    
    func handlePlayNext(sender: UIAlertAction) {
        self.isAddingToPlayNext = true
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "play_next_large"), title: "Added to Queue", description: "We'll play this one next.")
        if self._state! != .inLibrary {
            self.addTapped(sender: nil)
        } else {
            self.addToUpNext(games: [self._game!], later: false)
        }
    }
    
    func addToUpNext(games: [Game], later: Bool) {
        if later {
            autoreleasepool {
                let realm = try! Realm()
                let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
                if upNextPlaylist != nil {
                    var currentGames = Array(upNextPlaylist!.games)
                    currentGames.append(contentsOf: games)
                    upNextPlaylist!.update {
                        upNextPlaylist?.games.removeAll()
                        upNextPlaylist?.games.append(contentsOf: currentGames)
                    }
                }
            }
            self.isAddingToPlayLater = false
        } else {
            autoreleasepool {
                let realm = try! Realm()
                let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
                if upNextPlaylist != nil {
                    var currentGames = games
                    currentGames += upNextPlaylist!.games
                    upNextPlaylist!.update {
                        upNextPlaylist?.games.removeAll()
                        upNextPlaylist?.games.append(contentsOf: currentGames)
                    }
                }
            }
            self.isAddingToPlayNext = false
        }
    }
    
    func handlePlayLater(sender: UIAlertAction) {
        self.isAddingToPlayLater = true
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_queue_large"), title: "Added to Queue", description: nil)
        if self._state! != .inLibrary {
            self.addTapped(sender: nil)
        } else {
            self.addToUpNext(games: [self._game!], later: true)
        }
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
                // Update in Now Playing playlist
                autoreleasepool {
                    let realm = try! Realm()
                    let nowPlayingPlaylist = realm.objects(Playlist.self).filter("isNowPlaying = true").first
                    if nowPlayingPlaylist != nil {
                        if let index = nowPlayingPlaylist?.games.index(where: { (item) -> Bool in
                            item.uuid == self._game!.uuid
                        }) {
                            nowPlayingPlaylist?.update {
                                nowPlayingPlaylist?.games.remove(objectAtIndex: index)
                            }
                        }
                    }
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
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-green"), for: .normal)
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
            self.firstStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
        } else if starIndex == 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 1
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 2
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 3
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 4
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-yellow")
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
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 1
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 2
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-empty-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 3
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-empty-black")
            rating = 4
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.secondStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-yellow")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-yellow")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-yellow")
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
        
        if !self.isAddingToPlaylist && !self.isAddingToPlayNext && !self.isAddingToPlayLater {
            self._selectedPlatforms = consoles
            var currentPlatformList: [Platform] = [Platform]()
            let gameField = self._gameField?.deepCopy()
            
            if consoles.count > 0 {
                for game in (self._gameField?.ownedGames)! {
                    if !consoles.contains(game.platform!) {
                        game.delete()
                    } else {
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
                    if consoles.count == 1 {
                        self._game = newGameToSave
                    } else {
                        self._game = nil
                    }
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
                self.transitionToRemove()
            } else {

                self._gameField = gameField
                UIView.setAnimationsEnabled(false)
                self.platformButton?.setTitle("", for: .normal)
                UIView.setAnimationsEnabled(true)
                self.platformButton?.isEnabled = false
                self.transitionToAdd()
            }
        } else {
            if consoles.count > 0 {
                var currentPlatformList: [Int] = []
                var platformsToAdd: [Platform] = []
                var consoleIds: [Int] = []
                var gameField: GameField?
                autoreleasepool {
                    let realm = try? Realm()
                    gameField = realm?.object(ofType: GameField.self, forPrimaryKey: (self._gameField?.idNumber)!)
                }
                if gameField == nil {
                    gameField = self._gameField?.deepCopy()
                }
                for game in (gameField?.ownedGames)! {
                    if consoles.contains(game.platform!) {
                        currentPlatformList.append(game.platform!.idNumber)
                    }
                }
                for console in consoles {
                    if !currentPlatformList.contains(console.idNumber) {
                        platformsToAdd.append(console)
                    }
                    consoleIds.append(console.idNumber)
                }
                for platform in platformsToAdd {
                    let newGameToSave = Game()
                    newGameToSave.inLibrary = true
                    newGameToSave.add(gameField, platform)
                }
                
                autoreleasepool {
                    let realm = try? Realm()
                    self._gameField = realm?.object(ofType: GameField.self, forPrimaryKey: (gameField?.idNumber)!) // get updated link
                }
                
                var gamesToAdd: [Game] = []
                var platformString: String = ""
                for (i, game) in self._gameField!.ownedGames.enumerated() {
                    let platform = game.platform!
                    if consoleIds.contains(platform.idNumber) {
                        gamesToAdd.append(game)
                    }
                    if (platform.name?.characters.count)! < 10 {
                        platformString += platform.name! + (i == (self._gameField!.ownedGames.count - 1) ? "" : " • ")
                    } else {
                        platformString += platform.abbreviation! + (i == (self._gameField!.ownedGames.count - 1) ? "" : " • ")
                    }
                }
                UIView.setAnimationsEnabled(false)
                self.platformButton?.setTitle(platformString, for: .normal)
                UIView.setAnimationsEnabled(true)
                self.platformButton?.isEnabled = true
                
                self.transitionToRemove()
                
                if self.isAddingToPlaylist {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistNavigation") as! UINavigationController
                    let playlistVc = vc.viewControllers.first as! PlaylistViewController
                    playlistVc.addingGames = gamesToAdd
                    playlistVc.isAddingGames = true
                    playlistVc.delegate = self
                    self.present(vc, animated: true, completion: nil)
                    self.isAddingToPlaylist = false
                }
                if self.isAddingToPlayNext {
                    self.addToUpNext(games: gamesToAdd, later: false)
                    self.isAddingToPlayNext = false
                }
                if self.isAddingToPlayLater {
                    self.addToUpNext(games: gamesToAdd, later: true)
                    self.isAddingToPlayLater = false
                }
            }
        }
    }
}

extension GameDetailsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.detailsScrollView! {
            let offset = scrollView.contentOffset.y
            let initialInset = -(self.maximumHeaderHeight + 25.0 + (self.navigationController?.navigationBar.bounds.height ?? -20.0))
            let heightRange = self.maximumHeaderHeight - self.minimumHeaderHeight
            var newConstant: CGFloat = 0
            var newBorderConstant: CGFloat = 0
            var newBottomConstant: CGFloat = 0
            var heightPercentage = 1 - (offset - initialInset) / heightRange
            if offset >= initialInset && offset <= (initialInset + heightRange) {
                newBorderConstant = heightPercentage * (self.maximumShadowSpacing - self.minimumShadowSpacing) + self.minimumShadowSpacing
                newBottomConstant = -(heightPercentage * (self.maximumShadowBottom - self.minimumShadowBottom) + self.minimumShadowBottom)
                newConstant = self.maximumHeaderHeight - (offset - initialInset)
                self.addBackground?.isHidden = false
                self.statsButton?.isHidden = self.hideStats
                self.moreButton?.isHidden = false
                self.platformButton?.isHidden = false
            } else if offset < initialInset {
                newBorderConstant = self.maximumShadowSpacing
                newBottomConstant = -self.maximumShadowBottom
                newConstant = self.maximumHeaderHeight
                self.addBackground?.isHidden = false
                self.statsButton?.isHidden = false
                self.moreButton?.isHidden = false
                self.platformButton?.isHidden = false
                heightPercentage = 1.0
            } else if offset > (initialInset + heightRange) {
                newBorderConstant = self.minimumShadowSpacing
                newBottomConstant = -self.minimumShadowBottom
                newConstant = self.minimumHeaderHeight
                self.addBackground?.isHidden = true
                self.statsButton?.isHidden = true
                self.moreButton?.isHidden = true
                self.platformButton?.isHidden = true
                heightPercentage = 0.0
            }
            self.headerHeightConstraint?.constant = newConstant
            self.shadowTopConstraint?.constant = newBorderConstant
            self.shadowLeadingConstraint?.constant = newBorderConstant
            self.shadowBottomConstraint?.constant = newBottomConstant
            self.addBackground?.alpha = heightPercentage
            self.statsButton?.alpha = heightPercentage
            self.moreButton?.alpha = heightPercentage
            self.yearLabel?.alpha = heightPercentage
            self.platformButton?.alpha = heightPercentage
            self.completionLabel?.alpha = heightPercentage
            self.completionImageView?.alpha = heightPercentage
            self.steamLogo?.alpha = heightPercentage
            self.steamUserLabel?.alpha = heightPercentage
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView == self.detailsScrollView {
            let offset = targetContentOffset.pointee.y
            let initialInset = -(self.maximumHeaderHeight + 25.0 + (self.navigationController?.navigationBar.bounds.height ?? -20.0))
            let heightRange = self.maximumHeaderHeight - self.minimumHeaderHeight
            if offset >= initialInset && offset <= (initialInset + heightRange) {
                if (offset - initialInset) < heightRange / 2.0 {
                    targetContentOffset.pointee = CGPoint(x: 0.0, y: initialInset)
                } else {
                    targetContentOffset.pointee = CGPoint(x: 0.0, y: initialInset + heightRange)
                }
            }
        } else if let collectionView = scrollView as? UICollectionView {
            if collectionView == self.imageCollectionView! {
                let itemWidth = collectionView
            }
        }
    }
}

extension GameDetailsViewController: GalleryItemsDataSource {
    func itemCount() -> Int {
        return self.game?.gameFields?.images.count ?? 0
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return self.images[index]!.galleryItem
    }
}

extension GameDetailsViewController: GalleryItemsDelegate {
    func removeGalleryItem(at index: Int) {
        print("remove item at \(index)")
    }
}

extension GameDetailsViewController: GalleryDisplacedViewsDataSource {
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView? {
        return index < self.images.count ? self.images[index]?.imageView : nil
    }
}

extension GameDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.imageCollectionView! {
            return self.gameField?.images.count ?? 0
        } else if collectionView == self.charactersCollectionView! {
            return self.gameField?.characters.count ?? 0
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = collectionView.frame.size
        if collectionView == self.charactersCollectionView! {
            size.width = 105.0
        } else {
            size.width = size.height
        }
        return size
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.imageCollectionView! {
            // get a reference to our storyboard cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.imageCellReuseIdentifier, for: indexPath) as! ImageCell
            let cellView = cell.contentView
            if let imageView = self.images[indexPath.row]?.imageView {
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
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.characterCellReuseIdentifier, for: indexPath) as! CharacterCell
            guard let character = self.gameField?.characters[indexPath.row] else {
                return cell
            }
            var characterImageView: UIImageView
            if indexPath.item == self.characterImageViews.count {
                characterImageView = UIImageView()
                characterImageView.backgroundColor = .white
                characterImageView.tag = 9000
                self.characterImageViews.append(characterImageView)
            } else {
                characterImageView = self.characterImageViews[indexPath.item]
            }
            cell.characterLabel?.text = character.name
            characterImageView.translatesAutoresizingMaskIntoConstraints = false
            characterImageView.contentMode = .scaleAspectFill
            characterImageView.clipsToBounds = true
            characterImageView.layer.cornerRadius = 52.0
            cell.characterBorder?.addSubview(characterImageView)
            NSLayoutConstraint(item: characterImageView, attribute: .top, relatedBy: .equal, toItem: cell.characterBorder!, attribute: .top, multiplier: 1.0, constant: 0.5).isActive = true
            NSLayoutConstraint(item: characterImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.characterBorder!, attribute: .bottom, multiplier: 1.0, constant: -0.5).isActive = true
            NSLayoutConstraint(item: characterImageView, attribute: .leading, relatedBy: .equal, toItem: cell.characterBorder!, attribute: .leading, multiplier: 1.0, constant: 0.5).isActive = true
            NSLayoutConstraint(item: characterImageView, attribute: .trailing, relatedBy: .equal, toItem: cell.characterBorder!, attribute: .trailing, multiplier: 1.0, constant: -0.5).isActive = true

            if let urlString = character.image?.mediumUrl {
                if urlString.hasSuffix("question_mark.jpg") {
                    characterImageView.image = #imageLiteral(resourceName: "new_playlist")
                    cell.hideImage()
                } else {
                    characterImageView.image = nil
                    cell.showImage()
                    characterImageView.kf.setImage(with: URL(string: urlString)!, placeholder: nil, completionHandler: {
                        (image, error, cacheType, imageUrl) in
                        if image != nil {
                            if cacheType == .none {
                                UIView.transition(with: characterImageView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                    characterImageView.image = image
                                }, completion: nil)
                            } else {
                                characterImageView.image = image
                            }
                        }
                    })
                }
            } else if character.hasImage {
                characterImageView.image = #imageLiteral(resourceName: "new_playlist")
                cell.hideImage()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.imageCollectionView! {
            let displacedViewIndex = indexPath.item
            
            let galleryViewController = GalleryViewController(startIndex: displacedViewIndex, itemsDataSource: self, itemsDelegate: self, displacedViewsDataSource: self, configuration: galleryConfiguration())
            
            self.presentImageGallery(galleryViewController)
        }
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.closeButtonMode(.builtIn),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.displacement),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(false),
            
            GalleryConfigurationItem.swipeToDismissMode(.vertical),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(true),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(1),
            GalleryConfigurationItem.overlayBlurOpacity(1),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.light),
            
            GalleryConfigurationItem.videoControlsColor(.white),
            
            GalleryConfigurationItem.maximumZoomScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.25),
            
            GalleryConfigurationItem.blurPresentDuration(0.5),
            GalleryConfigurationItem.blurPresentDelay(0),
            GalleryConfigurationItem.colorPresentDuration(0.25),
            GalleryConfigurationItem.colorPresentDelay(0),
            
            GalleryConfigurationItem.blurDismissDuration(0.1),
            GalleryConfigurationItem.blurDismissDelay(0.4),
            GalleryConfigurationItem.colorDismissDuration(0.45),
            GalleryConfigurationItem.colorDismissDelay(0),
            
            GalleryConfigurationItem.itemFadeDuration(0.3),
            GalleryConfigurationItem.decorationViewsFadeDuration(0.15),
            GalleryConfigurationItem.rotationDuration(0.15),
            
            GalleryConfigurationItem.displacementDuration(0.55),
            GalleryConfigurationItem.reverseDisplacementDuration(0.25),
            GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
            GalleryConfigurationItem.displacementTimingCurve(.linear),
            
            GalleryConfigurationItem.statusBarHidden(true),
            GalleryConfigurationItem.displacementKeepOriginalInPlace(false),
            GalleryConfigurationItem.displacementInsetMargin(50),
            
            GalleryConfigurationItem.deleteButtonMode(.none)
        ]
    }
}
