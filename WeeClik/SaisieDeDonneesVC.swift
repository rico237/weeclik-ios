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
//        profil_commerce
        
        if let navigation = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "profil_commerce") as? UINavigationController{
            
            presentFullScreen(viewController: navigation, animated: true, completion: nil)
        }
        
    }

    @IBAction func saveInfos(_ sender: Any) {
        guard let user = currentUser else { return }
        
        SVProgressHUD.show(withStatus: "Sauvegarde des informations".localized())
        if let name = nomPrenomTF.text { user["name"] = name }
        user["isPro"] = self.isPro
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
            destination.isPro = self.isPro
        }
    }
}

final class SignUpViewController: PFSignUpViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.signUpView?.logo = UIImageView(image: UIImage(named: "icon"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.signUpView?.logo?.frame = CGRect(x: (self.signUpView?.logo?.frame.origin.x)!, y: (self.signUpView?.logo?.frame.origin.y)! - 83, width: 167, height: 167)
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
