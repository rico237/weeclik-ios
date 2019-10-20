//
//  IsPhoneNumberValidationPattern.swift
//  WeeClik
//
//  Created by Herrick Wolber on 17/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Validator

class IsPhoneNumberValidationRule: ValidationRule {
    var error: ValidationError = TelFormValidationError()
    typealias InputType = String
    func validate(input: String?) -> Bool {
        return true
    }
}
