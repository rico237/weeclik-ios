//
//  CommerceCVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 17/12/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit

class CommerceCVC: UICollectionViewCell {
    @IBOutlet weak var nomCommerce: UILabel!
    @IBOutlet weak var thumbnailPicture: UIImageView!
    
    @IBOutlet weak var nombrePartageLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var imageDistance: UIImageView!
    @IBOutlet weak var imagePartage: UIImageView!
    
    @IBOutlet weak var container: CardView!
    
    override open func layoutSubviews(){
        super.layoutSubviews()
        self.imagePartage.tintColor = .red
//        self.imageDistance.tintColor = .red
        self.thumbnailPicture.roundCorners([.topLeft, .topRight], radius: 5)
    }
}
