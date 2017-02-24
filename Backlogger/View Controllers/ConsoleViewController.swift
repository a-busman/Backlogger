//
//  ConsoleViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/8/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class ConsoleViewController: UIViewController {
    
    @IBOutlet weak var consoleImage:      UIImageView?
    @IBOutlet weak var consoleTitleLabel: UILabel?
    @IBOutlet weak var gameCountLabel:    UILabel?
    @IBOutlet weak var companyLabel:      UILabel?
    @IBOutlet weak var shadowView:        UIView?
    var console: Console?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(console: Console) {
        super.init(nibName: nil, bundle: nil)
        self.console = console
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConsole(console: Console) {
        self.console = console
        self.consoleImage?.image = console.image
        self.consoleTitleLabel?.text = console.title
        self.gameCountLabel?.text = console.gameCount
        self.companyLabel?.text = console.company
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.consoleImage?.image = self.console?.image
        self.consoleTitleLabel?.text = self.console?.title
        self.gameCountLabel?.text = self.console?.gameCount
        self.companyLabel?.text = self.console?.company
    }
    
    override func viewDidLayoutSubviews() {
        self.shadowView?.layer.shadowOpacity = 0.8
        self.shadowView?.layer.shadowRadius = 5.0
        self.shadowView?.layer.shadowColor = UIColor.black.cgColor
        self.shadowView?.layer.shadowPath = UIBezierPath(rect: (self.shadowView?.bounds)!).cgPath
        self.shadowView?.layer.shadowOffset = CGSize.zero
    }
}
