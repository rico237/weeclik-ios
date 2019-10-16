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
    
    @objc func savePassword(){
        if newPasswordTF.text == confirmPasswordTF.text  && actualPasswordTF.text == currentUser?.password {
            // Tout est bon alors on sauvegarde
            currentUser?.password = newPasswordTF.text
            currentUser?.saveInBackground()
            // Affiche un message de confirmation
            let alert = UIAlertController(title: "Modification enregistré", message: "Votre nouveau mot de passe à bien été modifié", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: { (alert) in
                self.navigationController?.popToRootViewController(animated: true)
            })
            
            alert.addAction(action)
            self.present(alert, animated: true)
            
        } else if newPasswordTF.text != confirmPasswordTF.text {
            // Les nouveaux mot de passe ne sont pas identiques
            HelperAndKeys.showAlertWithMessage(theMessage: "Votre nouveau mot de passe n'est pas identique avec la confirmation", title: "Erreur", viewController: self)
        } else if actualPasswordTF.text != currentUser?.password{
            // Le mot de passe actuel est mauvais
            HelperAndKeys.showAlertWithMessage(theMessage: "Le mot de passe actuel saisie est incorrect", title: "Erreur", viewController: self)
        }
    }

    @IBAction func lostPassword(_ sender: Any) {
        PFUser.requestPasswordResetForEmail(inBackground: (currentUser?.email)!)
        HelperAndKeys.showAlertWithMessage(theMessage: "Un lien pour réinitialiser votre mot de passe vous à été envoyé sur la boite mail associé à votre compte", title: "Demande envoyé", viewController: self)
    }
}
