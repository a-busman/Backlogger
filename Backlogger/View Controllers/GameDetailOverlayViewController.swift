//
//  GameDetailOverlayViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

protocol GameDetailOverlayViewControllerDelegate {
    func didTapDetails()
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
    
    var images:        [UIImage]?
    private var _game:  Game?
    
    let imageCellReuseIdentifier = "image_cell"
    
    enum CompletionState {
        case finished
        case inProgress
    }
    
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
            self.images = []
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
            
            if let images = newGame?.gameFields?.images {
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
            }
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
        scrollView?.delegate = self
        scrollView?.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 5.0, 0.0)
    }
    
    override func viewDidLayoutSubviews() {
        self.scrollView?.contentSize = (self.contentView?.bounds.size)!
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

extension GameDetailOverlayViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}

extension GameDetailOverlayViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images?.count ?? 0
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
        if (self.images?.count)! > 0 {
            if let image = self.images?[indexPath.item] {
                UIView.transition(with: cellView,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { cellView.image = image },
                                  completion: nil)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
}
