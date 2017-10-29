//
//  SaisieDeDonneesVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 20/09/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4

class SaisieDeDonneesVC: UIViewController {
    var isPro = false
    var currentUser = PFUser.current()!
    var facebookConnection = false
    
    @IBOutlet var logoUser: UIImageView!
    @IBOutlet weak var nomPrenomTF: FormTextField!
    @IBOutlet weak var mailTF: FormTextField!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        facebookConnection = PFFacebookUtils.isLinked(with: currentUser)
        logoUser.image = isPro ? UIImage(named: "Logo_commerce") : UIImage(named: "Logo_utilisateur")
        saveButton.backgroundColor = isPro ? UIColor(red:0.87, green:0.32, blue:0.32, alpha:1.00) : UIColor(red:0.32, green:0.71, blue:0.90, alpha:1.00)
        saveButton.layer.cornerRadius = 5
        mailTF.isEnabled = false
        
        
        if facebookConnection {
            // Connecté grâce à Facebook
            nomPrenomTF.text = currentUser["name"] as? String
            mailTF.text = currentUser["email"] as? String
        }
    }
    
    @IBAction func saveInfos(_ sender: Any) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        currentUser["email"] = mailTF.text
        currentUser["name"] = nomPrenomTF.text
        currentUser.saveInBackground()
        let vc = segue.destination as! UINavigationController
        let destination = vc.viewControllers[0] as! MonCompteVC
        destination.isPro = isPro
    }

}
