//
//  ProcessInscriptionVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 17/09/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit

class ProcessInscriptionVC: UIViewController {
    
    var isPro = false
    
    @IBAction func utilisateurSelected(_ sender: Any) {isPro = false}
    @IBAction func commerceSelected(_ sender: Any) {isPro = true}
    
    func showNextPage(){
        // Show next page with isPro variable
        let saisie = SaisieDeDonneesVC()
        saisie.isPro = isPro
        self.show(saisie, sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
