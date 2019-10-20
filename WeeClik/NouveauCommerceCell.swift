//
//  NouveauCommerceCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 05/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

class NouveauCommerceCell: UITableViewCell {
    @IBOutlet weak var contentTF:UITextField!

    func setTextFieldViewDataDelegate <D: UITextFieldDelegate> (delegate: D, tag: Int, placeHolder : String) {
        contentTF.delegate = delegate
        contentTF.tag = tag
        contentTF.placeholder = placeHolder
    }
}
