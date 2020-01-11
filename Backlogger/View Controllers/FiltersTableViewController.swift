//
//  FiltersTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/5/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift
import Zephyr

protocol FiltersTableViewControllerDelegate {
    func didSelectFilters(_ criteria: FiltersTableViewController.FiltersCriteria?, vc: FiltersTableViewController)
    func didDismiss()
}

class FiltersTableViewController: UITableViewController {
    @IBOutlet weak var completeSwitch:   UISwitch?
    @IBOutlet weak var favoriteSwitch:   UISwitch?
    @IBOutlet weak var progressSlider:   UISlider?
    @IBOutlet weak var progressLabel:    UILabel?
    @IBOutlet weak var ratingLabel:      UILabel?
    @IBOutlet weak var progressSegments: UISegmentedControl?
    @IBOutlet weak var ratingSegments:   UISegmentedControl?
    @IBOutlet weak var starStackView:    UIStackView?
    
    struct FiltersCriteria {
        var complete:         Bool?
        var favorite:         Bool?
        var progress:         Int?
        var rating:           Int?
        var platforms:        Set<Int>?
        var genres:           Set<Int>?
        var progressCriteria: FilterCriteria?
        var ratingCriteria:   FilterCriteria?
        
        var isEmpty: Bool {
            get {
                var ret = true
                if  self.complete         != nil ||
                    self.favorite         != nil ||
                    self.progress         != nil ||
                    self.rating           != nil ||
                    self.platforms        != nil ||
                    self.genres           != nil ||
                    self.progressCriteria != nil ||
                    self.ratingCriteria   != nil {
                    ret = false
                }
                return ret
            }
        }
    }
    
    enum FilterCriteria: Int {
        case less    = 0
        case equal   = 1
        case greater = 2
    }
    
    var delegate: FiltersTableViewControllerDelegate?
    
