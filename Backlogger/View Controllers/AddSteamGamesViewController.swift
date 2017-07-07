//
//  AddSteamGamesViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 6/24/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

protocol AddSteamGamesViewControllerDelegate {
    func didSelectSteamGames(vc: AddSteamGamesViewController, games: [GameField])
    func didDismiss(vc: AddSteamGamesViewController)
}

class AddSteamGamesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    
    var delegate: AddSteamGamesViewControllerDelegate?
    
    var gameFields: [GameField] = []
    var selected: [Bool] = []
    
    let tableReuseIdentifier = "table_cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView?.setEditing(true, animated: false)
        self.tableView?.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.tableReuseIdentifier)
        self.tableView?.tableFooterView = UIView(frame: .zero)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for i in 0..<gameFields.count {
            self.selected.append(true)
            self.tableView?.selectRow(at: IndexPath(row: i, section: 0), animated: false, scrollPosition: .none)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelTapped(sender: UIBarButtonItem) {
        self.delegate?.didDismiss(vc: self)
    }
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        var returnFields: [GameField] = []
        for (i, gameField) in gameFields.enumerated() {
            if self.selected[i] {
                returnFields.append(gameField)
            }
        }
        self.delegate?.didSelectSteamGames(vc: self, games: returnFields)
    }
}

extension AddSteamGamesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gameFields.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selected[indexPath.row] = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.selected[indexPath.row] = false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! TableViewCell
        
        if self.gameFields.count >= indexPath.row {
            
            let gameToShow = self.gameFields[indexPath.row]
            
            cell.rightLabel?.text = ""
            cell.percentView?.isHidden = true
            
            if let name = gameToShow.name {
                cell.titleLabel?.text = name
            } else {
                cell.titleLabel?.text = ""
            }
            var platformString = ""
            let platforms = gameToShow.platforms
            if platforms.count > 0 {
                if platforms.count > 1 {
                    for platform in platforms[0..<platforms.endIndex - 1] {
                        if platform.name!.characters.count < 10 {
                            platformString += platform.name! + " • "
                        } else {
                            platformString += platform.abbreviation! + " • "
                        }
                    }
                }
                if platforms[platforms.endIndex - 1].name!.characters.count < 10 {
                    platformString += platforms[platforms.endIndex - 1].name!
                } else {
                    platformString += platforms[platforms.endIndex - 1].abbreviation!
                }
            }
            cell.descriptionLabel?.text = platformString
            
            if let image = gameToShow.image {
                cell.imageUrl = URL(string: image.iconUrl!)
            }
            cell.cacheCompletionHandler = {
                (image, error, cacheType, imageUrl) in
                if let cellUrl = cell.imageUrl {
                    if imageUrl == cellUrl {
                        if image != nil {
                            if cacheType == .none || cacheType == .disk {
                                UIView.transition(with: cell.artView!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                    cell.set(image: image!)
                                }, completion: nil)
                            } else {
                                cell.set(image: image!)
                            }
                        }
                    }
                }
            }
        }
        return cell
    }
}
