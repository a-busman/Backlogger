//
//  NowPlayingGameView.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation
import UIKit

final class NowPlayingGameView: UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        let view = Bundle.main.loadNibNamed("NowPlayingGameView", owner: self, options: nil)![0] as! UIView
        self.addSubview(view)
    }
    init() {
        super.init(frame: CGRect())
        let view = Bundle.main.loadNibNamed("NowPlayingGameView", owner: self, options: nil)![0] as! UIView
        self.addSubview(view)
    }
}