    var criteria: FiltersCriteria?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.criteria == nil {
            self.criteria = type(of: self).getFilters()
        }
    }
    
    class func getFilters() -> FiltersCriteria {
        var criteria = FiltersCriteria()
        if Util.isICloudContainerAvailable {
            Zephyr.sync()
        }
        criteria.complete = UserDefaults.standard.value(forKey: "filterComplete") as? Bool
        criteria.favorite = UserDefaults.standard.value(forKey: "filterFavorite") as? Bool
        criteria.progress = UserDefaults.standard.value(forKey: "filterProgress") as? Int
        criteria.rating = UserDefaults.standard.value(forKey: "filterRating") as? Int
        let progressCriteria = UserDefaults.standard.value(forKey: "filterProgressCriteria") as? Int
        let ratingCriteria = UserDefaults.standard.value(forKey: "filterRatingCriteria") as? Int
        
        if progressCriteria != nil {
            criteria.progressCriteria = FilterCriteria(rawValue: progressCriteria!)
        }
        if ratingCriteria != nil {
            criteria.ratingCriteria = FilterCriteria(rawValue: ratingCriteria!)
        }
        if let platforms = UserDefaults.standard.array(forKey: "filterPlatforms") as? [Int] {
            criteria.platforms = Set(platforms.map{$0})
        }
        if let genres = UserDefaults.standard.array(forKey: "filterGenres") as? [Int] {
            criteria.genres = Set(genres.map{$0})
        }
        return criteria
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateFields()
        self.navigationController?.navigationBar.setNeedsLayout()
    }
    
    func updateFields() {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            if self.criteria?.platforms != nil {
                self.updateCellCheck(cell, checked: true)
            } else {
                self.updateCellCheck(cell, checked: false)
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) {
            if self.criteria?.genres != nil {
                self.updateCellCheck(cell, checked: true)
            } else {
                self.updateCellCheck(cell, checked: false)
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) {
            if let complete = self.criteria?.complete {
                self.updateCellCheck(cell, checked: true)
                self.completeSwitch?.setOn(complete, animated: true)
            } else {
                self.updateCellCheck(cell, checked: false)
                self.completeSwitch?.setOn(false, animated: true)
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) {
            if let favorite = self.criteria?.favorite {
                self.updateCellCheck(cell, checked: true)
                self.favoriteSwitch?.setOn(favorite, animated: true)
            } else {
                self.updateCellCheck(cell, checked: false)
                self.favoriteSwitch?.setOn(false, animated: true)
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 1)) {
            if let progress = self.criteria?.progress {
                self.updateCellCheck(cell, checked: true)
                self.progressLabel?.text = "\(progress)%"
                self.progressSlider?.setValue(Float(progress), animated: true)
                if let progressCriteria = self.criteria?.progressCriteria {
                    self.progressSegments?.selectedSegmentIndex = progressCriteria.rawValue
                }
            } else {
                self.updateCellCheck(cell, checked: false)
                self.progressLabel?.text = "50%"
                self.progressSlider?.setValue(50, animated: true)
                self.progressSegments?.selectedSegmentIndex = 0
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 1)) {
            if let rating = self.criteria?.rating {
                self.updateCellCheck(cell, checked: true)
                self.updateStars(rating - 1)
                if let ratingCriteria = self.criteria?.ratingCriteria {
                    self.ratingSegments?.selectedSegmentIndex = ratingCriteria.rawValue
                }
            } else {
                self.updateCellCheck(cell, checked: false)
                self.updateStars(-1)
                self.ratingSegments?.selectedSegmentIndex = 0
            }
        }
    }
    
    @IBAction func tappedDone(sender: UIBarButtonItem) {
        self.delegate?.didSelectFilters(criteria, vc: self)
    }
    
    @IBAction func tappedClear(sender: UIBarButtonItem) {
        self.criteria?.platforms = nil
        UserDefaults.standard.removeObject(forKey: "filterPlatforms")
        self.criteria?.genres = nil
        UserDefaults.standard.removeObject(forKey: "filterGenres")
        self.criteria?.complete = nil
        UserDefaults.standard.removeObject(forKey: "filterComplete")
        self.criteria?.favorite = nil
        UserDefaults.standard.removeObject(forKey: "filterFavorite")
        self.criteria?.progress = nil
        self.criteria?.progressCriteria = nil
        UserDefaults.standard.removeObject(forKey: "filterProgress")
        UserDefaults.standard.removeObject(forKey: "filterProgressCriteria")
        self.criteria?.rating = nil
        self.criteria?.ratingCriteria = nil
        UserDefaults.standard.removeObject(forKey: "filterRating")
        UserDefaults.standard.removeObject(forKey: "filterRatingCriteria")
        
        self.updateFields()
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: NSLocalizedString("Clear", comment: "Clear"), handler: { (action, view, completionHandler) in
            tableView.setEditing(false, animated: true)
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    self.criteria?.platforms = nil
                    UserDefaults.standard.removeObject(forKey: "filterPlatforms")
                case 1:
                    self.criteria?.genres = nil
                    UserDefaults.standard.removeObject(forKey: "filterGenres")
                default:
                    break
                }
            case 1:
                switch indexPath.row {
                case 0:
                    self.criteria?.complete = nil
                    self.completeSwitch?.setOn(false, animated: true)
                    UserDefaults.standard.removeObject(forKey: "filterComplete")
                case 1:
                    self.criteria?.favorite = nil
                    self.favoriteSwitch?.setOn(false, animated: true)
                    UserDefaults.standard.removeObject(forKey: "filterFavorite")
                case 2:
                    self.criteria?.progress = nil
                    self.criteria?.progressCriteria = nil
                    self.progressSlider?.setValue(50, animated: true)
                    self.progressSegments?.selectedSegmentIndex = 0
                    self.progressLabel?.text = "50%"
                    UserDefaults.standard.removeObject(forKey: "filterProgress")
                    UserDefaults.standard.removeObject(forKey: "filterProgressCriteria")
                case 3:
                    self.criteria?.rating = nil
                    self.criteria?.ratingCriteria = nil
                    self.updateStars(-1)
                    self.ratingSegments?.selectedSegmentIndex = 0
                    self.ratingLabel?.text = "0"
                    UserDefaults.standard.removeObject(forKey: "filterRating")
                    UserDefaults.standard.removeObject(forKey: "filterRatingCriteria")
                default:
                    break
                }
            default:
                break
            }
            if let cell = tableView.cellForRow(at: indexPath) {
                self.updateCellCheck(cell, checked: false)
            }
        })
        action.backgroundColor = UIColor(named: "App-blue")
        let config = UISwipeActionsConfiguration(actions: [action])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.setSelected(false, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @IBAction func completeToggled(_ sender: UISwitch) {
        self.criteria?.complete = sender.isOn
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) {
            self.updateCellCheck(cell, checked: true)
            UserDefaults.standard.set(self.criteria?.complete, forKey: "filterComplete")
        }
    }
    
    @IBAction func favoriteToggled(_ sender: UISwitch) {
        self.criteria?.favorite = sender.isOn
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) {
            self.updateCellCheck(cell, checked: true)
            UserDefaults.standard.set(self.criteria?.favorite, forKey: "filterFavorite")
        }
    }
    
    @IBAction func handleSlider(_ sender: UISlider) {
        let remainder = Int(sender.value) % 5
        var newValue: Int = 0
        if remainder < 2 {
            newValue = Int(sender.value) - remainder
        } else {
            newValue = Int(sender.value) + 5 - remainder
        }
        sender.value = Float(newValue)
        if let label = self.progressLabel, label.text != "\(newValue)%" {
            label.text = "\(newValue)%"
            UISelectionFeedbackGenerator().selectionChanged()
            UserDefaults.standard.set(newValue, forKey: "filterProgress")
        }
        self.criteria?.progress = newValue
        
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 1)) {
            self.updateCellCheck(cell, checked: true)
        }
    }
    
    @IBAction func ratingHandler(sender: UIGestureRecognizer) {
        let location = sender.location(in: self.starStackView!)
        let starIndex = Int(location.x / ((self.starStackView?.bounds.width)! / 5.0))
        self.updateStars(starIndex)
        self.updateRating(starIndex + 1)
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 1)) {
            self.updateCellCheck(cell, checked: true)
        }
    }
    
    @IBAction func segmentHandler(sender: UISegmentedControl) {
        if let progressSegments = self.progressSegments, sender == progressSegments {
            self.criteria?.progressCriteria = FilterCriteria(rawValue: sender.selectedSegmentIndex)
            UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "filterProgressCriteria")
            if self.criteria?.progress == nil {
                self.criteria?.progress = Int(self.progressSlider!.value)
                UserDefaults.standard.set(self.criteria?.progress, forKey: "filterProgress")
            }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 1)) {
                self.updateCellCheck(cell, checked: true)
            }
        } else if let ratingSegments = self.ratingSegments, sender == ratingSegments {
            self.criteria?.ratingCriteria = FilterCriteria(rawValue: sender.selectedSegmentIndex)
            UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "filterRatingCriteria")
            if self.criteria?.rating == nil {
                self.criteria?.rating = 0
                UserDefaults.standard.set(self.criteria?.rating, forKey: "filterRating")
            }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 1)) {
                self.updateCellCheck(cell, checked: true)
            }
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    private func updateStars(_ index: Int) {
        if (index + 1 <= 5 && index + 1 >= 0)  {
            self.ratingLabel?.text = "\(index + 1)"
            for (i, star) in self.starStackView!.arrangedSubviews.enumerated() {
                if let starImage = star as? UIImageView {
                    if index >= i {
                        starImage.image = UIImage(systemName: "star.fill")
                    } else {
                        starImage.image = UIImage(systemName: "star")
                    }
                }
            }
        }
    }
    
    private func updateRating(_ rating: Int) {
        self.criteria?.rating = rating
        UserDefaults.standard.set(rating, forKey: "filterRating")
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    private func updateCellCheck(_ cell: UITableViewCell, checked: Bool) {
        guard let checkImage = cell.contentView.viewWithTag(1) else { return }
        checkImage.isHidden = !checked
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var category: FilterCategoryTableViewController.FilterCategory
        var ids: Set<Int>?
        if segue.identifier == "platform_filter" {
            category = .platforms
            ids = self.criteria?.platforms
        } else if segue.identifier == "genre_filter" {
            category = .genres
            ids = self.criteria?.genres
        } else {
            return
        }
        if let vc = segue.destination as? FilterCategoryTableViewController {
            vc.delegate = self
            vc.filterCategory = category
            vc.filterList = ids ?? Set<Int>()
            vc.navigationItem.title = category.rawValue
        }
    }
}

extension FiltersTableViewController: FilterCategoryDelegate {
    func didSelect(_ ids: Set<Int>, category: FilterCategoryTableViewController.FilterCategory) {
        var key: String?
        if category == .genres {
            self.criteria?.genres = ids.isEmpty ? nil : ids
            key = "filterGenres"
        } else if category == .platforms {
            self.criteria?.platforms = ids.isEmpty ? nil : ids
            key = "filterPlatforms"
        }
        if key != nil {
            if !ids.isEmpty {
                UserDefaults.standard.set(Array(ids), forKey: key!)
            } else {
                UserDefaults.standard.removeObject(forKey: key!)
            }
        }
        //self.updateFields()
    }
}
