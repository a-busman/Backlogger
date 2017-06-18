//
//  GameDetailOverlayViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import ImageViewer

extension UIImageView: DisplaceableView {}

protocol GameDetailOverlayViewControllerDelegate {
    func didTapDetails()
}

struct DataItem {
    let imageView: UIImageView
    var galleryItem: GalleryItem
}

class GameDetailOverlayViewController: UIViewController {
    @IBOutlet weak var titleLabel:           UILabel?
    @IBOutlet weak var completionPercentage: UILabel?
    @IBOutlet weak var platformLabel:        UILabel?
    @IBOutlet weak var progressSliderView:   UISlider?
    @IBOutlet weak var scrollView:           UIScrollView?
    @IBOutlet weak var contentView:          UIView?
    @IBOutlet weak var descriptionLabel:     UILabel?
    @IBOutlet weak var imageCollectionView:  UICollectionView?
    @IBOutlet weak var publisherLabel:       UILabel?
    @IBOutlet weak var developerLabel:       UILabel?
    @IBOutlet weak var platformsLabel:       UILabel?
    @IBOutlet weak var genresLabel:          UILabel?
    @IBOutlet weak var completionView:       UIView?
    @IBOutlet weak var completionCheckImage: UIImageView?
    @IBOutlet weak var completionLabel:      UILabel?
    @IBOutlet weak var detailsGestureView:   UIView?
    @IBOutlet weak var pullTabView:          UIView?
    
    private var _game:  Game?
    
    let imageCellReuseIdentifier = "image_cell"
    
    enum CompletionState {
        case finished
        case inProgress
    }
    
    var images: [Int: DataItem] = [:]
    
    var delegate: GameDetailOverlayViewControllerDelegate?

    private var completionState = CompletionState.inProgress
    
    var game: Game? {
        get {
            return self._game
        }
        set(newGame) {
            self._game = newGame
            self.titleLabel?.text = newGame?.gameFields?.name
            self.descriptionLabel?.text = newGame?.gameFields?.deck
            var platformString = ""
            if let platforms = newGame?.gameFields?.platforms {
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
                self.platformLabel?.text = (self._game?.platform?.name)!
            }
            self.platformsLabel?.text = platformString
            
            var developersString = ""
            if let developers = newGame?.gameFields?.developers {
                if developers.count > 0 {
                    if developers.count > 1 {
                        for developer in developers[0..<developers.endIndex - 1] {
                            developersString += developer.name! + ", "
                        }
                    }
                    developersString += (developers.last?.name)!
                }
            }
            self.developerLabel?.text = developersString
            
            var publishersString = ""
            if let publishers = newGame?.gameFields?.publishers {
                if publishers.count > 0 {
                    if publishers.count > 1 {
                        for publisher in publishers[0..<publishers.endIndex - 1] {
                            publishersString += publisher.name! + ", "
                        }
                    }
                    publishersString += (publishers.last?.name)!
                }
            }
            self.publisherLabel?.text = publishersString
            
            var genresString = ""
            if let genres = newGame?.gameFields?.genres {
                if genres.count > 0 {
                    if genres.count > 1 {
                        for genre in genres[0..<genres.endIndex - 1] {
                            genresString += genre.name! + ", "
                        }
                    }
                    genresString += (genres.last?.name)!
                }
            }
            self.genresLabel?.text = genresString
            
            completionPercentage?.text = "\((newGame?.progress)!)%"
            progressSliderView?.value = Float((newGame?.progress)!)
            
            if (newGame?.finished)! == true {
                self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light")
                self.completionLabel?.text = "Finished"
            } else {
                self.completionCheckImage?.image = #imageLiteral(resourceName: "check_light_filled")
                self.completionLabel?.text = "In Progress"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView?.delegate = self
        self.scrollView?.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 5.0, 0.0)
        
        // Download all images at once
        if let game = self._game {
            for (i, image) in game.gameFields!.images.enumerated() {
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
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.scrollView?.contentSize = (self.contentView?.bounds.size)!
        self.imageCollectionView?.reloadData()
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
        let remainder = Int(sender.value) % 10
        var newValue: Int = 0
        if remainder < 5 {
            newValue = Int(sender.value) - remainder
        } else {
            newValue = Int(sender.value) + 10 - remainder
        }
        sender.value = Float(newValue)

        completionPercentage?.text = "\(newValue)%"
        self._game?.update {
            self._game?.progress = newValue
        }
    }
    
    @IBAction func tappedDetails(sender: UITapGestureRecognizer) {
        delegate?.didTapDetails()
    }
}

extension GameDetailOverlayViewController: GalleryItemsDataSource {
    func itemCount() -> Int {
        return self.game?.gameFields?.images.count ?? 0
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return self.images[index]!.galleryItem
    }
}

extension GameDetailOverlayViewController: GalleryItemsDelegate {
    func removeGalleryItem(at index: Int) {
        print("remove item at \(index)")
    }
}

extension GameDetailOverlayViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}

extension GameDetailOverlayViewController: GalleryDisplacedViewsDataSource {
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView? {
        return index < self.images.count ? self.images[index]?.imageView : nil
    }
}

extension GameDetailOverlayViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.game?.gameFields?.images.count ?? 0
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
        let cellView = self.images[indexPath.row]!.imageView
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
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
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let displacedViewIndex = indexPath.item
        
        let galleryViewController = GalleryViewController(startIndex: displacedViewIndex, itemsDataSource: self, itemsDelegate: self, displacedViewsDataSource: self, configuration: galleryConfiguration())
        
        self.presentImageGallery(galleryViewController)
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
