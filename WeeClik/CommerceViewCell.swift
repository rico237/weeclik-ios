//
//  CommerceViewCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 29/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

class CommerceViewCell: UICollectionViewCell {
    
    @IBOutlet weak var nomCommerce: UILabel!
    @IBOutlet weak var nombrePartageLabel: UILabel!
    @IBOutlet weak var thumbnailPicture: UIImageView!
    @IBOutlet weak var imagePartage: UIImageView!
    @IBOutlet weak var container: CardView!
    
    var cornerRadius: CGFloat = 3
    var shadowOffsetWidth: Int = 5
    var shadowOffsetHeight: Int = 5
    var shadowColor: UIColor? = UIColor.lightGray
    var shadowOpacity: Float = 0.7
    
    override func layoutSubviews() {
        layer.cornerRadius = cornerRadius
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        
        layer.masksToBounds = false
        layer.shadowColor = shadowColor?.cgColor
        layer.shadowOffset = CGSize(width: shadowOffsetWidth, height: shadowOffsetHeight);
        layer.shadowOpacity = shadowOpacity
        layer.shadowPath = shadowPath.cgPath
    }
    
}
