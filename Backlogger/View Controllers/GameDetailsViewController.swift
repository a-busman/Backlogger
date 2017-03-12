//
//  GameDetailsViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/24/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class GameDetailsViewController: UIViewController {
    @IBOutlet weak var mainImageView:          UIImageView?
    @IBOutlet weak var titleLabel:             UILabel?
    @IBOutlet weak var yearLabel:              UILabel?
    @IBOutlet weak var platformLabel:          UILabel?
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

    @IBOutlet weak var firstStar:  UIImageView?
    @IBOutlet weak var secondStar: UIImageView?
    @IBOutlet weak var thirdStar:  UIImageView?
    @IBOutlet weak var fourthStar: UIImageView?
    @IBOutlet weak var fifthStar:  UIImageView?
    
    @IBOutlet weak var doneButton: UIBarButtonItem?
    
    var addedToLibrary = AddedOverlayViewController()
    
    @IBOutlet weak var informationTopConstraint: NSLayoutConstraint?
    
    var images: [UIImage]?
    
    let imageCellReuseIdentifier = "image_cell"

    let headerBorder = CALayer()
    
    private var _game: Game?
    private var _state: State?
    
    enum State {
        case Add
        case InLibrary
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
    
    var game: Game? {
        get {
            return self._game
        }
        set(newGame) {
            self._game = newGame
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
            
            var platformString = ""
            if let platforms = newGame?.platforms {
                if platforms.count > 0 {
                    if platforms.count > 1 {
                        for platform in platforms[0..<platforms.endIndex - 1] {
                            if platform.name!.characters.count < 10 {
                                platformString += platform.name! + " | "
                            } else {
                                platformString += platform.abbreviation! + " | "
                            }
                        }
                    }
                    if platforms[platforms.endIndex - 1].name!.characters.count < 10 {
                        platformString += platforms[platforms.endIndex - 1].name!
                    } else {
                        platformString += platforms[platforms.endIndex - 1].abbreviation!
                    }
                }
            }
            self.platformLabel?.text = platformString
            
            newGame?.getImage(withSize: .MediumUrl, { result in
                if let error = result.error {
                    NSLog("\(error.localizedDescription)")
                    return
                }
                UIView.transition(with: self.mainImageView!,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.mainImageView?.image = result.value! },
                                  completion: nil)
            })
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        if self._state == .Add {
            self.statsButton?.alpha = 0.0
            self.progressIcon?.alpha = 0.0
        } else {
            self.statsButton?.alpha = 1.0
            self.progressIcon?.alpha = 1.0
            self.addLabel?.text = "REMOVE"
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
        self.statsButton?.layer.borderColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0).cgColor
        
        self.percentageBlurView?.effect = nil
        self.percentageVibrancyView?.effect = nil
        self.percentageLabel?.alpha = 0.0
        
        guard let game = self._game else {
            NSLog("No game yet")
            return
        }
        self.images = []
        game.updateGameDetails { result in
            if let error = result.error {
                NSLog("error: \(error.localizedDescription)")
                return
            }
            self.imageCollectionView?.reloadData()
            if let images = self._game?.images {
                if images.count == 0 {
                    self.imagesTitleLabel?.isHidden = true
                    self.imageCollectionView?.isHidden = true
                    self.informationTopConstraint?.isActive = false
                    self.informationTopConstraint = NSLayoutConstraint(item: self.informationTitleLabel!, attribute: .top, relatedBy: .equal, toItem: self.descriptionView!, attribute: .bottom, multiplier: 1.0, constant: 5.0)
                    self.informationTopConstraint?.isActive = true
                }
                for image in images {
                    image.getImage(field: .MediumUrl, { results in
                        if let error = results.error {
                            NSLog("error getting images: \(error.localizedDescription)")
                            return
                        }
                        self.images?.append(results.value!)
                        self.imageCollectionView?.reloadData()
                    })
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
            if let platforms = game.platforms {
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
                    self.platformLabel?.text = platforms[0].name
                }
            }
            if platformString == "" {
                platformString = "N/A"
            }
            self.platformsLabel?.text = platformString
            
            var developersString = ""
            if let developers = game.developers {
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
            if let publishers = game.publishers {
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
            if let genres = game.genres {
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
        if let titleString = game.name {
            self.titleLabel?.text = titleString
        }
        var yearLabelText = ""
        if let releaseDate = game.releaseDate {
            if !releaseDate.isEmpty {
                let index = releaseDate.index(releaseDate.startIndex, offsetBy: 4)
                yearLabelText = releaseDate.substring(to: index)
            } else {
                if let expectedDate = game.expectedDate {
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
        
        var platformString = ""
        if let platforms = game.platforms {
            if platforms.count > 0 {
                if platforms.count > 1 {
                    for platform in platforms[0..<platforms.endIndex - 1] {
                        if platform.name!.characters.count < 10 {
                            platformString += platform.name! + " | "
                        } else {
                            platformString += platform.abbreviation! + " | "
                        }
                    }
                }
                if platforms[platforms.endIndex - 1].name!.characters.count < 10 {
                    platformString += platforms[platforms.endIndex - 1].name!
                } else {
                    platformString += platforms[platforms.endIndex - 1].abbreviation!
                }
            }
        }
        if platformString == "" {
            platformString = "Platform Unknown"
        }
        self.platformLabel?.text = platformString
        
        self.descriptionView?.text = game.description
        self.addedToLibrary.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(addedToLibrary.view)
        NSLayoutConstraint(item: addedToLibrary.view,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerX,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: addedToLibrary.view,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: self.view,
                           attribute: .centerY,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: addedToLibrary.view,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 250.0
            ).isActive = true
        NSLayoutConstraint(item: addedToLibrary.view,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 250.0
            ).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        self.shadowView?.layer.shadowOpacity = 0.8
        self.shadowView?.layer.shadowRadius = 5.0
        self.shadowView?.layer.shadowColor = UIColor.black.cgColor
        self.shadowView?.layer.shadowPath = UIBezierPath(rect: (self.shadowView?.bounds)!).cgPath
        self.shadowView?.layer.shadowOffset = CGSize.zero
        
        self.detailsScrollView?.scrollIndicatorInsets = UIEdgeInsets(top: (self.headerView?.bounds.height)! + 69.0, left: 0, bottom: 0, right: 0)
        self.detailsScrollView?.contentInset = UIEdgeInsets(top: (self.headerView?.bounds.height)! + 69.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        bottomBorder.frame = CGRect(x:0, y:(self.headerView?.frame.size.height)! - 0.5, width: (self.headerView?.frame.size.width)!, height: 0.5)
        self.headerView?.layer.addSublayer(bottomBorder)
    }
    override var previewActionItems: [UIPreviewActionItem] {
        return [UIPreviewAction(title: "Add", style: .default, handler: {[unowned self] (_, _) -> Void in
        })]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
    }
    
    @IBAction func addTapped(sender: UITapGestureRecognizer) {
        if self.state == .Add {
            addedToLibrary.appear()
            self.state = .InLibrary
            self.addLabel?.text = "REMOVE"
            UIView.animate(withDuration: 0.2, animations: {
                self.addSymbolImage?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4.0)
                self.addBackground?.backgroundColor = .red
                self.statsButton?.alpha = 1.0
                self.progressIcon?.alpha = 1.0
                self.view.layoutIfNeeded()
            })
        } else {
            self.state = .Add
            self.addLabel?.text = "ADD"
            UIView.animate(withDuration: 0.2, animations: {
                self.addSymbolImage?.transform = CGAffineTransform(rotationAngle: 0.0)
                self.addBackground?.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
                self.statsButton?.alpha = 0.0
                self.progressIcon?.alpha = 0.0
                self.view.layoutIfNeeded()
            })
            if self.statsState == .visible {
                UIView.animate(withDuration: 0.2,
                               animations: {
                    self.statsButton?.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
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
                self.statsLabel?.textColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
                self.statsScrollView?.alpha = 1.0
                self.statsEffectView?.effect = UIBlurEffect(style: .extraLight)
            })
            self.statsState = .visible
        } else {
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.statsButton?.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.725, blue: 1.0, alpha: 1.0)
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
    
    @IBAction func artTapped(sender: UITapGestureRecognizer) {
        if self.state == .InLibrary {
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
            } else {
                self.favouriteButton?.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                self.favouriteButtonState = .selected
            }
        case 2:
            if self.playButtonState == .selected {
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
            } else {
                self.finishedButton?.setImage(#imageLiteral(resourceName: "check-black"), for: .normal)
                self.finishedButtonState = .selected
                self.completionLabel?.text = "Complete"
                self.completionImageView?.image = #imageLiteral(resourceName: "check")
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
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-black")
        }
        self.notesTextView?.resignFirstResponder()
    }
    
    @IBAction func ratingTapHandler(sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.ratingContainerView!)
        let starIndex = Int(location.x / ((self.ratingContainerView?.bounds.width)! / 5.0))
        
        if starIndex <= 0 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-white")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 1 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-white")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 2 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-white")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else if starIndex == 3 {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-white")
        } else {
            self.firstStar?.image  = #imageLiteral(resourceName: "star-black")
            self.secondStar?.image = #imageLiteral(resourceName: "star-black")
            self.thirdStar?.image  = #imageLiteral(resourceName: "star-black")
            self.fourthStar?.image = #imageLiteral(resourceName: "star-black")
            self.fifthStar?.image  = #imageLiteral(resourceName: "star-black")
        }
        self.notesTextView?.resignFirstResponder()
    }
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
        self.doneButton?.isEnabled = true
        UIView.animate(withDuration: 0.2, animations: {self.doneButton?.title = "Done"})
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
        self.doneButton?.isEnabled = false
        UIView.animate(withDuration: 0.2, animations: {self.doneButton?.title = " "})
    }
    
    @IBAction func handleTapDone() {
        self.notesTextView?.resignFirstResponder()
    }
}

extension GameDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.game?.images?.count ?? 0
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
        let cellView = UIImageView()
        cellView.clipsToBounds = true
        cell.clipsToBounds = false
        cellView.contentMode = .scaleAspectFill
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
        
        cell.contentView.layer.shadowOpacity = 1.0
        cell.contentView.layer.shadowRadius = 2.0
        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        let newBounds = cell.bounds
        cell.contentView.layer.shadowPath = UIBezierPath(rect: CGRect(x: newBounds.origin.x + 5, y: newBounds.origin.y + 5, width: newBounds.width - 10, height: newBounds.height - 10)).cgPath
        cell.contentView.layer.shadowOffset = .zero
        if indexPath.item >= (self.images?.count)! {
            cellView.image = #imageLiteral(resourceName: "info_image_placeholder")
        } else {
            if (self.images?.count)! > 0 {
                if let image = self.images?[indexPath.item] {
                    UIView.transition(with: cellView,
                                      duration:0.5,
                                      options: .transitionCrossDissolve,
                                      animations: { cellView.image = image },
                                      completion: nil)
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
