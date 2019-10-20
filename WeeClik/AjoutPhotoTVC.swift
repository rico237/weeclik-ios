//
//  AjoutPhotoTVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 05/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

class AjoutPhotoTVC: UITableViewCell {

    @IBOutlet private weak var photoCollectionView : UICollectionView!

    func setCollectionViewDataSourceDelegate <D: UICollectionViewDataSource & UICollectionViewDelegate> (dataSourceDelegate: D, forRow row: Int) {
        photoCollectionView.delegate = dataSourceDelegate
        photoCollectionView.dataSource = dataSourceDelegate
        photoCollectionView.tag = row
        photoCollectionView.reloadData()
    }
}
