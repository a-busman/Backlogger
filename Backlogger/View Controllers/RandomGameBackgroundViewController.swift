//
//  RandomGameBackgroundViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/2/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import RealmSwift
import Kingfisher

class RandomGameBackgroundViewController: UIViewController {

    let screenWidth: CGFloat = UIScreen.main.bounds.width
    let ratio = 15.0 / 9.0
    private var _games: Results<GameField>!
    var games: Results<GameField>! {
        get {
            return self._games
        }
        set(newValue) {
            self._games = newValue
            self._maxOnScreen = newValue.count
        }
    }
    private var _maxOnScreen = 0
    private var _onScreen = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.opacity = 0.3
        autoreleasepool {
            guard let realm = try? Realm() else { return }
            self._games = realm.objects(GameField.self)
        }
        self._maxOnScreen = self._games.count
        self.beginAnimation()
    }
    

    func beginAnimation() {
        DispatchQueue.global().async { [weak self] in
            while true {
                let useconds = UInt32.random(in: 0..<2000000)
                usleep(useconds)
                
                // Return when self no longer exists
                guard let localSelf = self else {
                    return
                }
                if localSelf._onScreen >= localSelf._maxOnScreen {
                    continue
                }
                DispatchQueue.main.async {
                    localSelf.showGameArt(localSelf.ratio)
                }

            }
        }
    }
    
    func showGameArt(_ ratio: Double) {
        guard let gameField = self.randomGame(), let imageUrl = gameField.image?.smallUrl else { return }
        let height = Double.random(in: 50...400)
        let rootViewFrame = self.view.frame
        let randomFrame = CGRect(x: Double(rootViewFrame.width), y: Double.random(in: -50.0..<(Double(rootViewFrame.height) - 50.0)), width: height / ratio, height: height)
        let rootView = UIView(frame: randomFrame)
        let imageView = UIImageView()
        rootView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: rootView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor).isActive = true
        rootView.layer.shadowColor = UIColor.black.cgColor
        rootView.layer.shadowOffset = CGSize(width: height / 40, height: height / 40)
        rootView.layer.shadowRadius = CGFloat(height / 40)
        rootView.layer.shadowOpacity = 0.9
        rootView.layer.zPosition = CGFloat(height)
        rootView.layer.cornerRadius = CGFloat(height / 40.0)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = CGFloat(height / 40.0)
        imageView.kf.setImage(with: URL(string: imageUrl), placeholder: #imageLiteral(resourceName: "now_playing_placeholder"),  completionHandler: {
            result in
            switch result {
            case .success(let value):
                imageView.image = value.image
                self.view.addSubview(rootView)
                self.animate(rootView)
            case .failure(let error):
                NSLog("Error: \(error)")
            }
        })
    }
    
    func animate(_ imageView: UIView) {
        let randomTime = Double.random(in: 2.0...8.0)
        self._onScreen += 1
        UIView.animate(withDuration: randomTime, delay: 0.0, options: .curveLinear, animations: {
            imageView.transform = CGAffineTransform(translationX: -self.screenWidth - imageView.frame.width - 20, y: 0)
        }, completion: { _ in
            imageView.removeFromSuperview()
            self._onScreen -= 1
        })
    }
    
    func randomGame() -> GameField? {
        let index = Int.random(in: 0..<self._games.count)
        
        return self._games[index]
    }
}
