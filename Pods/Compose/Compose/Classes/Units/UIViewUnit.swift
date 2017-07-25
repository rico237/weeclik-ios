//
//  UIViewUnit.swift
//  Compose
//
//  Created by Bruno Bilescky on 06/12/16.
//  Copyright © 2016 VivaReal. All rights reserved.
//

import UIKit

public struct UIViewUnit: ComposingUnit {

    public let type: UIView.Type
    public let cellType: UICollectionViewCell.Type
    public let identifier: String
    public let cellConfig: (UIView)-> Void
    public let heightUnit: DimensionUnit
    
    public init<View: UIView>(id: String, height: DimensionUnit, configure: @escaping ((View)-> Void)) {
        self.identifier = id
        self.type = View.self
        self.cellType = ComposingUnitCollectionViewCell<View>.self
        self.heightUnit = height
        self.cellConfig = { cell in
            guard let cell = cell as? ComposingUnitCollectionViewCell<View> else { return }
            configure(cell.innerView)
        }
    }
    
    public func configure(view: UIView) {
        self.cellConfig(view)
    }
    
    public func reuseIdentifier() -> String {
        return cellType.identifier()
    }
    
    public func register(in collectionView: UICollectionView) {
        cellType.register(in: collectionView)
    }
    
}
