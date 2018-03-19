//
//  AccueilCollectionViewCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 07/03/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit

class AccueilCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var nomCommerce: UILabel!
    @IBOutlet weak var nombrePartageLabel: UILabel!
    @IBOutlet weak var thumbnailPicture: UIImageView!
    @IBOutlet weak var imagePartage: UIImageView!
    @IBOutlet weak var container: CardView!

    override open func layoutSubviews(){
        super.layoutSubviews()
        self.imagePartage.tintColor = UIColor.red
        self.thumbnailPicture.roundCorners([.topLeft, .topRight], radius: 5)
    }
}

extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
