//
//  FilterCategoryTableViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/9/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift

protocol FilterCategoryDelegate {
    func didSelect(_ ids: Set<Int>, category: FilterCategoryTableViewController.FilterCategory)
}

class FilterCategoryTableViewController: UITableViewController {
    enum FilterCategory: String {
        case platforms = "Platforms"
        case genres    = "Genres"
    }
    
    private var _filterList: Results<Field>?
    private var _selected: [Bool] = []
    
    var delegate: FilterCategoryDelegate?
    var filterList = Set<Int>()
    var filterCategory: FilterCategory?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let realm = try? Realm(),
            let filterCategory = self.filterCategory {
            var type: Field.Type = Field.self
            if filterCategory == .platforms {
                type = Platform.self
            } else if filterCategory == .genres {
                type = Genre.self
            }
            self._filterList = realm.objects(type).sorted(byKeyPath: "name", ascending: true)
            if filterCategory == .platforms {
                self._filterList = self._filterList?.filter(NSPredicate(format: "ownedGames.@count > 0"))
            }
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self._filterList?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filter_category_cell", for: indexPath)
        let index = indexPath.row
        guard let item = self._filterList?[index] else { return cell }
        cell.textLabel?.text = item.name
        if self.filterList.contains(item.idNumber) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath),
            let selection = self._filterList?[indexPath.row] {
            cell.setSelected(false, animated: true)
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                self.filterList.remove(selection.idNumber)
            } else if cell.accessoryType == .none {
                cell.accessoryType = .checkmark
                self.filterList.insert(selection.idNumber)
            }
            self.delegate?.didSelect(self.filterList, category: self.filterCategory!)
        }
    }
}
