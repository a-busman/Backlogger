//
//  AboutViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 6/25/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    @IBAction func tappedLink(sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              view.subviews.count == 2,
              let linkView = view.subviews[1] as? UILabel else {
            return
        }
        UIApplication.shared.open(URL(string: linkView.text!)!, options: [:], completionHandler: nil)
    }
}
