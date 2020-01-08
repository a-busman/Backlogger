//
//  FiltersTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/5/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

class FiltersTableViewController: UITableViewController {
    @IBOutlet weak var completeSwitch: UISwitch?
    @IBOutlet weak var favoriteSwitch: UISwitch?
    @IBOutlet weak var progressLabel:  UILabel?
    @IBOutlet weak var starStackView: UIStackView?
    
    private var complete: Bool?
    private var favorite: Bool?
    private var progress: Int?
    private var rating: Int?
    private var platforms: [Platform]?
    private var genres: [Genre]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setNeedsLayout()
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: NSLocalizedString("Clear", comment: "Clear"), handler: { (action, view, completionHandler) in
            tableView.setEditing(false, animated: true)
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    self.platforms = nil
                case 1:
                    self.genres = nil
                default:
                    break
                }
            case 1:
                switch indexPath.row {
                case 0:
                    self.complete = nil
                    self.completeSwitch?.setOn(false, animated: true)
                case 1:
                    self.favorite = nil
                    self.favoriteSwitch?.setOn(false, animated: true)
                case 2:
                    self.progress = nil
                case 3:
                    self.rating = nil
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
        }
    }
    
    @IBAction func favoriteToggled(_ sender: UISwitch) {
        self.favorite = sender.isOn
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) {
            self.updateCellCheck(cell, checked: true)
        }
    }
    
    @IBAction func handleSlider(_ sender: UISlider) {
        let remainder = Int(sender.value) % 5
        let generator = UISelectionFeedbackGenerator()
        var newValue: Int = 0
        if remainder < 2 {
            newValue = Int(sender.value) - remainder
        } else {
            newValue = Int(sender.value) + 5 - remainder
        }
        sender.value = Float(newValue)
        if let label = self.progressLabel, label.text != "\(newValue)%" {
            label.text = "\(newValue)%"
            generator.selectionChanged()
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
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 1)) {
            self.updateCellCheck(cell, checked: true)
        }
    }
    
    private func updateStars(_ index: Int) {
        if self.rating != index {
            UISelectionFeedbackGenerator().selectionChanged()
            self.rating = index
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
