//: [Previous](@previous)

import Foundation
import SwiftyStoreKit

let sharedSecret = "702ebb787a9248aaa4a340d2e92d68c9"

func verifyPurchases(with id: String, sharedSecret: String) {
    let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecret)
    SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
        switch result {
        case .success(let receipt):
            let productId = id
            // Verify the purchase of Consumable or NonConsumable
            let purchaseResult = SwiftyStoreKit.verifyPurchase(
                productId: productId,
                inReceipt: receipt)

            switch purchaseResult {
            case .purchased(let receiptItem):
                print("\(productId) is purchased: \(receiptItem)")
            case .notPurchased:
                print("The user has never purchased \(productId)")
            }
        case .error(let error):
            print("Receipt verification failed: \(error)")
        }
    }
}

func verifySubscription(withId id: String, sharedSecret: String) {
    let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecret)
    SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
        switch result {
        case .success(let receipt):
            let productId = id
            // Verify the purchase of a Subscription
            let purchaseResult = SwiftyStoreKit.verifySubscription(
                //ofType: .nonRenewing(validDuration: 60*60 * 24*30 * 365) // 1 an
                ofType: .nonRenewing(validDuration: 30) // 30 sec
                productId: productId,
                inReceipt: receipt)

            switch purchaseResult {
            case .purchased(let expiryDate, let items):
                print("\(productId) is valid until \(expiryDate)\n\(items)\n")
            case .expired(let expiryDate, let items):
                print("\(productId) is expired since \(expiryDate)\n\(items)\n")
            case .notPurchased:
                print("The user has never purchased \(productId)")
            }

        case .error(let error):
            print("Receipt verification failed: \(error)")
        }
    }
}

//: [Next](@next)
