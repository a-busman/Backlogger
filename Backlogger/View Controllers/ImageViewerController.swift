//
//  ImageViewerController.swift
//  Backlogger
//
//  Created by Alex Busman on 2/25/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class ImageViewerController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView?
    
    let cellReuseIdentifier = "image_cell"
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension ImageViewerController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image_cell", for: indexPath) as! ImageCell
        return cell
    }
}
