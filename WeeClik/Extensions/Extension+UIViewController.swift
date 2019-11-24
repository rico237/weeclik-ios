//
//  Extension+UIViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 24/11/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import Loaf
import MessageUI

// MARK: Alerts
extension UIViewController {
    func showAlertWithMessage(message: String, title: String, completionAction: (() -> Void)?) {
        let alertViewController = UIAlertController(title: title.localized(), message: message.localized(), preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction(title: "OK".localized(), style: .cancel) { (_:UIAlertAction) -> Void in
            completionAction?()
            alertViewController.dismiss(animated: true, completion: nil)
        }
        alertViewController.addAction(defaultAction)
        present(alertViewController, animated: true, completion: nil)
    }

    func showSettingsAlert(withTitle title: String, withMessage message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Réglages".localized(), style: .default) { (_:UIAlertAction) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            } else {
                self.showBasicToastMessage(withMessage: "Impossibilité d'ouvrir les réglages de votre appareil.".localized(), state: .error)
            }
        }
        let cancelAction = UIAlertAction(title: "Annuler".localized(), style: .default) { (_:UIAlertAction) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func visitWebsite(urlString: String) {

        let alertViewController = UIAlertController.init(title: "Sortir de l'application ?".localized(), message: "Vous allez être redirigé vers le site web du commerçant.\n Et ainsi quitter l'application Weeclik.\n Voulez vous continuer ?".localized(), preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction.init(title: "OK".localized(), style: UIAlertAction.Style.default) { (_:UIAlertAction) -> Void in
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                self.showBasicToastMessage(withMessage: "Impossibilité d'ouvrir le site web associé.".localized(), state: .error)
            }
        }
        let cancelAction = UIAlertAction.init(title: "Annuler".localized(), style: UIAlertAction.Style.destructive) {(_:UIAlertAction) -> Void in
            alertViewController.dismiss(animated: true, completion: nil)
        }
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(defaultAction)
        present(alertViewController, animated: true, completion: nil)
    }
    
    func showInputDialog(title: String? = nil,
                         subtitle: String? = nil,
                         actionTitle: String? = "OK".localized(),
                         cancelTitle: String? = "Annuler".localized(),
                         inputPlaceholder: String? = nil,
                         inputKeyboardType: UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {

        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField: UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .destructive, handler: { (_:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: Toasts
extension UIViewController {
    func showToastMessage(withMessage message: String, state: Loaf.State = .info, location: Loaf.Location = .bottom, presentationDir: Loaf.Direction, dismissDir: Loaf.Direction) {
        Loaf(message, state: state, location: location, presentingDirection: presentationDir, dismissingDirection: dismissDir, sender: self).show()
    }

    func showBasicToastMessage(withMessage message: String, state: Loaf.State = .info) {
        Loaf(message, state: state, location: .bottom, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
    }
}

// MARK: iOS 12 FullScreen
extension UIViewController {
    func presentFullScreen(viewController: UIViewController, animated: Bool = true, completion:(() -> Void)?) {
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: animated, completion: completion)
    }
}
