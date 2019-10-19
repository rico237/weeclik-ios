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
import Parse

class ChoixAbonnmentsVC: UIViewController, IAPHandlerDelegate {
    func didFinishFetchAllProductFromParse(products: [PFProduct]) {
        self.parseProducts = products
        self.collectionView_Annuel.reloadData()
    }
    
    
    @IBOutlet weak var title_Annuel: UILabel!
    @IBOutlet weak var collectionView_Annuel: UICollectionView!
    
    var purchaseProducts = [SKProduct]()
    var parseProducts = [PFProduct]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "PAIEMENT".localized()
        
        InAppPurchaseHandler.shared.delegate = self
        InAppPurchaseHandler.shared.fetchAvailableProducts()
        InAppPurchaseHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else{ return }
            if type == .purchased {
                let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK".localized(), style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
            }
        }
        //testButton.addTarget(self, action: #selector(consumable), for: .touchUpInside)
    }
    
    @objc func consumable(){
        InAppPurchaseHandler.shared.purchaseMyProduct(index: 0)
    }
}

extension ChoixAbonnmentsVC : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.parseProducts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PaymentCollectionCell_Annuel", for: indexPath) as! PaymentCollectionViewCell
        
        let product = WeeClikProducts(withPFProduct: self.parseProducts[indexPath.row])
        
        cell.backgroundImageView.layer.cornerRadius = 15
        cell.backgroundImageView.layer.masksToBounds = true
        
        cell.priceViewLGButton.titleString = "\(product.price)€".localized()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let obj = self.parseProducts[indexPath.row]
        InAppPurchaseHandler.shared.purchaseMyProductById(identifier: obj.productIdentifier!)
    }
}




