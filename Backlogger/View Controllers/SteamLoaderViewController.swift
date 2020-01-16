//
//  SteamLoaderViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit

class SteamLoaderViewController: UIViewController {
    @IBOutlet weak var progressBar: UIProgressView?
    @IBOutlet weak var progressLabel: UILabel?
    
    private var _progress = 0
    
    var progress: Int {
        get {
            return self._progress
        }
        set(value) {
            if value >= 0 && value <= 100 {
                self.progressBar?.progress = Float(value) / 100
                self.progressLabel?.text = "\(value)%"
                self._progress = value
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
