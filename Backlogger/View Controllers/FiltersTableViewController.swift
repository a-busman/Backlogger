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

class FiltersTableViewController: UITableViewController {
    @IBOutlet weak var completeSwitch:   UISwitch?
    @IBOutlet weak var favoriteSwitch:   UISwitch?
    @IBOutlet weak var progressSlider:   UISlider?
    @IBOutlet weak var progressLabel:    UILabel?
    @IBOutlet weak var ratingLabel:      UILabel?
    @IBOutlet weak var progressSegments: UISegmentedControl?
    @IBOutlet weak var ratingSegments:   UISegmentedControl?
    @IBOutlet weak var starStackView:    UIStackView?
    
    enum FilterCriteria: Int {
        case less    = 0
        case equal   = 1
        case greater = 2
    }
    
    private var complete:         Bool?
    private var favorite:         Bool?
    private var progress:         Int?
    private var rating:           Int?
    private var platforms:        [Platform]?
    private var genres:           [Genre]?
    private var progressCriteria: FilterCriteria?
    private var ratingCriteria:   FilterCriteria?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Util.isICloudContainerAvailable {
            Zephyr.sync()
        }
        self.complete = UserDefaults.standard.value(forKey: "filterComplete") as? Bool
        self.favorite = UserDefaults.standard.value(forKey: "filterFavorite") as? Bool
        self.progress = UserDefaults.standard.value(forKey: "filterProgress") as? Int
        self.rating = UserDefaults.standard.value(forKey: "filterRating") as? Int
        self.progressCriteria = UserDefaults.standard.value(forKey: "filterProgressCriteria") as? FilterCriteria
        self.ratingCriteria = UserDefaults.standard.value(forKey: "filterRatingCriteria") as? FilterCriteria
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateFields()
        self.navigationController?.navigationBar.setNeedsLayout()
    }
    
    func updateFields() {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) {
            if let complete = self.complete {
                self.updateCellCheck(cell, checked: true)
                self.completeSwitch?.setOn(complete, animated: false)
            } else {
                self.updateCellCheck(cell, checked: false)
                self.completeSwitch?.setOn(false, animated: false)
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) {
            if let favorite = self.favorite {
                self.updateCellCheck(cell, checked: true)
                self.favoriteSwitch?.setOn(favorite, animated: false)
            } else {
                self.updateCellCheck(cell, checked: false)
                self.favoriteSwitch?.setOn(false, animated: false)
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 1)) {
            if let progress = self.progress {
                self.updateCellCheck(cell, checked: true)
                self.progressLabel?.text = "\(progress)%"
                self.progressSlider?.setValue(Float(progress), animated: false)
                if let progressCriteria = self.progressCriteria {
                    self.progressSegments?.selectedSegmentIndex = progressCriteria.rawValue
                }
            } else {
                self.updateCellCheck(cell, checked: false)
                self.progressLabel?.text = "50%"
                self.progressSlider?.setValue(50, animated: false)
                self.progressSegments?.selectedSegmentIndex = 0
            }
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 1)) {
            if let rating = self.rating {
                self.updateCellCheck(cell, checked: true)
                self.rating! -= 1
                self.updateStars(rating - 1)
                if let ratingCriteria = self.ratingCriteria {
                    self.ratingSegments?.selectedSegmentIndex = ratingCriteria.rawValue
                }
            } else {
                self.updateCellCheck(cell, checked: false)
                self.updateStars(-1)
                self.ratingSegments?.selectedSegmentIndex = 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: NSLocalizedString("Clear", comment: "Clear"), handler: { (action, view, completionHandler) in
            tableView.setEditing(false, animated: true)
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    self.platforms = nil
                    UserDefaults.standard.removeObject(forKey: "filterPlatforms")
                case 1:
                    self.genres = nil
                    UserDefaults.standard.removeObject(forKey: "filterGenres")
                default:
                    break
                }
            case 1:
                switch indexPath.row {
                case 0:
                    self.complete = nil
                    self.completeSwitch?.setOn(false, animated: true)
                    UserDefaults.standard.removeObject(forKey: "filterComplete")
                case 1:
                    self.favorite = nil
                    self.favoriteSwitch?.setOn(false, animated: true)
                    UserDefaults.standard.removeObject(forKey: "filterFavorite")
                case 2:
                    self.progress = nil
                    self.progressSlider?.setValue(50, animated: true)
                    self.progressSegments?.selectedSegmentIndex = 0
                    self.progressLabel?.text = "50%"
                    UserDefaults.standard.removeObject(forKey: "filterProgress")
                case 3:
                    self.rating = nil
                    self.updateStars(-1)
                    self.ratingSegments?.selectedSegmentIndex = 0
                    self.ratingLabel?.text = "0"
                    UserDefaults.standard.removeObject(forKey: "filterRating")
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
        action.backgroundColor = UIColor(named: "App")
        let config = UISwipeActionsConfiguration(actions: [action])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.setSelected(false, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }
    
    @IBAction func completeToggled(_ sender: UISwitch) {
        self.complete = sender.isOn
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) {
            self.updateCellCheck(cell, checked: true)
            UserDefaults.standard.set(self.complete, forKey: "filterComplete")
        }
    }
    
    @IBAction func favoriteToggled(_ sender: UISwitch) {
        self.favorite = sender.isOn
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) {
            self.updateCellCheck(cell, checked: true)
            UserDefaults.standard.set(self.favorite, forKey: "filterFavorite")
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
        self.progress = newValue
        
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 1)) {
            self.updateCellCheck(cell, checked: true)
        }
    }
    
    @IBAction func ratingHandler(sender: UIGestureRecognizer) {
        let location = sender.location(in: self.starStackView!)
        let starIndex = Int(location.x / ((self.starStackView?.bounds.width)! / 5.0))
        self.updateStars(starIndex)
        UserDefaults.standard.set(starIndex + 1, forKey: "filterRating")
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 1)) {
            self.updateCellCheck(cell, checked: true)
        }
    }
    
    private func updateStars(_ index: Int) {
        if (self.rating != index + 1) && (index + 1 <= 5 && index + 1 >= 0)  {
            UISelectionFeedbackGenerator().selectionChanged()
            self.ratingLabel?.text = "\(index + 1)"
            self.rating = index + 1
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
    
    private func updateCellCheck(_ cell: UITableViewCell, checked: Bool) {
        guard let checkImage = cell.contentView.viewWithTag(1) else { return }
        checkImage.isHidden = !checked
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
