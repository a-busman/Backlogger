//
//  PercentViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 7/6/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class PercentViewController: UIViewController {
    var progressLabel: UILabel!
    
    private var _progress: Int = 0
    
    private var _complete: Bool = false
    
    let shapeLayer = CAShapeLayer()
    
    var progress: Int {
        get {
            return self._progress
        }
        set(newValue) {
            self._progress = newValue
            if self.isViewLoaded {
                self.progressLabel.text = "\(self._progress)"
            }
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: 14, y: 14), radius: 14.0, startAngle: CGFloat(Double.pi * 1.5), endAngle:CGFloat(Double.pi * 2) * (CGFloat(self._progress) / 100.0) - CGFloat(Double.pi * 0.5) - (self._progress == 100 ? 0.00001 : 0), clockwise: true)
            self.shapeLayer.path = circlePath.cgPath
        }
    }
    
    var complete: Bool {
        get {
            return self._complete
        }
        set(newValue) {
            self._complete = newValue
            if newValue {
                self.shapeLayer.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0).cgColor
            } else {
                self.shapeLayer.strokeColor = Util.appColor.cgColor
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.progressLabel = UILabel()
        self.progressLabel.textColor = .secondaryLabel
        self.progressLabel.text = "\(self._progress)"
        self.progressLabel.textAlignment = .center
        self.progressLabel.font = UIFont.systemFont(ofSize: 10.0, weight: UIFont.Weight(rawValue: 4.0))
        
        let backgroundCirclePath = UIBezierPath(arcCenter: CGPoint(x: 14, y: 14), radius: 14.0, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 14, y: 14), radius: 14.0, startAngle: CGFloat(Double.pi * 1.5), endAngle:CGFloat(Double.pi * 2) * (CGFloat(self._progress) / 100.0) - CGFloat(Double.pi * 0.5) - (self._progress == 100 ? 0.00001 : 0), clockwise: true)
        
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.path = backgroundCirclePath.cgPath
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.systemGray6.cgColor
        backgroundLayer.lineWidth = 3.0
        
        self.shapeLayer.path = circlePath.cgPath
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        if self._complete {
            self.shapeLayer.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0).cgColor
        } else {
            self.shapeLayer.strokeColor = Util.appColor.cgColor
        }
        self.shapeLayer.lineWidth = 3.0
        self.shapeLayer.lineCap = CAShapeLayerLineCap.round
        
        self.view.layer.addSublayer(backgroundLayer)
        self.view.layer.addSublayer(shapeLayer)
        
        self.view.addSubview(self.progressLabel)
        
        self.view.backgroundColor = .clear
        self.progressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.progressLabel.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.progressLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.progressLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.progressLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
}
