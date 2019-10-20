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
        saveButton.backgroundColor = isPro ? UIColor(red:0.87, green:0.32, blue:0.32, alpha:1.00) : UIColor(red:0.32, green:0.71, blue:0.90, alpha:1.00)
        creationCompteLabel.text = isPro ? "Création d'un compte professionnel".localized() : "Création d'un compte utilisateur".localized()
        saveButton.layer.cornerRadius = 5
        mailTF.isEnabled = false
        mailTF.isUserInteractionEnabled = false
    }

    @IBAction func saveInfos(_ sender: Any) {
        print("Sauvegarde des infos utilisateur")
        self.initNewUser()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! UINavigationController
        if let destination = vc.viewControllers[0] as? MonCompteVC {
            destination.isPro = self.isPro
        }
    }

    func initNewUser() {
        if let user = currentUser {
            if let name = nomPrenomTF.text { user["name"] = name }
            user["mes_partages"] = []
            user["isPro"] = self.isPro
            user["inscriptionDone"] = true
            user["mes_partages_dates"] = []

            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.setDefaultStyle(.dark)
            SVProgressHUD.show(withStatus: "Sauvegarde des informations".localized())

            //TODO: utiliser la valeure success pour afficher un message d'erreur
            user.saveInBackground { (success, err) in
                if success {
                    SVProgressHUD.dismiss(withDelay: 1, completion: {
                        print("succesful signup : \(user.description)")
                        self.dismiss(animated: true, completion: nil)
                    })
                } else {
                    SVProgressHUD.dismiss(withDelay: 1, completion: {
                        let er = err! as NSError
                        print("Error de sauvegarde utilisateur : \n\t-> Code : \(er.code)\n\t-> Description : \(er.localizedDescription)")
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
        }
    }

}
