//
//  SelectionCategorieTVCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 13/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

class SelectionCategorieTVCell: UITableViewCell {
    @IBOutlet weak var categoriePickerView: UIPickerView!

    func setPickerViewDataSourceDelegate <D: UIPickerViewDataSource & UIPickerViewDelegate> (dataSourceDelegate: D) {
        categoriePickerView.delegate = dataSourceDelegate
        categoriePickerView.dataSource = dataSourceDelegate
    }
}
