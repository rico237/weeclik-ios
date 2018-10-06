//
//  ProcessInscriptionVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 17/09/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

class ProcessInscriptionVC: UIViewController {
    var viewController : UIViewController? = nil
    var newUser : PFUser!
    var choosePro = false // false = tous les users -> Client
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let vc = viewController {
            vc.dismiss(animated: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? SaisieDeDonneesVC {
            let button = sender as! UIButton
            if button.tag == 100 {
                // Commercant
                choosePro = true
            } else {
                choosePro = false
            }
            
            vc.currentUser = newUser
            vc.isPro = choosePro
        }
    }
}
