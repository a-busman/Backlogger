//
//  PanDirectionGestureRecognizer.swift
//  Backlogger
//
//  Created by Alex Busman on 2/8/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

enum PanDirection {
    case vertical
    case horizontal
}

class PanDirectionGestureRecognizer: UIPanGestureRecognizer {
    
    var direction: PanDirection = .vertical
    
    init(direction: PanDirection, target: AnyObject, action: Selector) {
        self.direction = direction
        super.init(target: target, action: action)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if state == .began {
            let vel = velocity(in: view)
            switch direction {
            case .horizontal where fabs(vel.y) > fabs(vel.x):
                state = .cancelled
            case .vertical where fabs(vel.x) > fabs(vel.y):
                state = .cancelled
            default:
                break
            }
        }
    }
}
