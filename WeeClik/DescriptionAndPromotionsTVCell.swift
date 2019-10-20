//
//  DescriptionAndPromotionsTVCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 13/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

class DescriptionAndPromotionsTVCell: UITableViewCell {
    @IBOutlet weak var textViewDescAndPromotions: UITextView!

    func setTextViewDataSourceDelegate <D: UITextViewDelegate> (dataSourceDelegate: D, withTag: Int) {
        textViewDescAndPromotions.delegate = dataSourceDelegate
        textViewDescAndPromotions.tag = withTag
    }
}
