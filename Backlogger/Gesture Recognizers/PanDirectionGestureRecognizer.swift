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
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
    }
    
    init(direction: PanDirection, target: Any?, action: Selector?) {
        self.direction = direction
        super.init(target: target, action: action)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if state == .began {
            let vel = velocity(in: view)
            switch direction {
            case .horizontal where abs(vel.y) > abs(vel.x):
                state = .cancelled
            case .vertical where abs(vel.x) > abs(vel.y):
                state = .cancelled
            default:
                break
            }
        }
    }
}
