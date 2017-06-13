//
//  NewPlaylistViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 5/4/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import AVFoundation
import RealmSwift
import Kingfisher

class PlaylistDetailsViewController: UITableViewController, UITextViewDelegate, PlaylistTitleCellDelegate, PlaylistAddTableCellDelegate, AddToPlaylistViewControllerDelegate, PlaylistFooterDelegate {
    
    @IBOutlet weak var noGamesView: UIView?
    
    let cellReuseIdentifier = "playlist_detail_cell"
    let titleReuseIdentifier = "playlist_title_cell"
    let descriptionReuseIdentifier = "playlist_description_cell"

    var playlistFooterView = PlaylistFooter()
    
    var titleTextViewHeight: CGFloat = 0.0
    var descriptionTextViewHeight: CGFloat = 0.0
    
    var firstLoaded = false
    
    var playlist: Playlist?
    
    var games = List<Game>()
    
    var imageCache: [Int: UIImage] = [:]
    
    var selectedRow = -1
    
    var movingIndexPath: IndexPath?
    
    var playlistImage: UIImage?
    
    var titleCell = PlaylistTitleCell()
    var descCell  = PlaylistDescriptionCell()
    
    var addCell: PlaylistAddTableCell?
    
    var toastOverlay = ToastOverlayViewController()
    
    var imagesLoaded = 0

    var titleInit = false
    var descriptionInit = false
    var addInit = false
    
    var descriptionVisible = false
    
    var isDismissing = false
    
    enum ImageSource {
        case custom
        case loaded
        case generated
        case none
    }
    
    var playlistImageSource: ImageSource = .none
    
    var didEditField = false
    
    enum PlaylistState {
        case new
        case editing
        case `default`
    }
    
    private var _playlistState: PlaylistState = .default
    
