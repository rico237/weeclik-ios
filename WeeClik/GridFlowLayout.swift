//
//  GridFlowLayout.swift
//  WeeClik
//
//  Created by Herrick Wolber on 28/02/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit

class GridFlowLayout: UICollectionViewFlowLayout {
    let cellsPerRow: Int
    override var itemSize: CGSize {
        get {
            guard let collectionView = collectionView else { return super.itemSize }

            let marginsAndInsets = sectionInset.left + sectionInset.right + collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right + minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
            let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)

            return CGSize(width: itemWidth, height: 200)
        }
        set {
            super.itemSize = newValue
        }
    }

    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()

        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        let contentSize = collectionViewContentSize
        return attributes?.filter { $0.frame.maxX <= contentSize.width && $0.frame.maxY < contentSize.height }
    }
}
