//
//  ParseErrorCodeHandler.swift
//  WeeClik
//
//  Created by Herrick Wolber on 11/05/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import Crashlytics

class ParseErrorCodeHandler {

    // FIXME: AJOUTER la bonne manière pour chaque erreur
    // ERREUR (CREATION / LOGIN) / COMMERCE (PFObject) / PURCHASE / etc.
    // URGENT: Envoyer mail à chaque erreur

    static func handleUnknownError(error: Error, withFeedBack feedBack: Bool = false) {

        if feedBack {
            HelperAndKeys.showNotification(type: "E" , title: "Erreur", message: error.localizedDescription, delay: 3)
        }

        Crashlytics.sharedInstance().recordError(error)

        print("Erreur Inconnu :\n\tCode : \(error.code)\n\tDomain : \(error.domain)\n\tLocalizedDescription : \(error.localizedDescription)")
        print("Envoi d'un mail aux admins a tester")
        MailHelper.sendErrorMail()
    }

    static func handleParseError(error: Error) -> String {
        switch error.code {
        case PFErrorCode.errorConnectionFailed.rawValue :
            return "Il y a eu un problème de connexion veuillez réessayer plus tard.".localized()
        case PFErrorCode.errorInvalidSessionToken.rawValue :
            PFUser.logOut()
            return "Il y a eu un problème de connexion veuillez réessayer.".localized()
        default:
            return error.localizedDescription + " code : \(error.code)"
        }
    }
}
