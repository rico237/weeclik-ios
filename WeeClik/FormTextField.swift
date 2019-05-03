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
        return super.textRect(forBounds: bounds.inset(by: UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: 0)))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds.inset(by: UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: 0)))
    }
}
