//
//  MonCompteVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 21/10/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD
import SwiftyStoreKit
import SPLarkController

class MonCompteVC: UIViewController {
    var isPro = false                   // Savoir si l'utilisateur est de type pro
    var hasPaidForNewCommerce = false   // Permet de savoir si on peut créer un nouveau commerce vers la BDD
    var isAdminUser = false
    var paymentEnabled = true
    
    var commerces : [PFObject]! = []    // La liste des commerces dans le BAAS
    var currentUser = PFUser.current()  // Utilisateur connecté
    
    let purchasedProductID = "abo.sans.renouvellement" // TODO: replace
    
    @IBOutlet weak var nouveauCommerceButton: UIButton!
    @IBOutlet weak var imageProfil : UIImageView!
    @IBOutlet weak var vueConnexion: UIView!
    @IBOutlet weak var gridView: UIView!
    @IBOutlet weak var changeProfilInfoTVC: UITableView!
    @IBOutlet weak var commercesTableView: UITableView!
    
    @IBOutlet weak var noCommerceView: UIView!
    @IBOutlet weak var noCommercesLabel: UILabel!
    
    // Contraintes du bouton de création d'un commerce
    @IBOutlet weak var buttonHeight: NSLayoutConstraint!
    @IBOutlet weak var rightButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftButtonConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: remove (test purpose)
//        isPro = true
        isAdminUser = true
        
