//
//  MotDePasseVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 02/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

class MotDePasseVC: UIViewController {
    var currentUser = PFUser.current()
    var isPro = false
    @IBOutlet weak var actualPasswordTF: FormTextField!
    @IBOutlet weak var newPasswordTF: FormTextField!
    @IBOutlet weak var confirmPasswordTF: FormTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePassword))
    }

    @objc func savePassword() {
        guard let user = currentUser else {
            showBasicToastMessage(withMessage: "Nous n'arrivons à trouver le compte associé à votre profil".localized(), state: .error)
            return
        }
        
        actualPasswordTF.resignFirstResponder()
        newPasswordTF.resignFirstResponder()
        confirmPasswordTF.resignFirstResponder()
        
        if newPasswordTF.text != confirmPasswordTF.text {
           // Les nouveaux mot de passe ne sont pas identiques
           showBasicToastMessage(withMessage: "Votre nouveau mot de passe n'est pas identique avec la confirmation".localized(), state: .error)
        } else {
            PFUser.logInWithUsername(inBackground: (user.username ?? user.email) ?? "", password: actualPasswordTF.text ?? "") { (user, error) in
                if let error = error {
                    // Le mot de passe actuel est mauvais
                    ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: false) {
                        self.showBasicToastMessage(withMessage: "Le mot de passe saisie est incorrect".localized(), state: .error)
                    }
                } else if let user = user {
                    // Tout est bon alors on sauvegarde
                    user.password = self.newPasswordTF.text
                    user.saveInBackground()
                    // Affiche un message de confirmation
                    let alert = UIAlertController(title: "Modification enregistré".localized(),
                                                  message: "Votre nouveau mot de passe à bien été modifié".localized(),
                                                  preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok".localized(), style: .default, handler: { (_) in
                        self.navigationController?.popToRootViewController(animated: true)
                    })

                    alert.addAction(action)
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @IBAction func lostPassword(_ sender: Any) {
        guard let user = currentUser, let mail = user.email else {
            showBasicToastMessage(withMessage: "Nous n'arrivons à trouver le compte associé à votre profil".localized(), state: .error)
            return
        }
        PFUser.requestPasswordResetForEmail(inBackground: mail) { (succeeded, error) in
            if succeeded {
                self.showAlertWithMessage(message: "Un lien pour réinitialiser votre mot de passe vous à été envoyé sur la boite mail associé à votre compte".localized(),
                                     title: "Demande envoyé".localized(),
                                     completionAction: nil)
            } else if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            }
        }
    }
}
