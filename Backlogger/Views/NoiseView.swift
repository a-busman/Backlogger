//
//  NoiseView.swift
//  Backlogger
//
//  Created by Alex Busman on 2/7/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

let noiseImageCache = NSCache<NSString, UIImage>()

@IBDesignable class NoiseView: UIView {
    
    let noiseImageSize = CGSize(width:128, height:128)
    
    @IBInspectable var noiseColor: UIColor = .black {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable var noiseMinAlpha: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable var noiseMaxAlpha: CGFloat = 1 {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable var noisePasses: Int = 1 {
        didSet {
            noisePasses = max(0, noisePasses)
            setNeedsDisplay()
        }
    }
    @IBInspectable var noiseSpacing: Int = 1 {
        didSet {
            noiseSpacing = max(1, noiseSpacing)
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        UIColor(patternImage: currentUIImage()).set()
        UIRectFillUsingBlendMode(bounds, .normal)
    }
    
    private func currentUIImage() -> UIImage {
        
        //  Key based on all parameters
        let cacheKey = "\(noiseImageSize),\(noiseColor),\(noiseMinAlpha),\(noiseMaxAlpha),\(noisePasses)"
        
        var image = noiseImageCache.object(forKey: NSString(string: cacheKey))
        
        if image == nil {
            image = generatedUIImage()
            
            #if !TARGET_INTERFACE_BUILDER
                noiseImageCache.setObject(image!, forKey: cacheKey as NSString)
            #endif
        }
        
        return image!
    }
    
    private func generatedUIImage() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(noiseImageSize, false, 0)
        
        let accuracy: CGFloat = 1000.0
        
        for _ in 0..<noisePasses {
            for y in 0..<Int(noiseImageSize.height) {
                for x in 0..<Int(noiseImageSize.width) {
                    if Int(arc4random()) % noiseSpacing == 0 {
                        let alpha = (CGFloat(Int(arc4random()) % Int((noiseMaxAlpha - noiseMinAlpha) * accuracy)) / accuracy) + noiseMinAlpha
                        noiseColor.withAlphaComponent(alpha).set()
                        UIRectFill(CGRect(x:CGFloat(x), y:CGFloat(y), width:1, height:1))
                    }
                }
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        
        UIGraphicsEndImageContext()
        
        return image
    }
}
