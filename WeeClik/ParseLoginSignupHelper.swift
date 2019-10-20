//
//  ParseLoginSignupHelper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 19/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Parse

class ParseLoginSignupHelper {
    static func parseLoginViewController() -> PFLogInViewController {
        let logInController = LoginViewController()
            logInController.fields = [PFLogInFields.usernameAndPassword,
                                      PFLogInFields.logInButton,
                                      PFLogInFields.signUpButton,
                                      PFLogInFields.passwordForgotten,
                                      PFLogInFields.dismissButton,
                                      PFLogInFields.facebook]
            logInController.emailAsUsername = true
            logInController.facebookPermissions = ["email", "public_profile"]

            // SignUp Part
            logInController.signUpController = SignUpViewController()
    //        logInController.signUpController?.emailAsUsername = true
            logInController.signUpController?.fields = [.usernameAndPassword, .signUpButton, .additional, .dismissButton]
            logInController.signUpController?.signUpView?.usernameField?.keyboardType = .emailAddress
            logInController.signUpController?.signUpView?.additionalField?.isSecureTextEntry = true
            logInController.signUpController?.signUpView?.additionalField?.keyboardType = .alphabet
    //        logInController.signUpController?.signUpView?.additionalField?.textContentType = .password
            logInController.signUpController?.signUpView?.usernameField?.placeholder = "Email".localized()
            logInController.signUpController?.signUpView?.additionalField?.placeholder = "Confirmation du mot de passe".localized()
        return logInController
    }
}
