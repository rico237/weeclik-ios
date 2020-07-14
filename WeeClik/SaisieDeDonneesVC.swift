//
//  SaisieDeDonneesVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 20/09/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD
import Loaf

class SaisieDeDonneesVC: UIViewController {
    var isPro: Bool!
    var currentUser = PFUser.current()
    var facebookConnection = false

    @IBOutlet weak var creationCompteLabel: UILabel!
    @IBOutlet weak var logoUser: UIImageView!
    @IBOutlet weak var nomPrenomTF: FormTextField!
    @IBOutlet weak var mailTF: FormTextField!
    @IBOutlet weak var saveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setDefaultStyle(.dark)

        if let user = currentUser {
            if PFFacebookUtils.isLinked(with: user) {
                // Connecté grâce à Facebook
                nomPrenomTF.text = user["name"] as? String
                mailTF.text = user["email"] as? String
            } else {
                mailTF.text = user.email
            }
        } else {
            currentUser = PFUser()
        }

        logoUser.image = isPro ? UIImage(named: "Logo_commerce") : UIImage(named: "Logo_utilisateur")
        saveButton.backgroundColor = isPro ? UIColor(red: 0.87, green: 0.32, blue: 0.32, alpha: 1.00) : UIColor(red: 0.32, green: 0.71, blue: 0.90, alpha: 1.00)
        creationCompteLabel.text = isPro ? "Création d'un compte professionnel".localized() : "Création d'un compte utilisateur".localized()
        saveButton.layer.cornerRadius = 5
        mailTF.isEnabled = false
        mailTF.isUserInteractionEnabled = false
    }
    
    func hideViewController() {
        if self.presentingViewController != nil {
            self.dismiss(animated: false, completion: {
               self.navigationController!.popToRootViewController(animated: true)
            })
        } else {
            self.navigationController!.popToRootViewController(animated: true)
        }
    }

    @IBAction func saveInfos(_ sender: Any) {
        guard let user = currentUser else { return }
        
        nomPrenomTF.resignFirstResponder()
        
        SVProgressHUD.show(withStatus: "Sauvegarde des informations".localized())
        if let name = nomPrenomTF.text { user["name"] = name }
        user["isPro"] = isPro
        user["inscriptionDone"] = true

        user.saveInBackground { (success, error) in
            if success {
                SVProgressHUD.dismiss(withDelay: 1, completion: {
                    self.showBasicToastMessage(withMessage: "Profil sauvegardé avec succès", state: .success)
                    Log.all.info("succesful signup : \(user.description)")
                    self.hideViewController()
                })
            } else {
                SVProgressHUD.dismiss(withDelay: 1, completion: {
                    if let error = error {
                        self.showBasicToastMessage(withMessage: "Erreur de sauvegarde de votre profil. Réessayer ultérieurement",
                                                   state: .error)
                        Log.all.warning("""
                            
                            Error de sauvegarde utilisateur :
                                Code : \(error.code)
                                Description : \(error.desc)
                            
                        """)
                        self.hideViewController()
                    }
                })
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigation  = segue.destination as? UINavigationController,
           let destination = navigation.viewControllers[0] as? MonCompteVC {
            
            destination.isPro = isPro
        }
    }
}

final class SignUpViewController: PFSignUpViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        signUpView?.logo = UIImageView(image: UIImage(named: "icon"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let logoFrame = signUpView?.logo?.frame else { return }
        
        signUpView?.logo?.frame = CGRect(x: logoFrame.origin.x, y: logoFrame.origin.y - 83, width: 167, height: 167)
    }
}

final class LoginViewController: PFLogInViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.logInView?.logo = UIImageView(image: UIImage(named: "icon"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.logInView?.logo?.frame = CGRect(x: (self.logInView?.logo?.frame.origin.x)!, y: (self.logInView?.logo?.frame.origin.y)! - 83, width: 167, height: 167)
    }
}

final class ParseLoginSignupHelper {
    static func parseLoginViewController() -> PFLogInViewController {
        let logInController = LoginViewController()
        logInController.fields = [.usernameAndPassword,
                                  .logInButton,
                                  .signUpButton,
                                  .passwordForgotten,
                                  .dismissButton,
                                  .facebook]
        logInController.emailAsUsername = true
        logInController.facebookPermissions = ["email", "public_profile"]
        logInController.modalPresentationStyle = .fullScreen

        // SignUp Part
        logInController.signUpController = SignUpViewController()
        logInController.signUpController?.fields = [.usernameAndPassword,
                                                    .signUpButton,
                                                    .additional,
                                                    .dismissButton]
        logInController.signUpController?.signUpView?.usernameField?.keyboardType = .emailAddress
        logInController.signUpController?.signUpView?.additionalField?.isSecureTextEntry = true
        logInController.signUpController?.signUpView?.additionalField?.keyboardType = .alphabet
        logInController.signUpController?.signUpView?.usernameField?.placeholder = "Email".localized()
        logInController.signUpController?.signUpView?.additionalField?.placeholder = "Confirmation du mot de passe".localized()
        logInController.signUpController?.modalPresentationStyle = .fullScreen
        return logInController
    }
}
