//
//  ParseErrorCodeHandler.swift
//  WeeClik
//
//  Created by Herrick Wolber on 11/05/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Parse
import Loaf
import Localize_Swift

struct ParseErrorCodeHandler {
    
    private static let className = "ParseErrorCodeHandler"

    // FIXME: AJOUTER la bonne manière pour chaque erreur
    // ERREUR (CREATION / LOGIN) / COMMERCE (PFObject) / PURCHASE / etc.
    // URGENT: Envoyer mail à chaque erreur

    static func handleUnknownError(error: Error, withFeedBack feedBack: Bool = false, completion: (() -> Void)? = nil) {

        if feedBack {
            HelperAndKeys.showNotification(type: "E", title: "Erreur", message: error.desc.localized(), delay: 3)
        }

        let message = """
        
            Erreur Inconnu :
                Code: \(error.code)
                Domain: \(error.domain)
                LocalizedDescription: \(error.localizedDescription)
                LocalizedDescription 2: \(error.desc.localized())
                Showed to user ? \(feedBack)
        
        """
        Log.all.error(message)
        Log.all.warning("Envoi de mail en cas d'erreur inactif")
        
        if (error.code == PFErrorCode.errorInvalidSessionToken.rawValue || error.code == PFErrorCode.errorFacebookInvalidSession.rawValue) {
            PFUser.logOut()
            Log.all.warning("User logged out")
            completion?()
        }
//        MailHelper.sendErrorMail()
    }

    static func handleParseError(error: Error) -> String {
        switch error.code {
        case PFErrorCode.errorConnectionFailed.rawValue :
            return "Il y a eu un problème de connexion veuillez réessayer plus tard.".localized()
        case PFErrorCode.errorInvalidSessionToken.rawValue :
            PFUser.logOut()
            Log.all.warning("User logged out")
            return "Il y a eu un problème de connexion veuillez réessayer.".localized()
        default:
            return error.localizedDescription + " code : \(error.code)"
        }
        
        Log.all.warning(error.localizedDescription + " code : \(error.code)")
    }
}
