//
//  TableViewCell.swift
//  Backlogger
//
//  Created by Alex Busman on 2/11/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    override func prepareForReuse() {
        //layer.removeAllAnimations()
        for view in contentView.subviews {
            view.removeFromSuperview()
        }
    }
}
