//
//  FiltersTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/5/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit

class FiltersTableViewController: UITableViewController {
    @IBOutlet weak var completeSwitch: UISwitch?
    @IBOutlet weak var favoriteSwitch: UISwitch?
    @IBOutlet weak var progressLabel:  UILabel?
    
    private var expanded = [false, false, false, false]

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
        
    }
    
    @IBAction func favoriteToggled(_ sender: UISwitch) {
        
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
