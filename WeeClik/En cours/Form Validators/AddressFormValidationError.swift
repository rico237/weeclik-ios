//
//  AddressFormValidationError.swift
//  WeeClik
//
//  Created by Herrick Wolber on 17/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Validator

class AddressFormValidationError: ValidationError {
    let message: String
    
    public init() {self.message = "Vous devez définir un nom pour votre commerce"}
    public init(_ message: String) { self.message = message }
}
