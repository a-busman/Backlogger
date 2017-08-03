//
//  ProgressCell.swift
//  Backlogger
//
//  Created by Alex Busman on 8/2/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class ProgressCell: UICollectionViewCell {
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var numeratorLabel: UILabel!
    @IBOutlet weak var denominatorLabel: UILabel!
    
    var numerator:   Int = 0
    var denominator: Int = 0
    
    var titleString: String = ""
    
    enum ProgressType {
        case games
        case percent
    }
    
    var progressType: ProgressType = .games
    
    let shapeLayer = CAShapeLayer()
    let backgroundLayer = CAShapeLayer()
    
    override func prepareForReuse() {
        self.shapeLayer.removeFromSuperlayer()
        self.backgroundLayer.removeFromSuperlayer()
    }
    
    override func layoutSubviews() {
        var total = self.denominator
        self.titleLabel.text = self.titleString
        
        self.numeratorLabel.text = "\(self.numerator)"
        
        if progressType == .games {
            self.denominatorLabel.text = "OF \(self.denominator) GAMES"
        } else {
            self.denominatorLabel.text = "PERCENT"
        }
        
        if self.denominator == 0 {
            total = 1
        }
        let backgroundCirclePath = UIBezierPath(arcCenter: CGPoint(x: 62.5, y: 62.5), radius: 62.5, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 62.5, y: 62.5), radius: 62.5, startAngle: CGFloat(Double.pi * 1.5), endAngle:CGFloat(Double.pi * 2) * (CGFloat(self.numerator) / CGFloat(total)) - CGFloat(Double.pi * 0.5) - ((Float(self.numerator) / Float(total)) >= 1.0 ? 0.00001 : 0), clockwise: true)
        
        self.backgroundLayer.path = backgroundCirclePath.cgPath
        self.backgroundLayer.fillColor = UIColor.clear.cgColor
        self.backgroundLayer.strokeColor = Util.appColor.cgColor.copy(alpha: 0.1)
        self.backgroundLayer.lineWidth = 15.0
        
        self.shapeLayer.path = circlePath.cgPath
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = Util.appColor.cgColor
        self.shapeLayer.lineWidth = 15.0
        self.shapeLayer.lineCap = kCALineCapRound
        
        self.circleView.layer.addSublayer(self.backgroundLayer)
        self.circleView.layer.addSublayer(self.shapeLayer)
    }
}