        isProUpdateUI()
        if isAdminUser {
            self.navigationItem.leftBarButtonItems = [
                UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:))),
                UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettingsPanel))
            ]
        } else {
            self.navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:)))]
        }
        
    }
    
    @objc func showSettingsPanel(){
        let controller = AdminMonProfilSettingsVC(nibName: "AdminMonProfilSettingsVC", bundle: nil)
        
        let transitionDelegate = SPLarkTransitioningDelegate()
        transitionDelegate.customHeight = 185
        controller.transitioningDelegate = transitionDelegate
        controller.modalPresentationStyle = .custom
        controller.modalPresentationCapturesStatusBarAppearance = true
        self.present(controller, animated: true, completion: {
            print("completion finished")
            SPLarkController.updatePresentingController(parent: self)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("viewwill")
        
        do {
            try PFUser.current()?.fetch()
        } catch let error as NSError {
            print("Error catching user infos : \n Num : \(error.code) \nDescription : \(error.localizedDescription)")
        }
        
        if let current = PFUser.current() {
            self.currentUser = current
            
            // TODO: bouton uniquement pour les admins
//            if let isAdminUser = current["isAdmin"] as? Bool {
//                if isAdminUser {
//                    // true
//
//                }
//            }
            
            if let proUser = current["isPro"] as? Bool {
                // isPro is set
                isPro = proUser
                isProUpdateUI()
            } else {
                // Nil found
                // Redirect -> Choosing controller from pro statement
                let choosingNav = storyboard?.instantiateViewController(withIdentifier: "choose_type_compte") as! UINavigationController
                let choosingVC = choosingNav.topViewController as! ProcessInscriptionVC
                choosingVC.newUser = current
                self.present(choosingNav, animated: true, completion: nil)
            }
            
            if let vue = vueConnexion{
                vue.removeFromSuperview()
            }
            self.queryCommercesArrayBasedOnUser()
        }
    }
    
    func isProUpdateUI(){
//        print("Bouton height \(isPro)")
//        print("Is iPhone X : \(HelperAndKeys.isPhoneX)")
        
        if self.imageProfil != nil {
            self.imageProfil.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
        }
        
        if self.leftButtonConstraint != nil {
            self.leftButtonConstraint.constant  = HelperAndKeys.isPhoneX ? 16 : 0
        }
        
        if self.rightButtonConstraint != nil {
            self.rightButtonConstraint.constant = HelperAndKeys.isPhoneX ? 16 : 0
        }
        
        if self.buttonHeight != nil {
            self.buttonHeight.constant = isPro ? 50 : 0
        }

        if self.noCommercesLabel != nil {
            self.noCommercesLabel.text = isPro ? "Vous ne possedez aucun commerce pour le moment" : "Vous n'avez pour le moment partagé aucun commerce"
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        print("User is pro \(currentUser!["isPro"] as! Bool)")
        print("view did")
        paymentEnabled = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getPaymentKey(), withExpectedType: "bool") as? Bool ?? true
    }
    
    @IBAction func changeImageProfil(){
        // TODO: Change image profil
        print("Ajouter une fonction pour changer la photo de profil")
    }

    @IBAction func getBackToHome(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func logOut(_ sender: Any) {
        PFUser.logOutInBackground()
        self.dismiss(animated: true)
    }
    
    func updateUIBasedOnUser(){
        isProUpdateUI()
        self.changeProfilInfoTVC.reloadData()
        self.commercesTableView.reloadData()
    }
}

extension MonCompteVC : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.changeProfilInfoTVC{
            return "Mon profil"
        } else {
            if isPro {
                return "Mes commerces"
            }
            return "Mes Partages"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.changeProfilInfoTVC {
            return 1
        } else {
            if let comm = commerces {
                if comm.count == 0 {
                    isProUpdateUI()
                } else {
                    if let vue = noCommerceView {
                        vue.removeFromSuperview()
                    }
                }
            } else {
                return 0
            }
            
            return commerces.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.changeProfilInfoTVC {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emailChangeCell")
            
            if let user = PFUser.current() {
                cell?.textLabel?.text = (user["name"] != nil) ? user["name"] as? String : ""
                cell?.detailTextLabel?.text = user.email
            } else {
                cell?.textLabel?.text = "Nom Prénom"
                cell?.detailTextLabel?.text = "email"
            }
            
            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "commercesCell")
            let obj = Commerce(parseObject: self.commerces[indexPath.row])

            cell?.textLabel?.text = "\(obj.nom) - \(obj.partages) partages"
            cell?.detailTextLabel?.text = "\(obj.statut.description)"
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView ==  self.commercesTableView {
            // Afficher le détail d'un commerce
            let story = UIStoryboard(name: "Main", bundle: nil)
            if isPro {
                let ajoutCommerceVC = story.instantiateViewController(withIdentifier: "ajoutCommerce") as! AjoutCommerceVC
                ajoutCommerceVC.editingMode = true
                ajoutCommerceVC.objectIdCommerce = self.commerces[indexPath.row].objectId!
                self.navigationController?.pushViewController(ajoutCommerceVC, animated: true)
            } else {
                let detailViewController = story.instantiateViewController(withIdentifier: "DetailCommerceViewController") as! DetailCommerceViewController
                detailViewController.routeCommerceId = self.commerces[indexPath.row].objectId!
                self.navigationController?.pushViewController(detailViewController, animated: true)
            }
        }
    }
}

// Navigation related
extension MonCompteVC {
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        print("Identifier \(identifier) & paymentEnabled \(paymentEnabled)")

        if paymentEnabled {
            // Permet de verifier si l'user a payer avant la création d'un commerce
            if identifier == "ajoutCommerce" {
                buyProduct()
                return hasPaidForNewCommerce
            }
        }

        return true
    }
    
    func buyProduct(){
        SwiftyStoreKit.retrieveProductsInfo([self.purchasedProductID]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
                SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
                    // handle result (same as above)
                    switch result {
                    case .success(let product):
                        // fetch content from your server, then:
                        if product.needsFinishTransaction {
                            SwiftyStoreKit.finishTransaction(product.transaction)
                        }
                        print("Purchase Success: \(product.productId)")
                        self.processusPaiement()
                        // TODO: Sauvegarder la stat dans parse
                        break
                    case .error(let error):
                        switch error.code {
                        case .unknown: print("Unknown error. Please contact support")
                        case .clientInvalid: print("Not allowed to make the payment")
                        case .paymentCancelled: break
                        case .paymentInvalid: print("The purchase identifier was invalid")
                        case .paymentNotAllowed: print("The device is not allowed to make the payment")
                        case .storeProductNotAvailable: print("The product is not available in the current storefront")
                        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                        default: print((error as NSError).localizedDescription)
                        }
                    }
                }
            } else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(result.error)")
            }
        }
    }
    
    func testProduct(){
        PFPurchase.buyProduct("rFK3UKsB") { (error) in
            if let error = error {
                print(error)
            } else {
                HelperAndKeys.showAlertWithMessage(theMessage: "Acheté avec succès", title: "Validé", viewController: self)
            }
        }
    }
    
    func processusPaiement() -> Bool {
        // TODO: faire de vrai tests pour le paiement
        
        // [1] Effectuer la demande de paiement
        
        // [2] Verifier le retour
        
        // [3] Si payé -> crée un commerce vide
        if let currentUser = currentUser {
            let newCommerce = PFObject(className: "Commerce")
            newCommerce["nomCommerce"] = "Nouveau Commerce"
            newCommerce["statutCommerce"] = StatutType.unknown.hashValue as NSNumber
            newCommerce["brouillon"] = true
            newCommerce["owner"] = currentUser
//            newCommerce.acl = PFACL(user: currentUser)
            
//            do {
//                try newCommerce.save()
//            }
//            catch {
//                print("\(error.localizedDescription)")
//            }
            
            newCommerce.saveEventually { (success, error) in
                if let error = error {
                    HelperAndKeys.showAlertWithMessage(theMessage: error.localizedDescription, title: "Erreur création de commerce", viewController: self)
                } else {
                    if success {
                        // [4] Une fois la création faite -> afficher page de création de commerce
                        self.hasPaidForNewCommerce = true
                        self.performSegue(withIdentifier: "ajoutCommerce", sender: self.nouveauCommerceButton)
                        
                    } else {
                        HelperAndKeys.showAlertWithMessage(theMessage: "Erreur lors de la création d'un commerce merci de prendre contact rapidement avec l'équipe WeeClik.", title: "Erreur création de commerce", viewController: self)
                    }
                }
            }
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue. Vous semblez ne pas être connecté. Veuillez vous re-connecter. Puis recommencer votre achat.", title: "Problème de connexion", viewController: self)
        }
        
        return self.hasPaidForNewCommerce
    }
}

