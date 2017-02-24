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
        layer.removeAllAnimations()
        for view in contentView.subviews {
            view.removeFromSuperview()
        }
    }
}

class TableViewCellView: UIViewController {
    
    @IBOutlet weak var artView: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var rightLabel: UILabel?
    
    enum ImageSource {
        case Placeholder
        case Downloaded
    }
    
    var imageSource: ImageSource = .Placeholder
    
    var game:    Game?
    var console: Console?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(console: Console) {
        super.init(nibName: nil, bundle: nil)
        self.console = console
    }
    init(game: Game) {
        super.init(nibName: nil, bundle: nil)
        self.game = game
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
