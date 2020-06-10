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
//        let fields = [actualPasswordTF, newPasswordTF, confirmPasswordTF]
//        for tf in fields {
//            if let tf = tf {
//                tf.addTarget(self, action: #selector(AjoutCommerceVC.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
//            }
//        }
//        actualPasswordTF.tag = 100
//        newPasswordTF.tag = 200
//        confirmPasswordTF.tag = 300
    }

    @objc func savePassword() {
        guard let user = currentUser else {
            showBasicToastMessage(withMessage: "Nous n'arrivons à trouver le compte associé à votre profil".localized(), state: .error)
            return
        }
        if newPasswordTF.text == confirmPasswordTF.text  && actualPasswordTF.text == user.password {
            // Tout est bon alors on sauvegarde
            user.password = newPasswordTF.text
            user.saveInBackground()
            // Affiche un message de confirmation
            let alert = UIAlertController(title: "Modification enregistré".localized(),
                                          message: "Votre nouveau mot de passe à bien été modifié".localized(),
                                          preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok".localized(), style: .default, handler: { (_) in
                self.navigationController?.popToRootViewController(animated: true)
            })

            alert.addAction(action)
            present(alert, animated: true)

        } else if newPasswordTF.text != confirmPasswordTF.text {
            // Les nouveaux mot de passe ne sont pas identiques
            showBasicToastMessage(withMessage: "Votre nouveau mot de passe n'est pas identique avec la confirmation".localized(), state: .error)
        } else if actualPasswordTF.text != user.password {
            // Le mot de passe actuel est mauvais
            showBasicToastMessage(withMessage: "Le mot de passe saisie est incorrect".localized(), state: .error)
        }
    }

    @IBAction func lostPassword(_ sender: Any) {
        guard let user = currentUser,
              let mail = user.email
        else {
            showBasicToastMessage(withMessage: "Nous n'arrivons à trouver le compte associé à votre profil".localized(), state: .error)
            return
        }
        PFUser.requestPasswordResetForEmail(inBackground: mail)
        showAlertWithMessage(message: "Un lien pour réinitialiser votre mot de passe vous à été envoyé sur la boite mail associé à votre compte".localized(),
                             title: "Demande envoyé".localized(),
                             completionAction: nil)
    }

//    @objc func textFieldDidChange(_ textField: UITextField) {
//        guard let text = textField.text else {
//            return
//        }
//        self.checkFormValidity(textField: textField, text: text)
//    }
//
//    func checkFormValidity(textField: UITextField, text: String) -> Bool {
//        case 100: // actual password
//            if text.count < 4 { return false}
//        case 200: // new password
//            if text
//        case 300: // confirmation password
//        default:  // Never called
//            break
//        }
//        return true
//    }
}
