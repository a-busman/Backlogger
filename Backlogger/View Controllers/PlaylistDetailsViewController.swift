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

class PlaylistDetailsViewController: UITableViewController, UITextViewDelegate, PlaylistAddTableCellViewDelegate, AddToPlaylistViewControllerDelegate, PlaylistFooterDelegate {
    
    @IBOutlet weak var noGamesView: UIView?
    
    let cellReuseIdentifier = "playlist_detail_cell"
    var playlistTitleView = PlaylistTitleView()
    var playlistDescriptionView = PlaylistDescriptionView()
    var playlistAddTableView = PlaylistAddTableCellView()
    var playlistFooterView = PlaylistFooter()
    
    var playlistTableViews: [PlaylistAddTableCellView] = []
    
    var titleTextViewHeight: CGFloat = 0.0
    var descriptionTextViewHeight: CGFloat = 0.0
    
    var playlist: Playlist?
    
    var games = List<Game>()
    
    var imageCache: [Int: UIImage] = [:]
    
    var selectedRow = -1
    
    var movingIndexPath: IndexPath?
    
    var playlistImage: UIImage?
    
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
        self.playlistTitleView.titleDelegate = self
        self.playlistTitleView.observer = self
        self.playlistDescriptionView.descriptionDelegate = self
        self.playlistDescriptionView.observer = self
        self.playlistAddTableView.playlistState = .add
        self.playlistAddTableView.delegate = self
        self.tableView.allowsSelectionDuringEditing = true
        if self._playlistState == .new {
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightTapped))
            let newLeftButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(leftTapped))
            self.navigationController?.navigationBar.topItem?.rightBarButtonItem = newRightButton
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = newLeftButton
            self.tableView.setEditing(true, animated: false)
            self.playlistTitleView.isEditable = true
            self.playlistDescriptionView.isEditable = true
            self.navigationItem.title = "New Playlist"
            
        } else {
            if let playlist = self.playlist {
                self.playlistTitleView.titleString = playlist.name ?? ""
                self.playlistDescriptionView.descriptionString = playlist.descriptionText ?? ""
                self.games.append(contentsOf: playlist.games)
                self.loadPlaylistImage()
            }
            self.playlistFooterView.delegate = self
            self.playlistTitleView.isEditable = false
            self.playlistDescriptionView.isEditable = false
        }
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
        switch self.games.count {
        case 0:
            // reset to default
            self.playlistImage = nil
            self.playlistTitleView.image = nil
            self.playlistTitleView.hideImage()
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
        self.playlistTitleView.image = self.playlistImage
        self.savePlaylistImage()
        self.playlistTitleView.showImage()
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
                if image.size.width < maxSize.width {
                    croppedImage = self.image(with: image, scaledTo: maxSize.width)
                    croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
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
    
    func image(with sourceImage: UIImage, scaledTo width: CGFloat) -> UIImage {
        let oldWidth = sourceImage.size.width
        let scaleFactor = width / oldWidth
        
        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
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
            self.tableView.tableFooterView = nil
        }
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController {
            self.playlistTitleView.titleTextView?.removeObserver(self, forKeyPath: "contentSize")
            self.playlistDescriptionView.descriptionTextView?.removeObserver(self, forKeyPath: "contentSize")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.playlistTableViews = []
        self.imageCache = [:]
    }
    
    //Cancel or back
    func leftTapped(sender: UIBarButtonItem) {
        self.playlistTitleView.titleTextView?.resignFirstResponder()
        self.playlistDescriptionView.descriptionTextView?.resignFirstResponder()
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
            self.playlistTableViews = []
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
                if self.playlistTitleView.titleTextView?.textColor != .lightGray {
                    self.playlist?.name = self.playlistTitleView.titleTextView.text
                    self.playlistTitleView.titleLabel.text = self.playlistTitleView.titleTextView.text
                } else {
                    self.playlist?.name = "Untitled Playlist"
                }
                if self.playlistDescriptionView.descriptionTextView?.textColor != .lightGray {
                    self.playlist?.descriptionText = self.playlistDescriptionView.descriptionTextView.text
                }
            }
        } else {
            playlist?.games.removeAll()
            playlist?.games.append(contentsOf: self.games)
            if self.playlistTitleView.titleTextView?.textColor != .lightGray {
                playlist?.name = self.playlistTitleView.titleTextView?.text
            } else {
                playlist?.name = "Untitled Playlist"
            }
            if self.playlistDescriptionView.descriptionTextView?.textColor != .lightGray {
                playlist?.descriptionText = self.playlistDescriptionView.descriptionTextView?.text
            }
        }
    }
    
    //Done or Edit
    @IBAction func rightTapped(sender: UIBarButtonItem) {
        self.playlistTitleView.titleTextView?.resignFirstResponder()
        self.playlistDescriptionView.descriptionTextView?.resignFirstResponder()
        
        self.navigationController?.navigationBar.tintColor = .white
        
        if self._playlistState == .default {
            self._playlistState = .editing
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightTapped))
            let newLeftButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(leftTapped))
            self.navigationItem.setRightBarButton(newRightButton, animated: true)
            self.navigationItem.setLeftBarButton(newLeftButton, animated: true)
            self.playlistTitleView.isEditable = true
            self.playlistDescriptionView.isEditable = true
            self.reloadDataWithCrossDissolve()
            self.tableView.tableFooterView = nil
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
            self._playlistState = .default
            let newRightButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(rightTapped))
            self.navigationItem.setRightBarButton(newRightButton, animated: true)
            self.navigationItem.setLeftBarButton(nil, animated: true)
            self.playlistTitleView.isEditable = false
            self.playlistDescriptionView.isEditable = false
            self.tableView.tableFooterView = self.playlistFooterView.view
            self.reloadDataWithCrossDissolve()
            if self.playlistImageSource != .custom {
                self.updatePlaylistImage()
            }
            self.tableView.setEditing(false, animated: false)
        } else {
            let newPlaylist = Playlist()
            self.saveCurrentState(playlist: newPlaylist)
            newPlaylist.add()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func addTapped() {
        self.performSegue(withIdentifier: "addToPlaylist", sender: self.playlistFooterView.addButton)

    }
    
    func didChoose(games: List<Game>) {
        self.games += games.map{$0}
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
                return 3
            } else {
                if self.playlist?.descriptionText != nil {
                    return 2
                } else {
                    return 1
                }
            }
        } else {
            return self.games.count
        }
        //return 3 + self.games.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /*********************************************************
         * FIXME: If a cell has been deleted by pressing the minus
         * button, then the delete button, when it is reused, the
         * minus button can no longer be pressed for some reason.
         * Creating a new cell each time solves this problem, but
         * then there will be memory issues as cells won't be
         * reused, but instead created each time.
         *********************************************************/
        
        // discarding first reusable cell seems to solve the problem for now.
        _ = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier)
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! TableViewCell
        //let cell = TableViewCell(style: .default, reuseIdentifier: self.cellReuseIdentifier)
        var cellView = UIView()
        if indexPath.section == 0 {
        
            switch indexPath.row {
            case 0:
                cellView = self.playlistTitleView.view
                break
            case 1:
                cellView = self.playlistDescriptionView.view
                break
            case 2:
                cellView = self.playlistAddTableView.view
                break
            default:
                break
            }
        } else {
            var playlistView: PlaylistAddTableCellView?
            if indexPath.row >= self.playlistTableViews.count {
                playlistView = PlaylistAddTableCellView()
                playlistView?.playlistState = .remove
                playlistView?.delegate = self
                playlistView?.game = self.games[indexPath.row]
                if self._playlistState == .default {
                    playlistView?.isHandleHidden = true
                }
                self.playlistTableViews.append(playlistView!)
                let game = self.games[indexPath.row].gameFields!

                if playlistView!.imageSource == .Placeholder {
                    if let image = self.imageCache[game.idNumber] {
                        playlistView?.set(image: image)
                        playlistView?.imageSource = .Downloaded
                    } else {
                        playlistView?.imageUrl = URL(string: game.image!.smallUrl!)
                        playlistView?.cacheCompletionHandler = {
                            (image, error, cacheType, imageUrl) in
                            if image != nil {
                                if cacheType == .none {
                                    UIView.transition(with: playlistView!.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                        playlistView?.set(image: image!)
                                    }, completion: nil)
                                } else {
                                    playlistView?.set(image: image!)
                                }
                                self.imageCache[game.idNumber] = image!
                                if self.playlistImageSource != .custom {
                                    self.updatePlaylistImage()
                                }
                            }
                        }
                    }
                }
            } else {
                playlistView = self.playlistTableViews[indexPath.row]
                if self._playlistState == .default {
                    playlistView?.hideHandle()
                } else {
                    playlistView?.showHandle()
                }
            }

            cellView = playlistView!.view
        }

        cell.selectionStyle = .none

        cellView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(cellView)
        
        NSLayoutConstraint(item: cellView,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .leading,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: cellView,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .trailing,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: cellView,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .top,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
        NSLayoutConstraint(item: cellView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: cell.contentView,
                           attribute: .bottom,
                           multiplier: 1.0,
                           constant: 0.0
            ).isActive = true
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
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        let state = sender.state
        
        let location = sender.location(in: self.tableView)
        var indexPath = tableView.indexPathForRow(at: location)
        self.movingIndexPath = indexPath
        
        struct My {
            static var cellSnapshot : UIView? = nil
        }
        struct Path {
            static var initialIndexPath : IndexPath? = nil
        }
        
        switch state {
        case .began:
            if self.movingIndexPath != nil {
                Path.initialIndexPath = self.movingIndexPath!
                let cell = tableView.cellForRow(at: self.movingIndexPath!)! as UITableViewCell
                My.cellSnapshot  = snapshotOfCell(cell)
                var center = cell.center
                My.cellSnapshot!.center = center
                tableView.addSubview(My.cellSnapshot!)
                cell.alpha = 0.0

                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    center.y = location.y
                    My.cellSnapshot!.center = center
                    
                }, completion: { (finished) -> Void in
                    if finished {
                        cell.isHidden = true
                    }
                })
            }
            break
        case .changed:
            var center = My.cellSnapshot!.center
            center.y = location.y
            My.cellSnapshot!.center = center
            if (indexPath != nil && indexPath != Path.initialIndexPath && indexPath!.section == 1) {
                swap(&self.games[indexPath!.row], &self.games[Path.initialIndexPath!.row])
                swap(&self.playlistTableViews[indexPath!.row], &self.playlistTableViews[Path.initialIndexPath!.row])
                tableView.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                Path.initialIndexPath = indexPath
            }
            
        default:
            let cell = tableView.cellForRow(at: Path.initialIndexPath!)! as UITableViewCell
            cell.isHidden = false
            cell.alpha = 0.0
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                My.cellSnapshot!.center = cell.center
            }, completion: { (finished) -> Void in
                if finished {
                    My.cellSnapshot!.alpha = 0.0
                    cell.alpha = 1.0
                    Path.initialIndexPath = nil
                    My.cellSnapshot!.removeFromSuperview()
                    My.cellSnapshot = nil
                }
            })
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.tableView.beginUpdates()
            self.games.remove(at: indexPath.row)
            self.playlistTableViews.remove(at: indexPath.row)
            //self.tableView.reloadRows(at: [indexPath], with: .automatic)
            //self.refreshSection(NSIndexSet(index: 1) as IndexSet)
            //self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
            //self.tableView.reloadRows(at: [indexPath], with: .automatic)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.tableView.endUpdates()
            if indexPath.row < 4 && self.playlistImageSource != .custom {
                self.updatePlaylistImage()
            }
            //self.tableView.reloadData()
            //_ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.refreshTable), userInfo: nil, repeats: false)
        } else if editingStyle == .insert {
            self.performSegue(withIdentifier: "addToPlaylist", sender: tableView.cellForRow(at: indexPath))
        }
    }
    
    func textView(_ textView: UITextView?, sizeDidChange size: CGSize) {
        if self.didEditField {
            if textView == self.playlistTitleView.titleTextView {
                self.titleTextViewHeight = size.height
            } else if textView == self.playlistDescriptionView.descriptionTextView {
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
            if textView == self.playlistTitleView.titleTextView {
                textView.text = "Playlist Name"
            } else if textView == self.playlistDescriptionView.descriptionTextView {
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
