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

protocol PlaylistDetailsViewControllerDelegate {
    func didFinish(vc: PlaylistDetailsViewController, playlist: Playlist)
}

class PlaylistDetailsViewController: UITableViewController {
    
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
    
    var delegate: PlaylistDetailsViewControllerDelegate?
    
    var imagesLoaded = 0
    
    var didPickImage = false

    var titleInit = false
    var descriptionInit = false
    var addInit = false
    
    var descriptionVisible = false
    
    var isDismissing = false
    
    var shouldUpdateImage = true
    
    enum ImageSource {
        case custom
        case loaded
        case generated
        case none
    }
    
    var playlistImageSource: ImageSource = .none
    
    var didEditField = false
    
    var isFavourites = false
    
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
        } else if self.isFavourites {
            self.firstLoaded = true
            self.navigationItem.setRightBarButton(nil, animated: false)
            self.loadPlaylistImage()
            self.updatePlaylistImage()
        } else {
            if self.playlist != nil {
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
        } else if self.isFavourites {
            self.titleCell.titleString = "Favourites"
            self.titleCell.isEditable = false
            self.descCell.descriptionString = ""
            self.descCell.isEditable = false
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
        toastOverlay.view.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
        toastOverlay.view.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
        toastOverlay.view.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
    }
    
    func refreshTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func reloadDataWithCrossDissolve() {
        UIView.transition(with: self.tableView, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: { _ in
            if self._playlistState == .default {
                self.hideCamera()
            } else {
                self.showCamera()
            }
        })
    }
    
    func refreshSection(_ set: IndexSet) {
        DispatchQueue.main.async {
            self.tableView.reloadSections(set, with: .none)
        }
    }
    
    func updatePlaylistImage() {
        if self.firstLoaded && self.playlistImageSource != .custom {
            // Find first 4 unique ids
            var ids: [Int] = []
            for game in self.games {
                if !ids.contains(game.gameFields!.idNumber) {
                    ids.append(game.gameFields!.idNumber)
                }
                if ids.count > 3 {
                    break
                }
            }
            switch ids.count {
            case 0:
                // reset to default
                self.playlistImage = nil
                self.titleCell.artImage = nil
                self.titleCell.hideImage()
                return
            case 1:
                self.playlistImage = self.imageCache[ids[0]]
                break
            case 2:
                if let image1 = self.imageCache[ids[0]],
                   let image2 = self.imageCache[ids[1]] {
                    self.playlistImage = self.stitch(images: [image1, image2], isVertical: false)
                }
                break
            case 3:
                if let image1 = self.imageCache[ids[0]],
                   let image2 = self.imageCache[ids[1]],
                   let image3 = self.imageCache[ids[2]] {
                    let intermediate   = self.stitch(images: [image1, image2], isVertical: false)
                    self.playlistImage = self.stitch(images: [intermediate, image3], isVertical: true)
                }
                break
            default:
                if let image1 = self.imageCache[ids[0]],
                   let image2 = self.imageCache[ids[1]],
                   let image3 = self.imageCache[ids[2]],
                   let image4 = self.imageCache[ids[3]] {
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
        self.shouldUpdateImage = false
    }
    
    func savePlaylistImage() {
        var filename: URL
        if self.isFavourites {
            filename = Util.getPlaylistImagesDirectory().appendingPathComponent("favourites.png")
        } else {
            filename = Util.getPlaylistImagesDirectory().appendingPathComponent("\(self.playlist!.uuid).png")
        }
        if self.playlistImage != nil {
            let data = self.playlistImage!.pngData()
            try? data?.write(to: filename)
        } else {
            try? FileManager.default.removeItem(at: filename)
        }
    }
    
    func loadPlaylistImage() {
        var filename: URL
        if self.isFavourites {
            filename = Util.getPlaylistImagesDirectory().appendingPathComponent("favourites.png")
        } else {
            filename = Util.getPlaylistImagesDirectory().appendingPathComponent("\(self.playlist!.uuid).png")
        }
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
                totalSize = CGSize(width: maxSize.width  * (CGFloat)(images.count), height: maxSize.height)
            }
            UIGraphicsBeginImageContext(totalSize)
            for image in images {
                var croppedImage: UIImage?
                let imageHeight = image.size.height
                let imageWidth = image.size.width
                if isVertical {
                    if imageWidth < maxSize.width {
                        croppedImage = self.image(with: image, scaledTo: maxSize.width / imageWidth)
                        croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                    }
                    if croppedImage != nil {
                        
                        if (maxSize.width / imageWidth) * imageHeight < maxSize.height {
                            croppedImage = self.image(with: croppedImage!, scaledTo: maxSize.height / croppedImage!.size.height)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    } else {
                        if imageHeight < maxSize.height {
                            croppedImage = self.image(with: image, scaledTo: maxSize.height / imageHeight)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    }
                } else {
                    if imageHeight < maxSize.height {
                        croppedImage = self.image(with: image, scaledTo: maxSize.height / imageHeight)
                        croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                    }
                    if croppedImage != nil {
                        if (maxSize.height / imageHeight) * imageWidth < maxSize.width {
                            croppedImage = self.image(with: croppedImage!, scaledTo: maxSize.width / croppedImage!.size.width)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    } else {
                        if imageWidth < maxSize.width {
                            croppedImage = self.image(with: image, scaledTo: maxSize.width / imageWidth)
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
        let xOffset: CGFloat = (image.size.width - width) / 2.0
        
        let rect: CGRect = CGRect(x: xOffset, y: 0, width: width, height: height)
        
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
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
    
    func showCamera() {
        self.titleCell.showCamera()
    }
    
    func hideCamera() {
        self.titleCell.hideCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isFavourites {
            autoreleasepool {
                let realm = try! Realm()
                self.games.removeAll()
                let games = realm.objects(Game.self).filter("favourite = true")
                if games.count == 0 {
                    self.navigationController?.popViewController(animated: false)
                    return
                }
                self.games.append(objectsIn: games)
            }
        }
        
        if !self.didPickImage {
            if self._playlistState == .default {
                if let playlist = self.playlist {
                    self.games.removeAll()
                    self.games.append(objectsIn: playlist.games)
                }
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
        }
        self.didPickImage = false
        self.imagesLoaded = 0
        self.tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isMovingFromParent {
            self.titleCell.titleTextView?.removeObserver(self, forKeyPath: "contentSize")
            self.descCell.descriptionTextView?.removeObserver(self, forKeyPath: "contentSize")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.imageCache = [:]
    }
    
    func takePhoto(action: UIAlertAction) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhoto(action: UIAlertAction) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func handleFirstDelete(sender: UIAlertAction) {
        let actions = UIAlertController(title: "Delete from Game Library", message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Playlist", style: .destructive, handler: self.handleSecondDelete)
        actions.addAction(deleteAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actions.popoverPresentationController?.sourceView = self.titleCell.moreButton
        actions.popoverPresentationController?.sourceRect = self.titleCell.moreButton!.bounds
        self.present(actions, animated: true, completion: nil)
    }
    
    func handleSecondDelete(sender: UIAlertAction) {
        let uuid = self.playlist!.uuid
        self.playlist?.delete()
        
        let filename = Util.getPlaylistImagesDirectory().appendingPathComponent("\(uuid).png")
        
        let fileManager = FileManager.default
                
        do {
            try fileManager.removeItem(at: filename)
        }
        catch {
            NSLog("Could not delete \(filename)")
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func handleAddToPlaylist(sender: UIAlertAction) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistNavigation") as! UINavigationController
        let playlistVc = vc.viewControllers.first as! PlaylistViewController
        playlistVc.addingGames = Array(self.games)
        playlistVc.isAddingGames = true
        playlistVc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func handlePlayNext(sender: UIAlertAction) {
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "play_next_large"), title: "Added to Queue", description: "We'll play this next.")
        autoreleasepool {
            let realm = try! Realm()
            let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
            if upNextPlaylist != nil {
                let currentGames = List<Game>()
                for game in self.games {
                    var isNowPlaying = false
                    if let linkedPlaylists = game.linkedPlaylists {
                        for playlist in linkedPlaylists {
                            if playlist.isNowPlaying || playlist.isUpNext {
                                isNowPlaying = true
                                break
                            }
                        }
                    }
                    if !isNowPlaying {
                        currentGames.append(game)
                    }
                }
                currentGames.append(objectsIn: upNextPlaylist!.games)
                upNextPlaylist!.update {
                    upNextPlaylist?.games.removeAll()
                    upNextPlaylist?.games.append(objectsIn: currentGames)
                }
            }
        }
    }
    
    func handlePlayLater(sender: UIAlertAction) {
        self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_queue_large"), title: "Added to Queue", description: nil)

        autoreleasepool {
            let realm = try! Realm()
            let upNextPlaylist = realm.objects(Playlist.self).filter("isUpNext = true").first
            if upNextPlaylist != nil {
                var currentGames = Array(upNextPlaylist!.games)
                for game in self.games {
                    var isNowPlaying = false
                    if let linkedPlaylists = game.linkedPlaylists {
                        for playlist in linkedPlaylists {
                            if playlist.isNowPlaying || playlist.isUpNext {
                                isNowPlaying = true
                                break
                            }
                        }
                    }
                    if !isNowPlaying {
                        currentGames.append(game)
                    }
                }
                upNextPlaylist!.update {
                    upNextPlaylist?.games.removeAll()
                    upNextPlaylist?.games.append(objectsIn: currentGames)
                }
            }
        }
    }
    
    //Cancel or back
    @objc func leftTapped(sender: UIBarButtonItem) {
        self.titleCell.titleTextView?.resignFirstResponder()
        self.descCell.descriptionTextView?.resignFirstResponder()
        if self._playlistState == .new {
            self.dismiss(animated: true, completion: nil)
        } else if self._playlistState == .editing {
            self._playlistState = .default
            self.loadPlaylistImage()
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(rightTapped))
            self.navigationItem.setRightBarButton(newRightButton, animated: true)
            self.navigationItem.setLeftBarButton(nil, animated: true)
            self.tableView.tableFooterView = self.playlistFooterView.view
            self.tableView.setEditing(false, animated: false)
            self.games.removeAll()
            self.games.append(objectsIn: self.playlist!.games)
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
                self.playlist?.games.append(objectsIn: self.games)
                if self.titleCell.titleTextView?.textColor != .lightGray {
                    self.playlist?.name = self.titleCell.titleTextView?.text
                    self.titleCell.titleLabel?.text = self.titleCell.titleTextView?.text
                } else {
                    self.playlist?.name = "Untitled Playlist"
                }
                if self.playlistImageSource == .custom {
                    self.playlist?.imageUrl = "custom"
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
            playlist?.games.append(objectsIn: self.games)
            if self.titleCell.titleTextView?.textColor != .lightGray {
                playlist?.name = self.titleCell.titleTextView?.text
            } else {
                playlist?.name = "Untitled Playlist"
            }
            if self.playlistImageSource == .custom {
                self.playlist?.imageUrl = "custom"
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
            if self.isFavourites {
                self.firstLoaded = true
            }
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
            self.updatePlaylistImage()
            self.savePlaylistImage()
            
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
            self.firstLoaded = true
            if self.playlistImageSource != .custom {
                self.updatePlaylistImage()
            } else {
                newPlaylist.update {
                    newPlaylist.imageUrl = "custom"
                }
            }
            self.savePlaylistImage()
            self.delegate?.didFinish(vc: self, playlist: newPlaylist)
        }
    }
    
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
                self.titleCell.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor).isActive = true
                self.titleCell.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor).isActive = true
                self.titleCell.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
                self.titleCell.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true

                if self.shouldUpdateImage {
                    self.updatePlaylistImage()
                }
                if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
                    cell.separatorInset = UIEdgeInsets.init(top: 0, left: 15.0, bottom: 0, right: 0)
                }
                if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
                    cell.layoutMargins = .zero
                }
                if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
                    cell.preservesSuperviewLayoutMargins = false
                }
                
                if self._playlistState == .new || self._playlistState == .editing {
                    self.titleCell.moreButton?.isHidden = true
                } else {
                    self.titleCell.moreButton?.isHidden = false
                }
                break
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: self.descriptionReuseIdentifier)!
                for view in cell.contentView.subviews {
                    view.removeFromSuperview()
                }
                cell.contentView.addSubview(self.descCell.view)
                self.descCell.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor).isActive = true
                self.descCell.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor).isActive = true
                self.descCell.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
                self.descCell.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true

                if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
                    cell.separatorInset = UIEdgeInsets.init(top: 0, left: 15.0, bottom: 0, right: 0)
                }
                if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
                    cell.layoutMargins = .zero
                }
                if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
                    cell.preservesSuperviewLayoutMargins = false
                }
                break
            case 2:
                let newCell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PlaylistAddTableCell
                newCell.playlistState = .add
                cell = newCell
                if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
                    cell.separatorInset = UIEdgeInsets.init(top: 0, left: 47.5, bottom: 0, right: 0)
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
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            
            let gameCell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PlaylistAddTableCell
            if self._playlistState == .default {
                gameCell.playlistState = .default
            } else {
                gameCell.playlistState = .remove
            }
            gameCell.game = self.games[indexPath.row]
            if self._playlistState == .default {
                gameCell.isHandleHidden = true
            }
            let game = self.games[indexPath.row].gameFields!

            if imageCache[game.idNumber] != nil {
                gameCell.set(image: imageCache[game.idNumber]!)
                if indexPath.row < 4 && (self.firstLoaded || self._playlistState == .new) {
                    self.imagesLoaded += 1
                    if self.imagesLoaded == (self.games.count < 4 ? self.games.count : 4) && self.playlistImageSource != .custom {
                        self.updatePlaylistImage()
                    }
                }
            } else {
                gameCell.cacheCompletionHandler = {
                    result in
                    switch result {
                    case .success(let value):
                        if value.cacheType == .none || value.cacheType == .disk {
                            UIView.transition(with: gameCell.artView!,
                                              duration: 0.5,
                                              options: .transitionCrossDissolve,
                                              animations: {
                                                gameCell.set(image: value.image)
                            },
                                              completion: nil)
                        } else {
                            gameCell.set(image: value.image)
                        }
                        self.imageCache[game.idNumber] = value.image
                        if indexPath.row < 4 && self.firstLoaded {
                            self.imagesLoaded += 1
                            if self.imagesLoaded == (self.games.count < 4 ? self.games.count : 4) && self.playlistImageSource != .custom {
                                self.updatePlaylistImage()
                            }
                        }
                    case .failure(let error):
                        NSLog("Error: \(error)")
                    }
                }
                if let smallUrl = game.image?.smallUrl {
                    if let url = URL(string: smallUrl) {
                        gameCell.loadImage(url: url)
                    }
                }
            }
            cell = gameCell
            if indexPath.row == (self.games.count - 1) || indexPath.row == 4 || self._playlistState == .new {
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
                cell.separatorInset = UIEdgeInsets.init(top: 0, left: indent, bottom: 0, right: 0)
            }
            if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
                cell.layoutMargins = .zero
            }
            if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
                cell.preservesSuperviewLayoutMargins = false
            }
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            
        }

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
        if (indexPath.section == 1 && !self.isFavourites) || (indexPath.section == 0 && indexPath.row == 2){
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 && !self.isFavourites {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let game = self.games[sourceIndexPath.row]
        self.games.remove(at: sourceIndexPath.row)
        self.games.insert(game, at: destinationIndexPath.row)
        self.imagesLoaded = 0
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 1 && !self.isFavourites {
            return .delete
        } else if indexPath.section == 0 && indexPath.row == 2 {
            return .insert
        }
        return .none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 2 {
            self.performSegue(withIdentifier: "addToPlaylist", sender: tableView.cellForRow(at: indexPath))
        } else if indexPath.section == 1 && self._playlistState == .default {
            self.performSegue(withIdentifier: "playlist_show_game", sender: tableView.cellForRow(at: indexPath))
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addToPlaylist" {
            let newNavController = segue.destination as! UINavigationController
            let addToPlaylistViewController = newNavController.topViewController as! AddToPlaylistViewController
            addToPlaylistViewController.delegate = self
        } else if segue.identifier == "playlist_show_game" {
            if let cell = sender as? UITableViewCell {
                let i = (self.tableView?.indexPath(for: cell)?.row)!
                let vc = segue.destination as! GameDetailsViewController

                vc.gameField = self.games[i].gameFields
                vc.game = self.games[i]
                vc.state = .inLibrary
                vc.showAddButton = false
                vc.hideStats = false
            }
        }
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        return cellSnapshot
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.games.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.imagesLoaded = 0
            if self._playlistState == .default {
                self.saveCurrentState(playlist: nil)
                if self.playlistImageSource != .custom {
                    self.updatePlaylistImage()
                }
            }
            self.playlistFooterView.update(count: self.games.count)
            var percent = 0
            for game in self.games {
                percent += game.progress
            }
            percent /= self.games.count == 0 ? 1 : self.games.count
            self.playlistFooterView.update(percent: percent)
        } else if editingStyle == .insert {
            self.performSegue(withIdentifier: "addToPlaylist", sender: tableView.cellForRow(at: indexPath))
        }
    }
    
    @objc func invalidateEditField() {
        self.didEditField = false
    }
}

extension PlaylistDetailsViewController: UITextViewDelegate {
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

extension PlaylistDetailsViewController: PlaylistTitleCellDelegate {
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
        if !self.isFavourites {
            actions.addAction(deleteAction)
        }
        if self.games.count > 0 {
            actions.addAction(addToAction)
            actions.addAction(playNextAction)
            actions.addAction(queueAction)
        }
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actions.popoverPresentationController?.sourceView = self.titleCell.moreButton
        actions.popoverPresentationController?.sourceRect = self.titleCell.moreButton!.bounds
        self.present(actions, animated: true, completion: nil)
    }
    
    func artTapped(sender: UITapGestureRecognizer) {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takeAction = UIAlertAction(title: "Take Photo", style: .default, handler: self.takePhoto)
        let chooseAction = UIAlertAction(title: "Choose Photo", style: .default, handler: self.choosePhoto)
        
        actions.addAction(takeAction)
        actions.addAction(chooseAction)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        actions.popoverPresentationController?.sourceView = self.titleCell.artView
        actions.popoverPresentationController?.sourceRect = self.titleCell.artView!.bounds
        
        self.present(actions, animated: true, completion: nil)
    }
}

extension PlaylistDetailsViewController: AddToPlaylistViewControllerDelegate {
    func didChoose(games: List<Game>) {
        self.games.append(objectsIn: games)
        self.imagesLoaded = 0
        if self.playlistState == .default {
            self.saveCurrentState(playlist: nil)
        }
    }
    
    func dismissView(_ vc: AddToPlaylistViewController) {
        self.isDismissing = true
        vc.dismiss(animated: true, completion: nil)
    }
}

extension PlaylistDetailsViewController: PlaylistFooterDelegate {
    func addTapped() {
        self.performSegue(withIdentifier: "addToPlaylist", sender: self.playlistFooterView.addButton)
    }
}

extension PlaylistDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.didPickImage = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let editedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            self.playlistImage = editedImage
            self.playlistImageSource = .custom
            self.titleCell.artImage = editedImage
            self.titleCell.showImage()
        } else if let originalImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            self.playlistImage = originalImage
            self.playlistImageSource = .custom
            self.titleCell.artImage = originalImage
            self.titleCell.showImage()
        }
        self.didPickImage = true
        picker.dismiss(animated: true, completion: nil)
    }
}

extension PlaylistDetailsViewController: PlaylistViewControllerDelegate {
    func chosePlaylist(vc: PlaylistViewController, playlist: Playlist, games: [Game], isNew: Bool) {
        if !isNew {
            playlist.update {
                playlist.games.append(objectsIn: games)
            }
        }
        vc.presentingViewController?.dismiss(animated: true, completion: {
            var descString: String
            if games.count == 1 {
                descString = "Added 1 game to \"\(playlist.name!)\"."
            } else {
                descString = "Added \(games.count) games to \"\(playlist.name!)\"."
            }
            self.toastOverlay.show(withIcon: #imageLiteral(resourceName: "add_to_playlist_large"), title: "Added to Playlist", description: descString)
        })
        vc.navigationController?.dismiss(animated: true, completion: nil)
        self.tableView.reloadData()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
