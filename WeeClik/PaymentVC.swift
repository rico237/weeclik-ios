//  Created by Herrick Wolber on 17/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.

import UIKit
import Parse
import SwiftyStoreKit
import SPLarkController
import SwiftDate
import SVProgressHUD

class PaymentVC: UIViewController {
    // Check if we came for renewable or creation
    var commerceAlreadyExists = false
    // User making purchase
    var currentUser = PFUser.current()
    // Permet de savoir si on peut créer un nouveau commerce vers la BDD
    var hasPaidForNewCommerce = false
    // TEST VAR (permet de switcher la demande de paiement)
    var paymentDeactivated = false
    
    var scheduleVal = false
    // ObjectId of commerce if purchase was a success || commerce that wants to be renewed
    var renewingCommerceId = ""
    // Apple ID of one year subscription (not automatically renewed)
    var purchasedProductID: String {
        if ConfigurationManager.shared.target == "DEV" {
            return "abo.sans.renouvellement.dev"
        }
        return "abo.sans.renouvellement.un.an"
    }

    // Paneau d'aministration (option de paiement etc.)
    let panelController = AdminMonProfilSettingsVC(nibName: "AdminMonProfilSettingsVC", bundle: nil)
    // CGU, CGV, etc
    @IBOutlet weak var legalTextView: UITextView!

    @objc func showSettingsPanel() {
        let transitionDelegate = SPLarkTransitioningDelegate()
        transitionDelegate.customHeight = 185
        panelController.transitioningDelegate = transitionDelegate
        panelController.modalPresentationStyle = .custom
        panelController.modalPresentationCapturesStatusBarAppearance = true
        present(panelController, animated: true, completion: nil)
    }

