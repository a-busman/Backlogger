//
//  AddedOverlayViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/25/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class AddedOverlayViewController: UIViewController {
    @IBOutlet weak var checkMark: UIImageView?
    @IBOutlet weak var addLabel:  UILabel?

    private var timer: Timer!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkMark?.alpha = 0.0
        self.addLabel?.alpha = 0.0
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func appear() {
        self.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        let visualEffectView = self.view as? UIVisualEffectView
        visualEffectView?.effect = nil
        self.view.isHidden = false
        self.timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(disappear), userInfo: nil, repeats: false)
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: { let visualEffectView = self.view as? UIVisualEffectView
            visualEffectView?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            visualEffectView?.effect = UIBlurEffect(style: .extraLight)
            self.checkMark?.alpha = 1.0
            self.addLabel?.alpha = 1.0},
                       completion: nil)
    }
    
    func disappear() {
        self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: { let visualEffectView = self.view as? UIVisualEffectView
            visualEffectView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            visualEffectView?.effect = nil
            self.checkMark?.alpha = 0.0
            self.addLabel?.alpha = 0.0},
                       completion: { _ in self.view.isHidden = true})
        self.timer.invalidate()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
