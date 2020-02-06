//
//  ParseErrorCodeHandler.swift
//  WeeClik
//
//  Created by Herrick Wolber on 11/05/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Parse
import Crashlytics
import Loaf
import Localize_Swift

struct ParseErrorCodeHandler {
    
    private static let className = "ParseErrorCodeHandler"

    // FIXME: AJOUTER la bonne manière pour chaque erreur
    // ERREUR (CREATION / LOGIN) / COMMERCE (PFObject) / PURCHASE / etc.
    // URGENT: Envoyer mail à chaque erreur

    static func handleUnknownError(error: Error, withFeedBack feedBack: Bool = false, completion: (() -> ())? = nil) {

        if feedBack {
            HelperAndKeys.showNotification(type: "E", title: "Erreur", message: error.desc.localized(), delay: 3)
        }

        let message = """
            Erreur Inconnu : \
            \tCode : \(error.code) \
            \tDomain : \(error.domain) \
            \tLocalizedDescription : \(error.localizedDescription) \
            \tLocalizedDescription 2 : \(error.desc.localized()) \
            \tShowed to user ? : \(feedBack)
        """
        Logger.logEvent(for: ParseErrorCodeHandler.className, message: message, level: .error)
        Logger.logEvent(for: ParseErrorCodeHandler.className, message: "Envoi de mail en cas d'erreur inactif", level: .warning)
        
        if (error.code == PFErrorCode.errorInvalidSessionToken.rawValue || error.code == PFErrorCode.errorFacebookInvalidSession.rawValue) {
            PFUser.logOut()
            Logger.logEvent(for: ParseErrorCodeHandler.className, message: "User logged out", level: .info)
            completion?()
        } else {
            Logger.logEvent(for: ParseErrorCodeHandler.className, message: "Sent event to crashlytics", level: .debug)
            Crashlytics.sharedInstance().recordError(error)
        }
//        MailHelper.sendErrorMail()
    }

    static func handleParseError(error: Error) -> String {
        switch error.code {
        case PFErrorCode.errorConnectionFailed.rawValue :
            Logger.logEvent(for: ParseErrorCodeHandler.className, message: error.localizedDescription + " code : \(error.code)", level: .error)
            return "Il y a eu un problème de connexion veuillez réessayer plus tard.".localized()
        case PFErrorCode.errorInvalidSessionToken.rawValue :
            PFUser.logOut()
            Logger.logEvent(for: ParseErrorCodeHandler.className, message: error.localizedDescription + " code : \(error.code)", level: .error)
            return "Il y a eu un problème de connexion veuillez réessayer.".localized()
        default:
            Logger.logEvent(for: ParseErrorCodeHandler.className, message: error.localizedDescription + " code : \(error.code)", level: .error)
            return error.localizedDescription + " code : \(error.code)"
        }
    }
}
