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
    @IBOutlet weak var actualPasswordTF: FormTextField!
    @IBOutlet weak var newPasswordTF: FormTextField!
    @IBOutlet weak var confirmPasswordTF: FormTextField!
    
    var isPro = false
    var userProfilePicURL = ""          // Image de profil de l'utilisateur (uniquement facebook pour le moment)

    @IBOutlet weak var profilPicture: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePassword))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateProfilPic(forUser: currentUser!)
    }
    
    func updateProfilPic(forUser user: PFUser){
        // Regarde si une image de profil a été chargé
        // sinon si une image est lié via facebook
        // Sinon on affiche l'image de base weeclik
        if let profilFile = user["profilPicFile"] as? PFFileObject {
            if let url = profilFile.url {
                if url != "" {
                    self.userProfilePicURL = url
                }
            }
        } else if let profilPicURL = user["profilePictureURL"] as? String {
            if profilPicURL != "" {
                self.userProfilePicURL = profilPicURL
            }
        }
        
        if self.profilPicture != nil {
            
            self.profilPicture.layer.borderColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00).cgColor
            self.profilPicture.clipsToBounds = true
            
            if self.userProfilePicURL != "" {
                let placeholderImage = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
                self.profilPicture.sd_setImage(with: URL(string: self.userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload , completed: nil)
                self.profilPicture.layer.cornerRadius = self.profilPicture.frame.size.width / 2
                self.profilPicture.layer.borderWidth = 3
                self.profilPicture.layer.masksToBounds = true
            } else {
                self.profilPicture.layer.cornerRadius = 0
                self.profilPicture.layer.borderWidth = 0
                self.profilPicture.layer.masksToBounds = false
                self.profilPicture.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
            }
        }
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
