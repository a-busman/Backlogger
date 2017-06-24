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
    func didSelectConsoles(_ consoles: [Platform])
}

class ConsoleSelectionTableViewController: UITableViewController {
    
    var consoles = [Platform]()
    
    var selected = [Platform]()
    var delegate: ConsoleSelectionTableViewControllerDelegate?
    
    var customPlatforms = [Platform]()
    
    var gameField: GameField?
    
    var currentMaxId: Int = 0
    
    var playlist = false
    
    let reuseIdentifier = "console_selection_cell"
    
    weak var okAlertAction: UIAlertAction?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        self.navigationItem.title = "Select Platforms"

        self.clearsSelectionOnViewWillAppear = false
        
        if self.gameField != nil {
            autoreleasepool {
                let realm = try! Realm()
                if let dbGameField = realm.object(ofType: GameField.self, forPrimaryKey: gameField!.idNumber) {
                    if !self.playlist {
                        for game in dbGameField.ownedGames {
                            selected.append(game.platform!)
                        }
                    }
                    for platform in dbGameField.platforms {
                        consoles.append(platform)
                    }
                } else {
                    for platform in gameField!.platforms {
                        consoles.append(platform)
                    }
                }
            }
        }
        autoreleasepool {
            let realm = try! Realm()
            let custom = realm.objects(Platform.self).filter("custom = true")
            for customPlatform in custom {
                customPlatforms.append(customPlatform)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if consoles.count > 0 {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if consoles.count > 0 {
            switch section {
            case 0:
                return consoles.count
            case 1:
                return customPlatforms.count + 1
            default:
                return 0
            }
        } else {
            return customPlatforms.count + 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.consoles.count > 0 {
            switch section {
            case 0:
                return "Platforms"
            case 1:
                return "Custom Platforms"
            default:
                return ""
            }
        } else {
            return "Custom Platforms"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if self.consoles.count > 0 {
            if indexPath.section == 0 {
                cell.textLabel?.text = consoles[indexPath.row].name ?? ""
                if self.selected.contains(consoles[indexPath.row]) {
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
                    if self.selected.contains(customPlatforms[indexPath.row]) {
                        cell.accessoryType = .checkmark
                    } else {
                        cell.accessoryType = .none
                    }
                }
            }
        } else {
            if indexPath.row == customPlatforms.count {
                cell.textLabel?.text = "Add Console..."
                cell.accessoryType = .none
            } else {
                cell.textLabel?.text = customPlatforms[indexPath.row].name ?? ""
                if self.selected.contains(customPlatforms[indexPath.row]) {
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
        if self.consoles.count > 0 {
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
                                self.selected.append(newPlatform!)
                                self.customPlatforms.append(newPlatform!)
                            }

                            cell?.accessoryType = .checkmark
                            tableView.reloadData()
                        }
                        NotificationCenter.default.removeObserver(self)
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
                    if !self.selected.contains(customPlatforms[indexPath.row]) {
                        cell?.accessoryType = .checkmark
                        self.selected.append(customPlatforms[indexPath.row])
                    } else {
                        for i in 0..<self.selected.count {
                            if self.selected[i] == customPlatforms[indexPath.row] {
                                self.selected.remove(at: i)
                                break
                            }
                        }
                        cell?.accessoryType = .none
                    }
                }
            } else {
                if !self.selected.contains(consoles[indexPath.row]) {
                    cell?.accessoryType = .checkmark
                    self.selected.append(consoles[indexPath.row])
                } else {
                    for i in 0..<self.selected.count {
                        if self.selected[i] == consoles[indexPath.row] {
                            self.selected.remove(at: i)
                            break
                        }
                    }
                    cell?.accessoryType = .none
                }
            }
        } else {
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
                            self.selected.append(newPlatform!)
                            self.customPlatforms.append(newPlatform!)
                        }
                        
                        cell?.accessoryType = .checkmark
                        tableView.reloadData()
                    }
                    NotificationCenter.default.removeObserver(self)
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
                if !self.selected.contains(customPlatforms[indexPath.row]) {
                    cell?.accessoryType = .checkmark
                    self.selected.append(customPlatforms[indexPath.row])
                } else {
                    for i in 0..<self.selected.count {
                        if self.selected[i] == customPlatforms[indexPath.row] {
                            self.selected.remove(at: i)
                            break
                        }
                    }
                    cell?.accessoryType = .none
                }
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
        self.delegate?.didSelectConsoles(self.selected)
    }
}
