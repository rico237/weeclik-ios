//
//  FormTextField.swift
//  WeeClik
//
//  Created by Herrick Wolber on 20/10/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

@IBDesignable
class FormTextField: UITextField {
    
    @IBInspectable var paddingLeft: CGFloat = 8
    @IBInspectable var paddingRight: CGFloat = 8
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0, paddingLeft, 0, 0)))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: UIEdgeInsetsInsetRect(bounds,  UIEdgeInsetsMake(0, paddingLeft, 0, 0)))
    }
}
