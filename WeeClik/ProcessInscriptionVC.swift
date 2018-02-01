//
//  ProcessInscriptionVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 17/09/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

class ProcessInscriptionVC: UIViewController {
    var viewController : UIViewController? = nil
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let vc = viewController {
            vc.dismiss(animated: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! SaisieDeDonneesVC
        if let ide = segue.identifier{
            if ide == "showCommerce" {dest.isPro = true}
        }
        
//        self.dismiss(animated: true)
    }
}