    var playlistState: PlaylistState {
        get {
            return self._playlistState
        }
        set(newState) {
            self._playlistState = newState
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        
        self.tableView.allowsSelectionDuringEditing = true
        if self._playlistState == .new {
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightTapped))
            let newLeftButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(leftTapped))
            self.navigationController?.navigationBar.topItem?.rightBarButtonItem = newRightButton
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newLeftButton
            self.tableView.setEditing(true, animated: false)
            self.navigationItem.title = "New Playlist"
            
        } else {
            if let playlist = self.playlist {
                self.games.append(contentsOf: playlist.games)
                self.loadPlaylistImage()
            }
            self.playlistFooterView.delegate = self
        }
        self.tableView.register(UINib(nibName: "PlaylistAddTableCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.titleReuseIdentifier)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.descriptionReuseIdentifier)

        self.addCell = self.tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as? PlaylistAddTableCell
        
        self.titleCell.titleDelegate = self
        self.titleCell.observer = self
        self.titleCell.delegate = self
        self.descCell.descriptionDelegate = self
        self.descCell.observer = self

        if self._playlistState == .new {
            self.titleCell.isEditable = true
            self.descCell.isEditable = true
        } else {
            self.titleCell.titleString = self.playlist?.name ?? ""
            self.titleCell.isEditable = false
            self.descCell.descriptionString = self.playlist?.descriptionText ?? ""
            self.descCell.isEditable = false
        }
        self.titleCell.view.translatesAutoresizingMaskIntoConstraints = false
        self.descCell.view.translatesAutoresizingMaskIntoConstraints = false
        self.toastOverlay.view.translatesAutoresizingMaskIntoConstraints = false
        let window = UIApplication.shared.keyWindow!
        window.addSubview(toastOverlay.view)
        NSLayoutConstraint(item: toastOverlay.view, attribute: .centerY, relatedBy: .equal, toItem: window, attribute: .centerY, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: toastOverlay.view, attribute: .centerX, relatedBy: .equal, toItem: window, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: toastOverlay.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 300.0).isActive = true
    }
    
    func refreshTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func reloadDataWithCrossDissolve() {
        UIView.transition(with: self.tableView, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
    }
    
    func refreshSection(_ set: IndexSet) {
        DispatchQueue.main.async {
            self.tableView.reloadSections(set, with: .none)
        }
    }
    
    func updatePlaylistImage() {
        if self.firstLoaded {
            switch self.games.count {
            case 0:
                // reset to default
                self.playlistImage = nil
                self.titleCell.artImage = nil
                self.titleCell.hideImage()
                return
            case 1:
                self.playlistImage = self.imageCache[self.games[0].gameFields!.idNumber]
                break
            case 2:
                if let image1 = self.imageCache[self.games[0].gameFields!.idNumber],
                   let image2 = self.imageCache[self.games[1].gameFields!.idNumber] {
                    self.playlistImage = self.stitch(images: [image1, image2], isVertical: false)
                }
                break
            case 3:
                if let image1 = self.imageCache[self.games[0].gameFields!.idNumber],
                   let image2 = self.imageCache[self.games[1].gameFields!.idNumber],
                   let image3 = self.imageCache[self.games[2].gameFields!.idNumber] {
                    let intermediate   = self.stitch(images: [image1, image2], isVertical: false)
                    self.playlistImage = self.stitch(images: [intermediate, image3], isVertical: true)
                }
                break
            default:
                if let image1 = self.imageCache[self.games[0].gameFields!.idNumber],
                   let image2 = self.imageCache[self.games[1].gameFields!.idNumber],
                   let image3 = self.imageCache[self.games[2].gameFields!.idNumber],
                   let image4 = self.imageCache[self.games[3].gameFields!.idNumber] {
                    let intermediate1  = self.stitch(images: [image1, image2], isVertical: false)
                    let intermediate2  = self.stitch(images: [image3, image4], isVertical: false)
                    self.playlistImage = self.stitch(images: [intermediate1, intermediate2], isVertical: true)
                }
            }
            if self._playlistState != .new {
                self.savePlaylistImage()
            }
        }
        self.titleCell.artImage = self.playlistImage
        self.titleCell.showImage()
    }
    
    func savePlaylistImage() {
        let filename = Util.getPlaylistImagesDirectory().appendingPathComponent("\(self.playlist!.uuid).png")
        if self.playlistImage != nil {
            let data = UIImagePNGRepresentation(self.playlistImage!)
            try? data?.write(to: filename)
        } else {
            try? FileManager.default.removeItem(at: filename)
        }
    }
    
    func loadPlaylistImage() {
        let filename = Util.getPlaylistImagesDirectory().appendingPathComponent("\(self.playlist!.uuid).png")
        self.playlistImage = UIImage(contentsOfFile: filename.path)
        if self.playlistImage != nil {
            if self.playlist?.imageUrl != nil {
                self.playlistImageSource = .custom
            } else {
                self.playlistImageSource = .loaded
            }
        }
    }
    
    func stitch(images: [UIImage], isVertical: Bool) -> UIImage {
        var stitchedImages : UIImage!
        if images.count > 0 {
            var maxWidth = CGFloat(0), maxHeight = CGFloat(0)
            for image in images {
                if image.size.width > maxWidth {
                    maxWidth = image.size.width
                }
                if image.size.height > maxHeight {
                    maxHeight = image.size.height
                }
            }
            var totalSize : CGSize
            let maxSize = CGSize(width: maxWidth, height: maxHeight)
            if isVertical {
                totalSize = CGSize(width: maxSize.width, height: maxSize.height * (CGFloat)(images.count))
            } else {
                totalSize = CGSize(width: maxSize.width  * (CGFloat)(images.count), height:  maxSize.height)
            }
            UIGraphicsBeginImageContext(totalSize)
            for image in images {
                var croppedImage: UIImage?
                if isVertical {
                    if image.size.width < maxSize.width {
                        croppedImage = self.image(with: image, scaledTo: maxSize.width / image.size.width)
                        croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                    }
                    if croppedImage != nil {
                        if croppedImage!.size.height < maxSize.height {
                            croppedImage = self.image(with: croppedImage!, scaledTo: maxSize.height / croppedImage!.size.height)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    } else {
                        if image.size.height < maxSize.height {
                            croppedImage = self.image(with: image, scaledTo: maxSize.height / image.size.height)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    }
                } else {
                    if image.size.width < maxSize.width {
                        croppedImage = self.image(with: image, scaledTo: maxSize.width / image.size.width)
                        croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                    }
                    if croppedImage != nil {
                        if croppedImage!.size.height < maxSize.height {
                            croppedImage = self.image(with: croppedImage!, scaledTo: maxSize.height / croppedImage!.size.height)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    } else {
                        if image.size.height < maxSize.height {
                            croppedImage = self.image(with: image, scaledTo: maxSize.height / image.size.height)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    }
                }
                let offset = (CGFloat)(images.index(of: image)!)
                if croppedImage == nil {
                    let rect =  AVMakeRect(aspectRatio: image.size, insideRect: isVertical ?
                        CGRect(x: 0, y: maxSize.height * offset, width: maxSize.width, height: maxSize.height) :
                        CGRect(x: maxSize.width * offset, y: 0, width: maxSize.width, height: maxSize.height))
                    image.draw(in: rect)
                } else {
                    let rect =  AVMakeRect(aspectRatio: croppedImage!.size, insideRect: isVertical ?
                        CGRect(x: 0, y: maxSize.height * offset, width: maxSize.width, height: maxSize.height) :
                        CGRect(x: maxSize.width * offset, y: 0, width: maxSize.width, height: maxSize.height))
                    croppedImage!.draw(in: rect)
                }
            }
            stitchedImages = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return stitchedImages
    }
    
    func cropToBounds(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let rect: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    func image(with sourceImage: UIImage, scaledTo factor: CGFloat) -> UIImage {
        let newHeight = sourceImage.size.height * factor
        let newWidth = sourceImage.size.width * factor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func dismissView(_ vc: AddToPlaylistViewController) {
        self.isDismissing = true
        vc.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self._playlistState == .default {
            self.playlistFooterView.update(count: self.games.count)
            var percent = 0
            for game in self.games {
                percent += game.progress
            }
            
            percent /= self.games.count == 0 ? 1 : self.games.count
            
            self.playlistFooterView.update(percent: percent)
            self.playlistFooterView.showButton = self.games.count == 0
            self.tableView.tableFooterView = playlistFooterView.view
        } else {
            if self._playlistState == .editing && !self.isDismissing {
                self.rightTapped(sender: UIBarButtonItem())
            } else if self.isDismissing {
                self.isDismissing = false
            }
            self.tableView.tableFooterView = UIView(frame: .zero)
        }
        self.imagesLoaded = 0
        self.tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isMovingFromParentViewController {
            self.titleCell.titleTextView?.removeObserver(self, forKeyPath: "contentSize")
            self.descCell.descriptionTextView?.removeObserver(self, forKeyPath: "contentSize")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.imageCache = [:]
    }
    
    func moreTapped(sender: UITapGestureRecognizer) {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Remove...", style: .default, handler: self.handleFirstDelete)
        let addToAction = UIAlertAction(title: "Add to Playlist", style: .default, handler: self.handleAddToPlaylist)
        let playNextAction = UIAlertAction(title: "Play Next", style: .default, handler: self.handlePlayNext)
        let queueAction = UIAlertAction(title: "Play Later", style: .default, handler: self.handlePlayLater)
        deleteAction.setValue(#imageLiteral(resourceName: "trash"), forKey: "image")
        addToAction.setValue(#imageLiteral(resourceName: "add_to_playlist"), forKey: "image")
        playNextAction.setValue(#imageLiteral(resourceName: "play_next"), forKey: "image")
        queueAction.setValue(#imageLiteral(resourceName: "add_to_queue"), forKey: "image")
        
        actions.addAction(deleteAction)
        actions.addAction(addToAction)
        actions.addAction(playNextAction)
        actions.addAction(queueAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)
    }
    
    func handleFirstDelete(sender: UIAlertAction) {
        let actions = UIAlertController(title: "Delete from Game Library", message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Playlist", style: .destructive, handler: self.handleSecondDelete)
        actions.addAction(deleteAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actions, animated: true, completion: nil)
    }
    
    func handleSecondDelete(sender: UIAlertAction) {
        self.playlist?.delete()
        self.navigationController?.popViewController(animated: true)
    }
    
    func handleAddToPlaylist(sender: UIAlertAction) {
        let gameCount = 5
        let playlist = "Really long playlist name that allows me to see if this thing works correctly or not. Maybe it will."
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "checkmark"), title: "Added to Playlist", description: "\(gameCount) games added to \"\(playlist)\".")
    }
    
    func handlePlayNext(sender: UIAlertAction) {
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "checkmark"), title: "Added to Queue", description: "We'll play this next.")
        autoreleasepool {
            let realm = try! Realm()
            let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
            if upNextPlaylist != nil {
                var currentGames = self.games
                currentGames += upNextPlaylist!.games
                upNextPlaylist!.update {
                    upNextPlaylist?.games.removeAll()
                    upNextPlaylist?.games.append(contentsOf: currentGames)
                }
            }
        }
    }
    
    func handlePlayLater(sender: UIAlertAction) {
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "checkmark"), title: "Added to Queue", description: nil)

        autoreleasepool {
            let realm = try! Realm()
            let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
            if upNextPlaylist != nil {
                var currentGames = Array(upNextPlaylist!.games)
                currentGames += self.games
                upNextPlaylist!.update {
                    upNextPlaylist?.games.removeAll()
                    upNextPlaylist?.games.append(contentsOf: currentGames)
                }
            }
        }
    }
    
    //Cancel or back
    func leftTapped(sender: UIBarButtonItem) {
        self.titleCell.titleTextView?.resignFirstResponder()
        self.descCell.descriptionTextView?.resignFirstResponder()
        if self._playlistState == .new {
            self.dismiss(animated: true, completion: nil)
        } else if self._playlistState == .editing {
            self._playlistState = .default
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(rightTapped))
            self.navigationItem.setRightBarButton(newRightButton, animated: true)
            self.navigationItem.setLeftBarButton(nil, animated: true)
            self.tableView.tableFooterView = self.playlistFooterView.view
            self.tableView.setEditing(false, animated: false)
            self.games.removeAll()
            self.games.append(contentsOf: self.playlist!.games)
            self.imagesLoaded = 0
            self.reloadDataWithCrossDissolve()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func saveCurrentState(playlist: Playlist?) {
        if playlist == nil {
            self.playlist?.update {
                self.playlist?.games.removeAll()
                self.playlist?.games.append(contentsOf: self.games)
                if self.titleCell.titleTextView?.textColor != .lightGray {
                    self.playlist?.name = self.titleCell.titleTextView?.text
                    self.titleCell.titleLabel?.text = self.titleCell.titleTextView?.text
                } else {
                    self.playlist?.name = "Untitled Playlist"
                }
                if let descCell = self.descCell.descriptionTextView {
                    if descCell.textColor != .lightGray {
                        self.playlist?.descriptionText = descCell.text
                    } else {
                        self.playlist?.descriptionText = nil
                    }
                }
            }
        } else {
            playlist?.games.removeAll()
            playlist?.games.append(contentsOf: self.games)
            if self.titleCell.titleTextView?.textColor != .lightGray {
                playlist?.name = self.titleCell.titleTextView?.text
            } else {
                playlist?.name = "Untitled Playlist"
            }
            if let descCell = self.descCell.descriptionTextView {
                if descCell.textColor != .lightGray {
                    playlist?.descriptionText = descCell.text
                } else {
                    playlist?.descriptionText = nil
                }
            }
        }
    }
    
    //Done or Edit
    @IBAction func rightTapped(sender: UIBarButtonItem) {
        self.titleCell.titleTextView?.resignFirstResponder()
        self.descCell.descriptionTextView?.resignFirstResponder()
        
        self.navigationController?.navigationBar.tintColor = .white
        if self._playlistState == .default {
            self._playlistState = .editing
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightTapped))
            let newLeftButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(leftTapped))
            self.navigationItem.setRightBarButton(newRightButton, animated: true)
            self.navigationItem.setLeftBarButton(newLeftButton, animated: true)
            self.titleCell.isEditable = true
            self.descCell.isEditable = true
            self.imagesLoaded = 0
            self.reloadDataWithCrossDissolve()
            self.tableView.tableFooterView = UIView(frame: .zero)
            self.tableView.setEditing(true, animated: false)
        } else if self._playlistState == .editing {
            self.saveCurrentState(playlist: nil)
            self.playlistFooterView.update(count: self.games.count)
            var percent = 0
            for game in self.games {
                percent += game.progress
            }
            percent /= self.games.count == 0 ? 1 : self.games.count
            self.playlistFooterView.update(percent: percent)
            self.playlistFooterView.showButton = self.games.count == 0
            if self.playlistImageSource != .custom {
                self.updatePlaylistImage()
            }
            self._playlistState = .default
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(rightTapped))
            self.navigationItem.setRightBarButton(newRightButton, animated: true)
            self.navigationItem.setLeftBarButton(nil, animated: true)
            self.titleCell.isEditable = false
            self.descCell.isEditable = false
            self.tableView.tableFooterView = self.playlistFooterView.view
            self.imagesLoaded = 0
            self.reloadDataWithCrossDissolve()
            
            self.tableView.setEditing(false, animated: false)
        } else {
            let newPlaylist = Playlist()
            self.saveCurrentState(playlist: newPlaylist)
            newPlaylist.add()
            self.playlist = newPlaylist
            self.savePlaylistImage()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func addTapped() {
        self.performSegue(withIdentifier: "addToPlaylist", sender: self.playlistFooterView.addButton)

    }
    
    func didChoose(games: List<Game>) {
        self.games += games.map{$0}
        self.imagesLoaded = 0
        if _playlistState == .default {
            self.saveCurrentState(playlist: nil)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if self._playlistState != .default {
                self.descriptionVisible = true
                return 3
            } else {
                if self.playlist?.descriptionText != nil && self.playlist?.descriptionText != "" {
                    self.descriptionVisible = true
                    return 2
                } else {
                    self.descriptionVisible = false
                    return 1
                }
            }
        } else {
            return self.games.count
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: self.titleReuseIdentifier)!
                for view in cell.contentView.subviews {
                    view.removeFromSuperview()
                }
                cell.contentView.addSubview(self.titleCell.view)
                NSLayoutConstraint(item: self.titleCell.view,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .leading,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                NSLayoutConstraint(item: self.titleCell.view,
                                   attribute: .trailing,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .trailing,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                NSLayoutConstraint(item: self.titleCell.view,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .top,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                NSLayoutConstraint(item: self.titleCell.view,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                if !self.firstLoaded {
                    self.updatePlaylistImage()
                }
                break
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: self.descriptionReuseIdentifier)!
                for view in cell.contentView.subviews {
                    view.removeFromSuperview()
                }
                cell.contentView.addSubview(self.descCell.view)
                NSLayoutConstraint(item: self.descCell.view,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .leading,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                NSLayoutConstraint(item: self.descCell.view,
                                   attribute: .trailing,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .trailing,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                NSLayoutConstraint(item: self.descCell.view,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .top,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                NSLayoutConstraint(item: self.descCell.view,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: cell.contentView,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: 0.0
                    ).isActive = true
                break
            case 2:
                let newCell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PlaylistAddTableCell
                newCell.playlistState = .add
                newCell.delegate = self
                cell = newCell
                if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
                    cell.separatorInset = UIEdgeInsetsMake(0, 47.5, 0, 0)
                }
                if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
                    cell.layoutMargins = .zero
                }
                if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
                    cell.preservesSuperviewLayoutMargins = false
                }
                break
            default:
                cell = UITableViewCell()
            }
        } else {
            
            let gameCell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PlaylistAddTableCell
            if self._playlistState == .default {
                gameCell.playlistState = .default
            } else {
                gameCell.playlistState = .remove
            }
            gameCell.delegate = self
            gameCell.game = self.games[indexPath.row]
            if self._playlistState == .default {
                gameCell.isHandleHidden = true
            }
            let game = self.games[indexPath.row].gameFields!

            if imageCache[game.idNumber] != nil {
                gameCell.set(image: imageCache[game.idNumber]!)
                if indexPath.row < 4 && (self.firstLoaded || self._playlistState == .new) {
                    self.imagesLoaded += 1
                    if self.imagesLoaded == (self.games.count < 4 ? self.games.count : 4) {
                        self.updatePlaylistImage()
                    }
                }
            } else {
                gameCell.cacheCompletionHandler = {
                    (image, error, cacheType, imageUrl) in
                    if image != nil {
                        if cacheType == .none {
                            UIView.transition(with: gameCell.artView!,
                                              duration: 0.5,
                                              options: .transitionCrossDissolve,
                                              animations: {
                                                gameCell.set(image: image!)
                                              },
                                              completion: nil)
                        } else {
                            gameCell.set(image: image!)
                        }
                        self.imageCache[game.idNumber] = image!
                        if indexPath.row < 4 && self.firstLoaded {
                            self.imagesLoaded += 1
                            if self.imagesLoaded == (self.games.count < 4 ? self.games.count : 4) {
                                self.updatePlaylistImage()
                            }
                        }
                    }
                }
                if let smallUrl = game.image?.smallUrl {
                    if let url = URL(string: smallUrl) {
                        gameCell.loadImage(url: url)
                    }
                }
            }
            cell = gameCell
            if indexPath.row == (self.games.count - 1) || self._playlistState == .new{
                self.firstLoaded = true
            }
            var indent: CGFloat = 0.0
            if self._playlistState == .default {
                if indexPath.row < self.games.count - 1 {
                    indent = 67.0
                }
            } else {
                indent = 105.0
            }
            
            if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
                cell.separatorInset = UIEdgeInsetsMake(0, indent, 0, 0)
            }
            if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
                cell.layoutMargins = .zero
            }
            if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
                cell.preservesSuperviewLayoutMargins = false
            }
        }
        cell.selectionStyle = .none

        return cell
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let changeDict = change {
                if let newContentSize = (changeDict[NSKeyValueChangeKey.newKey] as AnyObject).cgSizeValue {
                    self.textView(object as? UITextView, sizeDidChange: newContentSize)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if self.titleTextViewHeight < 150.0 {
                    return 150.0
                } else {
                    return self.titleTextViewHeight
                }
            } else if indexPath.row == 1 {
                if (self.descriptionTextViewHeight + 10) < 75.0 {
                    return 75.0
                } else {
                    return self.descriptionTextViewHeight + 10
                }
            } else {
                return 55.0
            }
        } else {
            return 55.0
        }
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
            var row = 0
            if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
                row = tableView.numberOfRows(inSection: sourceIndexPath.section) - 1
            }
            return IndexPath(row: row, section: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath;
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 || (indexPath.section == 0 && indexPath.row == 2) {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let game = self.games.remove(at: sourceIndexPath.row)
        self.games.insert(game, at: destinationIndexPath.row)
        self.imagesLoaded = 0
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 1 {
            return .delete
        } else if indexPath.section == 0 && indexPath.row == 2 {
            return .insert
        }
        return .none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 2 {
            self.performSegue(withIdentifier: "addToPlaylist", sender: tableView.cellForRow(at: indexPath))
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addToPlaylist" {
            let newNavController = segue.destination as! UINavigationController
            let addToPlaylistViewController = newNavController.topViewController as! AddToPlaylistViewController
            addToPlaylistViewController.delegate = self
        }
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "addToPlaylist", sender: sender)
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        return cellSnapshot
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //self.tableView.beginUpdates()
            self.games.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            //self.tableView.endUpdates()
            self.imagesLoaded = 0
            
        } else if editingStyle == .insert {
            self.performSegue(withIdentifier: "addToPlaylist", sender: tableView.cellForRow(at: indexPath))
        }
    }
    
    func textView(_ textView: UITextView?, sizeDidChange size: CGSize) {
        if self.didEditField {
            if textView == self.titleCell.titleTextView {
                self.titleTextViewHeight = size.height
            } else if textView == self.descCell.descriptionTextView {
                self.descriptionTextViewHeight = size.height
            }
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.didEditField = false
        }
    }
    
    func invalidateEditField() {
        self.didEditField = false
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.textColor == .lightGray {
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText = textView.text as NSString
        let updatedText = currentText.replacingCharacters(in: range, with: text)
        
        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            if textView == self.titleCell.titleTextView {
                textView.text = "Playlist Name"
            } else if textView == self.descCell.descriptionTextView {
                textView.text = "Description"
            }
            textView.textColor = UIColor.lightGray
            
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            
            return false
        }
            
            // Else if the text view's placeholder is showing and the
            // length of the replacement string is greater than 0, clear
            // the text view and set its color to black to prepare for
            // the user's entry
        else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        self.didEditField = true
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.invalidateEditField), userInfo: nil, repeats: false)
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
}
