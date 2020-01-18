//
//  Extension+Dictionary.swift
//  WeeClik
//
//  Created by Herrick Wolber on 31/12/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Foundation

extension Dictionary where Value: RangeReplaceableCollection {
    public mutating func append(element: Value.Iterator.Element, toValueOfKey key: Key) -> Value? {
        var value: Value = self[key] ?? Value()
        value.append(element)
        self[key] = value
        return value
    }
}
