//
//  PaymentCollectionViewCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 26/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import LGButton

class PaymentCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var shadowView : UIView!
    @IBOutlet weak var priceViewLGButton: LGButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var actionButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        shadowView.layer.cornerRadius = 5
    }
}
