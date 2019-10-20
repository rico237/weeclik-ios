//
//  InAppPurchaseHandler.swift
//  WeeClik
//
//  Created by Herrick Wolber on 15/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import StoreKit
import Parse

enum IAPHandlerAlertType {
    case disabled
    case restored
    case purchased
    case failed

    func message() -> String {
        switch self {
            case .disabled: return "Les achats sont désactivés sur votre appareil".localized()
            case .restored: return "Votre abonnement à bien été restauré !".localized()
            case .purchased: return "Vous avez bien soucrit à l'abonnement annuel !".localized()
            case .failed: return "Un problème est arrivé durant l'achat! Merci de réessayer plus tard.".localized()
        }
    }
}

protocol IAPHandlerDelegate: class {
    func didFinishFetchAllProductFromParse(products: [PFProduct])
}

class InAppPurchaseHandler: NSObject {
    static let shared = InAppPurchaseHandler()

    weak var delegate: IAPHandlerDelegate?

    var productIds = [String]()
    var parseProducts = [PFProduct]()
    var productBeingPurchased: PFProduct!

    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var iapProducts = [SKProduct]()

    var purchaseStatusBlock: ((IAPHandlerAlertType) -> Void)?

    // MARK: - MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }

    func getProductArray() -> [SKProduct] { return iapProducts }

    func getParseProductsArray() -> [PFProduct] {return parseProducts}

    func purchaseMyProduct(index: Int) {
        if iapProducts.count == 0 { return }

        if self.canMakePurchases() {
            let product = iapProducts[index]
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)

            print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            productID = product.productIdentifier
        } else {
            purchaseStatusBlock?(.disabled)
        }
    }

    func purchaseMyProductById(identifier: String) {
        if iapProducts.count == 0 { return }

        if self.canMakePurchases() {
            if let index = productIds.firstIndex(of: identifier) {
                let product = iapProducts[index]
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(self)
                SKPaymentQueue.default().add(payment)

                print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
                productID = product.productIdentifier
            }
        } else {
            purchaseStatusBlock?(.disabled)
        }
    }

    // Changed to use index of string and search for the matching SKProduct
    func purchaseMyProduct(indexString: String) {
        if iapProducts.count == 0 { return }

        if self.canMakePurchases() {
            var product = iapProducts[0]
            var continue_action = false

            for products in iapProducts {
                if (products.productIdentifier == indexString) {
                    product = products
                    continue_action = true
                    break
                }
            }

            if (continue_action) {
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(self)
                SKPaymentQueue.default().add(payment)

                print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
                productID = product.productIdentifier
            }
        } else {
            purchaseStatusBlock?(.disabled)
        }
    }

    // MARK: - RESTORE PURCHASE
    func restorePurchase() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    // MARK: - FETCH AVAILABLE IAP PRODUCTS
    func fetchAvailableProducts() {
        let set = NSMutableSet()
        let query = PFProduct.query()

        query?.findObjectsInBackground(block: { (products, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error)
            } else if let products = products {
                for obj in products {
                    let product = obj as! PFProduct
                    self.parseProducts.append( product )
                    set.add(product.productIdentifier!)
                }
                self.delegate?.didFinishFetchAllProductFromParse(products: self.parseProducts)
            }
        })

        productsRequest = SKProductsRequest(productIdentifiers: set as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }

    func updatePurchaseParseObject() {
        let query = PFProduct.query()
        query?.findObjectsInBackground(block: { (products, error) in
            if let error = error as NSError? {
                print("Error : \n\tCode : \(error.code)\n\tMessage : \(error.localizedDescription)")
            } else if let products = products as? [PFProduct] {
                for prod in products {
                    if prod.productIdentifier == "" {
                        prod.incrementKey("purchased")
                        prod.saveEventually()
                    }
                }
            }
        })
    }
}

extension InAppPurchaseHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // MARK: - REQUEST IAP PRODUCTS
    func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        if (response.products.count > 0) {
            iapProducts = response.products
            for product in iapProducts {
                print("\n------------------------------------------------------")
                productIds.append(product.productIdentifier)
                let numberFormatter = NumberFormatter()
                numberFormatter.formatterBehavior = .behavior10_4
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = product.priceLocale
                let price1Str = numberFormatter.string(from: product.price)
                print("Produit : \n\tAppStore Id -> " + product.productIdentifier + "\n\tDescription -> " + product.localizedDescription + "\n\tPrix -> \(price1Str!)")
                print("------------------------------------------------------\n")
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        purchaseStatusBlock?(.restored)
    }

    // MARK: - IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    print("purchased")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
//                    updatePurchaseParseObject(object: productBeingPurchased)
                    purchaseStatusBlock?(.purchased)
                    break

                case .failed:
                    print("failed")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
//                    purchaseStatusBlock?(.failed)
                    break
                case .restored:
                    print("restored")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
//                    purchaseStatusBlock?(.restored)
                    break

                default: break
                }
            }
        }
    }
}
