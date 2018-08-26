//
//  ChoixAbonnmentsVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 15/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

// Native Libs
import UIKit
import StoreKit

// CocoaPods Libs
import LGButton


class ChoixAbonnmentsVC: UIViewController {
    
    @IBOutlet weak var title_Annuel: UILabel!
    @IBOutlet weak var collectionView_Annuel: UICollectionView!
    
    var purchaseProducts = [SKProduct]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "PAIEMENT"
        
        InAppPurchaseHandler.shared.fetchAvailableProducts()
        InAppPurchaseHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else{ return }
            if type == .purchased {
                let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
            }
        }
        self.purchaseProducts = InAppPurchaseHandler.shared.getProductArray()
        
        //testButton.addTarget(self, action: #selector(consumable), for: .touchUpInside)
    }
    
    @objc func consumable(){
        print("Test")
        InAppPurchaseHandler.shared.purchaseMyProduct(index: 0)
    }
}

extension ChoixAbonnmentsVC : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PaymentCollectionCell_Annuel", for: indexPath) as! PaymentCollectionViewCell
        
        cell.backgroundImageView.layer.cornerRadius = 15
        cell.backgroundImageView.layer.masksToBounds = true
        
        return cell
    }
    
    func paiementActionForObjectId(identifier : String) {
        
    }
}




