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
    var newUser: PFUser!
    var choosePro = false // false = tous les users -> Client
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PFUser.current()?.fetchInBackground(block: { (object, error) in
            if let error = error {
                Log.all.error("Error while fetching user data : \(error.debug)")
            } else if let user = object {
                let isPro = user["isPro"] as? Bool
                let inscriptionDone = user["inscriptionDone"] as? Bool
                
                if isPro != nil && inscriptionDone ?? false {
                    self.dismiss(animated: true)
                }
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let viewController = segue.destination as? SaisieDeDonneesVC else { return }
        if let button = sender as? UIButton {
            if button.tag == 100 {
                // Commercant
                choosePro = true
            } else {
                choosePro = false
            }
        }

        viewController.currentUser = newUser
        viewController.isPro = choosePro
        viewController.processInscriptionVC = self
    }
}
