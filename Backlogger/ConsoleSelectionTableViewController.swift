//
//  ConsoleSelectionTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 3/12/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

protocol ConsoleSelectionTableViewControllerDelegate {
    func didSelectConsoles(_ consoles: [Int], _ custom: [Int : Platform]?)
}

class ConsoleSelectionTableViewController: UITableViewController {
    
    var consoles = [Platform]()
    
    var selected = [Int]()
    var delegate: ConsoleSelectionTableViewControllerDelegate?
    
    var customPlatforms = [Platform]()
    
    var currentMaxId: Int = 0
    
    let reuseIdentifier = "console_selection_cell"
    
    weak var okAlertAction: UIAlertAction?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        self.navigationItem.title = "Select Platforms"
        //self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        autoreleasepool {
            let realm = try? Realm()
            if let custom = realm?.objects(Platform.self).filter("custom = true") {
                for customPlatform in custom {
                    customPlatforms.append(customPlatform)
                }
            }
        }
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return consoles.count
        case 1:
            return customPlatforms.count + 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Platforms"
        case 1:
            return "Custom Platforms"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = consoles[indexPath.row].name ?? ""
            if self.selected.contains(consoles[indexPath.row].idNumber) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else if indexPath.section == 1 {
            if indexPath.row == customPlatforms.count {
                cell.textLabel?.text = "Add Console..."
                cell.accessoryType = .none
            } else {
                cell.textLabel?.text = customPlatforms[indexPath.row].name ?? ""
                if self.selected.contains(customPlatforms[indexPath.row].idNumber) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 1 {
            if indexPath.row == customPlatforms.count {
                let alertController = UIAlertController(title: "Add New Console", message: "", preferredStyle: .alert)
                
                self.okAlertAction = UIAlertAction(title: "OK", style: .default, handler: {
                    alert -> Void in
                    
                    let textField = alertController.textFields![0] as UITextField
                    
                    if (textField.text?.characters.count)! > 0 {
                        autoreleasepool {
                        let realm = try? Realm()
                            // Check if platform already exists
                            var newPlatform = realm?.objects(Platform.self).filter("name = '\((textField.text)!)'").first
                            if newPlatform == nil {
                                newPlatform = Platform()
                                
                                newPlatform?.name = textField.text
                                newPlatform?.abbreviation = textField.text
                                newPlatform?.custom = true
                                if self.currentMaxId == 0 {
                                    let maxNumber = realm?.objects(Platform.self).map{$0.idNumber}.max() ?? 0
                                    if maxNumber >= Platform.customIdBase() {
                                        self.currentMaxId = maxNumber + 1
                                    } else {
                                        self.currentMaxId = Platform.customIdBase()
                                    }
                                }
                                
                                newPlatform?.idNumber = self.currentMaxId
                                self.currentMaxId = self.currentMaxId + 1
                            }
                            self.selected.append((newPlatform?.idNumber)!)
                            self.customPlatforms.append(newPlatform!)
                        }

                        cell?.accessoryType = .checkmark
                        tableView.reloadData()
                    }
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    (action : UIAlertAction!) -> Void in
                    
                })
                
                alertController.addTextField { textField in
                    textField.placeholder = "Enter Platform Name"
                    NotificationCenter.default.addObserver(self, selector: #selector(self.handleTextFieldTextDidChangeNotification), name: NSNotification.Name.UITextFieldTextDidChange, object: textField)
                }
                self.okAlertAction?.isEnabled = false
                alertController.addAction(self.okAlertAction!)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true, completion: nil)
            } else {
                if !self.selected.contains(customPlatforms[indexPath.row].idNumber) {
                    cell?.accessoryType = .checkmark
                    self.selected.append(customPlatforms[indexPath.row].idNumber)
                } else {
                    for i in 0..<self.selected.count {
                        if self.selected[i] == customPlatforms[indexPath.row].idNumber {
                            self.selected.remove(at: i)
                            break
                        }
                    }
                    cell?.accessoryType = .none
                }
            }
        } else {
            if !self.selected.contains(consoles[indexPath.row].idNumber) {
                cell?.accessoryType = .checkmark
                self.selected.append(consoles[indexPath.row].idNumber)
            } else {
                for i in 0..<self.selected.count {
                    if self.selected[i] == consoles[indexPath.row].idNumber {
                        self.selected.remove(at: i)
                        break
                    }
                }
                cell?.accessoryType = .none
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func handleTextFieldTextDidChangeNotification(notification: NSNotification) {
        let textField = notification.object as! UITextField
        
        self.okAlertAction!.isEnabled = (textField.text?.utf16.count)! >= 1
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        var customPlatformsToReturn = [Int : Platform]()
        for platform in self.customPlatforms {
            if self.selected.contains(platform.idNumber) {
                customPlatformsToReturn[platform.idNumber] = platform
            }
        }
        if customPlatformsToReturn.count == 0 {
            self.delegate?.didSelectConsoles(self.selected, nil)
        } else {
            
            self.delegate?.didSelectConsoles(self.selected, customPlatformsToReturn)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
