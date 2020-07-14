//
//  Extension+UITableView.swift
//  WeeClik
//
//  Created by Herrick Wolber on 07/07/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

extension UITableView {
    func reloadWithoutScroll() {
        beginUpdates()
        let offset = contentOffset
        layoutIfNeeded()
        setContentOffset(offset, animated: false)
        endUpdates()
    }
}