// Payment related
extension MonCompteVC {
    
}

// Data related
extension MonCompteVC {
    func queryCommercesArrayBasedOnUser(){
        if isPro {
            // Prend les commerces du compte pro
            let queryCommerce = PFQuery(className: "Commerce")
            queryCommerce.whereKey("owner", equalTo: currentUser as Any)
            queryCommerce.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])
            queryCommerce.findObjectsInBackground(block: { (objects, error) in
                if objects != nil {
                    self.commerces = objects
                    self.updateUIBasedOnUser()
                }
            })
        } else {
            // Prend les commerces favoris de l'utilisateur
            let queryCommerce = PFUser.query()
            queryCommerce?.whereKey("objectId", equalTo: currentUser?.objectId?.description as Any)
            queryCommerce?.getFirstObjectInBackground(block: { (obj, err) in
                //                    print("Nombre de commerces : \(objects?.count ?? 0)")
                self.commerces = obj!["mes_partages"] as? [PFObject]
                self.updateUIBasedOnUser()
            })
        }
    }
}

extension MonCompteVC : PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate{
    
    @IBAction func showParseUI(){
        // Login Part
        let logInController = LoginViewController()
        logInController.delegate = self
        logInController.fields = [PFLogInFields.usernameAndPassword,
                                  PFLogInFields.logInButton,
                                  PFLogInFields.signUpButton,
                                  PFLogInFields.passwordForgotten,
                                  PFLogInFields.dismissButton,
                                  PFLogInFields.facebook]
        logInController.emailAsUsername = true
        logInController.facebookPermissions = ["email", "public_profile"]
        
        // SignUp Part
        logInController.signUpController = SignUpViewController()
        logInController.signUpController?.delegate = self
        
        self.present(logInController, animated: true, completion: nil)
    }
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        if PFFacebookUtils.isLinked(with: user) {
            self.getFacebookInformations(user: user)
        }
        logInController.dismiss(animated: true)
    }
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        if let parseError = error{
            let nserror = parseError as NSError
            print("Erreur de login : \nCode (\(nserror.code))\n     -> \(nserror.localizedDescription)")
        }
    }
    
    // Inscription classique (par mail)
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?) {
        if let parseError = error{
            let nserror = parseError as NSError
            print("Erreur de signup : \nCode (\(nserror.code))\n     -> \(nserror.localizedDescription)")
        }
    }
    
    // Fonction pour definir des mots de passe trop faibles
    func signUpViewController(_ signUpController: PFSignUpViewController, shouldBeginSignUp info: [String : String]) -> Bool {
        print("Aucune conditions particulières pour le mot de passe")
        return true
    }
    
    func getFacebookInformations(user : PFUser) {
        
        let params = ["fields" : "email, name"]
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: params)
        
        graphRequest?.start(completionHandler: { (request, result, error) in
            //            let err = error! as NSError
            if (error == nil) {
                // handle successful response
                if let data = result as? [String:Any] {
                    user["name"] = data["name"] as! String
                    user["email"] = data["email"] as! String
                    let facebookId = data["id"] as! String
                    user["facebookId"] = facebookId
                    user["profilePictureURL"] = "https://graph.facebook.com/" + facebookId + "/picture?type=large&return_ssl_resources=1"
                    user.saveInBackground()
                }
            }
                //            else if (err.userInfo["error"]["type"] == "OAuthException") {
                //                // Since the request failed, we can check if it was due to an invalid session
                //                print("The facebook session was invalidated")
                //                PFFacebookUtils.unlinkUser(inBackground: PFUser.current()!)
                //            }
            else {
                print("Some other error: \(String(describing: error?.localizedDescription))")
            }
        })
    }
}
