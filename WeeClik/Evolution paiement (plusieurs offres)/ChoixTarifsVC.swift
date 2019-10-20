//
//  ChoixTarifsVCViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 06/09/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import StoreKit

import Parse
import LGButton

class ChoixTarifsVC: UIViewController, IAPHandlerDelegate {
    func didFinishFetchAllProductFromParse(products: [PFProduct]) {self.parseProducts = products}
    @IBOutlet weak var back: UIView!

    let darkBlue  = UIColor(red:0.04, green:0.18, blue:1.00, alpha:1.00)
    let lightBlue = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.00)
    var parseProducts = [PFProduct]()

    @IBOutlet weak var choixTypeTarif: UISegmentedControl!
    @IBOutlet weak var backgroundGradient: LGButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // methods
        initViews()
        fetchProducts()

        changeBackgroundColorOnValueChange(control: self.choixTypeTarif)

        self.choixTypeTarif.addTarget(self, action: #selector(changeBackgroundColorOnValueChange), for: .valueChanged)
    }

    func fetchProducts() {
        InAppPurchaseHandler.shared.delegate = self
//        InAppPurchaseHandler.shared.fetchAvailableProducts()
        InAppPurchaseHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else { return }
            if type == .purchased {
                let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK".localized(), style: .default, handler: { (_) in

                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
            }
        }
    }

    func initViews() {
        backgroundGradient.shadowColor   = UIColor.black
        backgroundGradient.shadowOpacity = 1
    }

    // Value change
    @objc func changeBackgroundColorOnValueChange(control : UISegmentedControl) {
        print("Changed with selected index : \(control.selectedSegmentIndex)")
        UIView.animate(withDuration: 1, animations: {
            if control.selectedSegmentIndex == 0 {
                self.back.backgroundColor = UIColor(red:0.04, green:0.18, blue:1.00, alpha:1.00)
            } else {
                self.back.backgroundColor = UIColor(red:0.94, green:0.20, blue:0.17, alpha:1.00)
            }
        }, completion: nil)

//        backgroundGradient.layoutSubviews()
    }
}
