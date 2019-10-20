//
//  PhotosVideosCollectionCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 09/03/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit

class PhotosVideosCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imagePlaceholder: UIImageView!
    @IBOutlet weak var minuteViewContainer: UIView!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: self.minuteViewContainer.frame.size.width, height: 25)
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.3).cgColor]
//        gradientLayer.locations = [0.95, 1]
        self.minuteViewContainer.layer.insertSublayer(gradientLayer, at: 0)
//        self.view.layer.addSublayer(gradientLayer)
    }
}
