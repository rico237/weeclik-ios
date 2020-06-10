//
//  ParseErrorCodeHandler.swift
//  WeeClik
//
//  Created by Herrick Wolber on 11/05/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Parse
import Loaf

struct ParseErrorCodeHandler {
    // ERREUR (CREATION / LOGIN) / COMMERCE (PFObject) / PURCHASE / etc.
    // TODO: Envoyer mail à chaque erreur

    static func handleLocationError(error: Error) {
        guard let error = error as? CLError else {
            return
        }
        // FIXME: Use proper CLError handle (https://developer.apple.com/documentation/corelocation/clerror?language=objc)
        var message = error._nsError.description
        switch error.domain {
        case kCLErrorDomain:
            message = "Adresse invalide."
        default:
            break
        }
        
        HelperAndKeys.showNotification(type: "E", title: "Erreur", message: message, delay: 3)
    }
    
    static func handleUnknownError(error: Error, withFeedBack feedBack: Bool = false, completion: (() -> Void)? = nil) {

        if feedBack {
            HelperAndKeys.showNotification(type: "E", title: "Erreur", message: error.localizedDescription, delay: 3)
        }

        let message = """
        
            Erreur Inconnu:
                Code: \(error.code)
                Domain: \(error.domain)
                LocalizedDescription: \(error.localizedDescription)
                LocalizedDescription 2: \(error.desc.localized())
                Showed to user ? \(feedBack)
        
        """
        if error.code != 8 {
            Log.all.error(message)
            Log.all.warning("Envoi de mail en cas d'erreur inactif")
        }
        
        if (error.code == PFErrorCode.errorInvalidSessionToken.rawValue || error.code == PFErrorCode.errorFacebookInvalidSession.rawValue) {
            PFUser.logOut()
            Log.all.warning("User logged out")
            completion?()
        }
//        MailHelper.sendErrorMail()
    }

    // FIXME: AJOUTER la bonne manière pour chaque erreur
    static func handleParseError(error: Error) -> String {
        switch error.code {
        case PFErrorCode.errorConnectionFailed.rawValue :
            return "Il y a eu un problème de connexion veuillez réessayer plus tard.".localized()
        case PFErrorCode.errorInvalidSessionToken.rawValue :
            PFUser.logOut()
            Log.all.warning("User logged out")
            return "Il y a eu un problème de connexion veuillez réessayer.".localized()
        default:
            Log.all.warning(error.debug)
            return error.localizedDescription + " code : \(error.code)"
        }
    }
}
