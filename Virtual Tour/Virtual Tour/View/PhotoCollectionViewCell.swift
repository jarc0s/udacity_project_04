//
//  PhotoCollectionViewCell.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/16/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var contentLoader: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentLoader.layer.cornerRadius = 10
        contentLoader.layer.masksToBounds = true
        self.backgroundColor = .darkGray
        activityIndicator.transform = CGAffineTransform(scaleX: 2, y: 2)
    }
    
    
    
}