    func updateAdminUI() {
        guard let current = currentUser else {
            navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:)))]
            return
        }
        // Recup le role de l'utilisateur (ex: admin)
        let adminRole = PFRole.query()
        adminRole?.whereKey("users", equalTo: current)
        adminRole?.findObjectsInBackground(block: { (results, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error)
            } else {
                if let results = results, let roles = results as? [PFRole] {
                    for role in roles where role.name == "admin" {
                        self.navigationItem.leftBarButtonItems = [
                            UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.getBackToHome(_:))),
                            UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(self.showSettingsPanel))
                        ]
                    }
                }
            }
        })
    }

    @IBAction func getBackToHome(_ sender: Any) {
        if commerceAlreadyExists {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PAIEMENT".localized()

        SVProgressHUD.setHapticsEnabled(true)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(1.5)

        updateCGUText()
        // Update UINavigationBar
        updateAdminUI()
    }

    func updateCGUText() {
        let style = NSMutableParagraphStyle()
        style.alignment = .justified

        let attributedString = NSMutableAttributedString(string: legalTextView.text)
        let urlCGU = URL(string: "\(Constants.Server.baseURL)/cgu")!
        let urlPolitique = URL(string: "\(Constants.Server.baseURL)/politique-confidentialite")!

        let cguRange = attributedString.mutableString.range(of: "Conditions générales".localized(), options: .caseInsensitive)
        attributedString.setAttributes([.link: urlCGU], range: cguRange)
        
        let politiqueRange = attributedString.mutableString.range(of: "Politique de Confidentialité".localized(), options: .caseInsensitive)
        attributedString.setAttributes([.link: urlPolitique], range: politiqueRange)

        legalTextView.isUserInteractionEnabled = true
        legalTextView.isEditable = false
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14), range: fullRange)

        legalTextView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.blue,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ] as [NSAttributedString.Key: Any]

        legalTextView.attributedText = attributedString
    }

    @IBAction func processPurchase(_ sender: Any) {
        paymentDeactivated = HelperAndKeys.getUserDefaultsValue(forKey: Constants.UserDefaultsKeys.paymentKey, withExpectedType: "bool") as? Bool ?? false
        scheduleVal = HelperAndKeys.getUserDefaultsValue(forKey: Constants.UserDefaultsKeys.scheduleKey, withExpectedType: "bool") as? Bool ?? false

        if !paymentDeactivated {
            // Permet de verifier si l'user a payer avant la création d'un commerce
            buyProduct()
        } else {
            if commerceAlreadyExists {
                renewCommerceEndDate()
            } else {
                newCommerce()
            }
        }
    }

    func renewCommerceEndDate() {
        let query = PFQuery(className: "Commerce")
        query.getObjectInBackground(withId: renewingCommerceId) { (commerce, error) in
            if let error = error {
                Log.all.error("Erreur retrieving commerce info - func renewCommerceEndDate")
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else if let commerce = commerce {
                let lastEndDate = commerce["endSubscription"] as? Date ?? Date()

                if lastEndDate.isBeforeDate(Date(), granularity: .minute) {
                    // isBefore today
                    commerce["endSubscription"] = self.scheduleVal ? Date() + 30.seconds : Date() + 1.years
                } else {
                    // isAfter today
                    commerce["endSubscription"] = self.scheduleVal ? lastEndDate + 30.seconds : lastEndDate + 1.years
                }

                commerce["statutCommerce"] = 1
                commerce.saveInBackground { (success, error) in
                    if success {
                        SVProgressHUD.showSuccess(withStatus: "Votre commerce a été renouvelé pour un an".localized())
                        // Commerce crée on sauvegarde les stats
                        self.saveStatForPurchase(forUser: self.currentUser!, andCommerce: commerce)
                        self.getBackToHome(self)
                    } else if let error = error {
                        Log.all.error("Erreur dans le renouvellement de l'abonnement du commerce")
                        ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
                        SVProgressHUD.showError(withStatus: "Erreur dans le renouvellement de l'abonnement du commerce".localized())
                    }
                }
            } else {
                SVProgressHUD.showError(withStatus: "Une erreur inconnue est arrivée durant le renouvellement".localized())
            }
        }
    }

    @IBAction func restorePurchase(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Chargement de vos achats".localized())
        SwiftyStoreKit.restorePurchases(atomically: false) { results in
            if !results.restoreFailedPurchases.isEmpty {
                print("Restore Failed: \(results.restoreFailedPurchases)")
                SVProgressHUD.showError(withStatus: "Erreur lors du chargement de vos achats".localized())
            } else if !results.restoredPurchases.isEmpty {
                for purchase in results.restoredPurchases where purchase.needsFinishTransaction {
                    // fetch content from your server, then:
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                print("Restore Success")
                SVProgressHUD.showSuccess(withStatus: "Vos achats ont été restaurés avec succès".localized())
            } else {
                print("Nothing to Restore")
                SVProgressHUD.showInfo(withStatus: "Aucun achat à restaurer".localized())
            }
        }
    }

    @IBAction func cancelPurchase(_ sender: Any) {
        getBackToHome(self)
    }

    func newCommerce() {
        SVProgressHUD.setStatus("Création de votre commerce".localized())
        // TODO: faire de vrai tests pour le paiement
        // [1] Effectuer la demande de paiement
        // [2] Verifier le retour
        // [3] Si payé -> crée un commerce vide
        if let currentUser = currentUser {
            let newCommerce = PFObject(className: "Commerce")
            newCommerce["nomCommerce"] = "Nouveau Commerce"
            newCommerce["statutCommerce"] = 1
            newCommerce["nombrePartages"] = 0
            newCommerce["brouillon"] = true
            newCommerce["typeCommerce"] = "Alimentaire"
            newCommerce["adresse"] = ""
            newCommerce["promotions"] = "Pas de promotions"
            newCommerce["siteWeb"] = ""
            newCommerce["mail"] = ""
            newCommerce["tel"] = ""
            newCommerce["description"] = "Pas de description"
            newCommerce["tags"] = []
            newCommerce["position"] = PFGeoPoint(latitude: 0, longitude: 0)
            newCommerce["owner"] = currentUser
            newCommerce["createdFromProject"] = "iOS"
            newCommerce.acl = ParseHelper.getUserACL(forUser: currentUser)
            
            if scheduleVal {
                newCommerce["endSubscription"] = Date() + 30.seconds
            } else {
                newCommerce["endSubscription"] = Date() + 1.years
            }

            newCommerce.saveInBackground { (success, error) in
                if let error = error {
                    self.showAlertWithMessage(message: error.localizedDescription, title: "Erreur création de commerce".localized(), completionAction: nil)
                    ParseErrorCodeHandler.handleUnknownError(error: error)
                    SVProgressHUD.dismiss()
                } else {
                    if success {
                        SVProgressHUD.showSuccess(withStatus: "Commerce crée avec succes".localized())
                        // Commerce crée on sauvegarde les stats
                        self.saveStatForPurchase(forUser: currentUser, andCommerce: newCommerce)
                        // [4] Une fois la création faite -> afficher page de création de commerce
                        SVProgressHUD.dismiss(withDelay: 1.5) {
                            self.getBackToHome(self)
                        }
                    } else {
                        self.showAlertWithMessage(message: "Erreur lors de la création d'un commerce merci de prendre contact rapidement avec l'équipe WeeClik.".localized(),
                                                  title: "Erreur création de commerce".localized(),
                                                  completionAction: nil)
                        SVProgressHUD.dismiss()
                    }
                }
            }
        } else {
            self.showAlertWithMessage(message: "Une erreur est survenue. Vous semblez ne pas être connecté. Veuillez vous re-connecter. Puis recommencer votre achat.".localized(),
                                      title: "Problème de connexion".localized(),
                                      completionAction: nil)
            SVProgressHUD.dismiss()
        }
    }

    func saveStatForPurchase(forUser user: PFUser, andCommerce commerce: PFObject) {

        let stat            = PFObject(className: "StatsPurchase")
        stat["user"]        = user
        stat["commerce"]    = commerce

        if let queryProduct = PFProduct.query() {
            queryProduct.whereKey("productIdentifier", equalTo: purchasedProductID)
            queryProduct.getFirstObjectInBackground(block: { (purchaseProduct, error) in
                if let purchaseProduct = purchaseProduct {
                    stat["typeAbonnement"]  = purchaseProduct
                    purchaseProduct.incrementKey("purchased")
                    purchaseProduct.saveInBackground { (_, error) in
                        if let error = error {
                            print("Error function retrieve PFProduct - func saveStatForPurchase")
                            ParseErrorCodeHandler.handleUnknownError(error: error)
                        }
                    }
                } else if let error = error {
                    print("Error function retrieve PFProduct - func saveStatForPurchase")
                    ParseErrorCodeHandler.handleUnknownError(error: error)
                }
            })
        }

        stat.saveInBackground { (_, error) in
            if let error = error {
                print("Error function save stat - func saveStatForPurchase")
                ParseErrorCodeHandler.handleUnknownError(error: error)
                SVProgressHUD.dismiss(withDelay: 1.5)
            }
        }
    }

    func buyProduct() {

        SVProgressHUD.show(withStatus: "Chargement du paiement".localized())
        SwiftyStoreKit.retrieveProductsInfo([purchasedProductID]) { result in
            SVProgressHUD.dismiss(withDelay: 1.5)

            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice ?? "Unknown"
                Log.all.verbose("Try to purchase product: \(product.localizedDescription), price: \(priceString)")
                SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in

                    switch result {
                    case .success(let product):
                        // fetch content from your server, then:
                        if self.commerceAlreadyExists {
                            self.renewCommerceEndDate()
                        } else {
                            self.newCommerce()
                        }

                        if product.needsFinishTransaction {
                            SwiftyStoreKit.finishTransaction(product.transaction)
                        }
                        Log.all.info("Purchase Success: \(product)")
                    case .error(let error):
                        switch error.code {
                        case .unknown:
                            SVProgressHUD.showError(withStatus: "Unknown error. Please contact support".localized())
                        case .clientInvalid:
                            SVProgressHUD.showError(withStatus: "Not allowed to make the payment".localized())
                        case .paymentCancelled:
                            break
                        case .paymentInvalid:
                            SVProgressHUD.showError(withStatus: "The purchase identifier was invalid".localized())
                        case .paymentNotAllowed:
                            SVProgressHUD.showError(withStatus: "The device is not allowed to make the payment".localized())
                        case .storeProductNotAvailable:
                            SVProgressHUD.showError(withStatus: "The product is not available in the current storefront".localized())
                        case .cloudServicePermissionDenied:
                            SVProgressHUD.showError(withStatus: "Access to cloud service information is not allowed".localized())
                        case .cloudServiceNetworkConnectionFailed:
                            SVProgressHUD.showError(withStatus: "Could not connect to the network".localized())
                        case .cloudServiceRevoked:
                            SVProgressHUD.showError(withStatus: "User has revoked permission to use this cloud service".localized())
                        default:
                            SVProgressHUD.showError(withStatus: (error as NSError).localizedDescription)
                        }
                        
                        let errorMessage = """
                            
                            Error while purchasing item \(product.localizedDescription), price: \(priceString)
                        
                            Error description :
                                Code: \(error.code)
                                Description: \(error.localizedDescription)
                                Desc: \(error.desc)
                        
                        """
                        // Log only if is not canceled
                        if error.code == .paymentCancelled {
                            Log.all.verbose("User canceled or enum's default")
                        } else {
                            Log.all.error(errorMessage)
                            ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: false) // TODO: change it is not a parse error
                        }
                    }
                }
            } else if let invalidProductId = result.invalidProductIDs.first {
                Log.all.error("Invalid product identifier: \(invalidProductId)")
                ParseErrorCodeHandler.handleUnknownError(error:
                    NSError(domain: "PaymentVC",
                            code: 404,
                            userInfo: ["invalid_product_identifier": "Product identifier is invalid : \(invalidProductId)"])
                )
            } else {
                Log.all.error("Error: \(String(describing: result.error))")
                ParseErrorCodeHandler.handleUnknownError(error: result.error ?? NSError.init(domain: "Purchase", code: 999, userInfo: nil),
                                                         withFeedBack: false)
            }
        }

    }
}
