//
//  Extension+UIView.swift
//  WeeClik
//
//  Created by Herrick Wolber on 13/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
