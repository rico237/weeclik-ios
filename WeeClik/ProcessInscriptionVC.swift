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
    var viewController: UIViewController?
    var newUser: PFUser!
    var choosePro = false // false = tous les users -> Client

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let viewController = viewController else {
            return
        }
        viewController.dismiss(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let viewController = segue.destination as? SaisieDeDonneesVC else {
            return
        }
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
    }
}
