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
import SwiftDate

class MonCompteVC: UIViewController {
    var isPro = false                   // Savoir si l'utilisateur est de type pro
    var hasPaidForNewCommerce = false   // Permet de savoir si on peut créer un nouveau commerce vers la BDD
    var isAdminUser = false             // TEST VAR Permet d'afficher les options admins
    var paymentEnabled = true           // TEST VAR (permet de switcher la demande de paiement)
    
    var userProfilePicURL = ""          // Image de profil de l'utilisateur (uniquement facebook pour le moment)
    
    var commerces : [PFObject]! = []    // La liste des commerces dans le BAAS
    var currentUser = PFUser.current()  // Utilisateur connecté
    
    var newCommerceID = ""
    
    let purchasedProductID = "abo.sans.renouvellement" // TODO: replace (ID du produit apple a acheter)
    
    let panelController = AdminMonProfilSettingsVC(nibName: "AdminMonProfilSettingsVC", bundle: nil) // Paneau d'aministration (option de paiement etc.)
    
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
//        isAdminUser = true
        
        isProUpdateUI() // Update liste of commerce for pro users
        updateAdminUI() // Update UINavigationBar
    }
    
    @objc func showSettingsPanel(){
        let transitionDelegate = SPLarkTransitioningDelegate()
        transitionDelegate.customHeight = 185
        panelController.transitioningDelegate = transitionDelegate
        panelController.modalPresentationStyle = .custom
        panelController.modalPresentationCapturesStatusBarAppearance = true
        self.present(panelController, animated: true, completion: nil)
    }
    
    func updateAdminUI(){
        if isAdminUser {
            self.navigationItem.leftBarButtonItems = [
                UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:))),
                UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(showSettingsPanel))
            ]
        } else {
            self.navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:)))]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            try PFUser.current()?.fetch()
        } catch let error as NSError {
            print("Error catching user infos : \n Num : \(error.code) \nDescription : \(error.localizedDescription)")
        }
        
        if let current = PFUser.current() {
            self.currentUser = current
            
            // Regarde si une image de profil a été chargé
            // Sinon on affiche l'image de base weeclik
            if let profilPicURL = currentUser!["profilePictureURL"] as? String {
                if profilPicURL != "" {
                    self.userProfilePicURL = profilPicURL
                }
            }
            
            // Recup le role de l'utilisateur (ex: admin)
            let adminRole = PFRole.query()
            adminRole?.whereKey("users", equalTo: current)
            adminRole?.findObjectsInBackground(block: { (results, error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    if let results = results {
                        let roles = results as! [PFRole]
                        for role  in roles {
                            if role.name == "admin" {
                                self.isAdminUser = true
                                self.updateAdminUI()
                            }
                        }
                    }
                }
            })
            
            // Recup si l'utilisateur est un pro (commercant)
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
            
            // Récupère ces commerces (favoris si utilisateur normal)
            self.queryCommercesArrayBasedOnUser()
        }
    }
    
    func isProUpdateUI(){
//        print("Bouton height \(isPro)")
//        print("Is iPhone X : \(HelperAndKeys.isPhoneX)")
        
        if self.imageProfil != nil {
            
            self.imageProfil.layer.borderColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00).cgColor
            
            if self.userProfilePicURL != "" {
                let placeholderImage = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
                self.imageProfil.sd_setImage(with: URL(string: self.userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload , completed: nil)
                self.imageProfil.layer.cornerRadius = self.imageProfil.frame.size.width / 2
                self.imageProfil.clipsToBounds = true
                self.imageProfil.layer.borderWidth = 3
                self.imageProfil.layer.masksToBounds = true
            } else {
                self.imageProfil.layer.cornerRadius = 0
                self.imageProfil.clipsToBounds = true
                self.imageProfil.layer.borderWidth = 0
                self.imageProfil.layer.masksToBounds = false
                self.imageProfil.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
            }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ajoutCommerce" {
            let ajoutCommerceVC = segue.destination as! AjoutCommerceVC
            ajoutCommerceVC.editingMode = true
            ajoutCommerceVC.objectIdCommerce = self.newCommerceID
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        paymentEnabled = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getPaymentKey(), withExpectedType: "bool") as? Bool ?? true
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
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Chargement du paiement")
        
        SwiftyStoreKit.retrieveProductsInfo([self.purchasedProductID]) { result in
            
            
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
                SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
                    
                    SVProgressHUD.dismiss()
                    
                    switch result {
                    case .success(let product):
                        // fetch content from your server, then:
                        self.processusPaiement()
                        if product.needsFinishTransaction {
                            SwiftyStoreKit.finishTransaction(product.transaction)
                        }
                        print("Purchase Success: \(product.productId)")
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
                print("Error: \(String(describing: result.error))")
            }
        }
    }
    
    func saveStatForPurchase(forUser user: PFUser, andCommerce commerce: PFObject){
        let stat            = PFObject(className: "StatsPurchase")
        stat["user"]        = user
        stat["commerce"]    = commerce
        
        if let queryProduct = PFProduct.query() {
            queryProduct.whereKey("productIdentifier", equalTo: self.purchasedProductID)
            
            if let product = try? queryProduct.findObjects().last as? PFProduct {
                stat["typeAbonnement"]  = product
            }
        }
        
//        if let queryRole = PFRole.query() {
//            queryRole.whereKey("name", equalTo: "admin")
//            if let adminRole = try? queryRole.findObjects().first as? PFRole {
//                let acl = PFACL()
//                acl.setReadAccess(true, for: adminRole)
//                acl.setWriteAccess(true, for: adminRole)
//                stat.acl = acl
//            }
//        }
        
        stat.saveInBackground { (success, error) in
            
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error)
            } else {
                if !success {
                    // TODO: Nous envoyer une notification sur le sujet du pb
                }
            }
        }
    }
    
    func processusPaiement() {
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
            newCommerce["promotions"] = ""
            newCommerce["photoSlider"] = []
            newCommerce["siteWeb"] = ""
            newCommerce["mail"] = ""
            newCommerce["tel"] = ""
            newCommerce["description"] = ""
            newCommerce["videos"] = []
            newCommerce["tags"] = []
            newCommerce["position"] = PFGeoPoint(latitude: 0, longitude: 0)
            newCommerce["owner"] = currentUser
            
            let testPurpose = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getScheduleKey(), withExpectedType: "bool") as? Bool ?? false
            if testPurpose {
                newCommerce["endSubscription"] = Date() + 30.seconds
            } else {
                newCommerce["endSubscription"] = Date() + 1.years
            }
            
            newCommerce.acl = PFACL(user: currentUser)
            
            newCommerce.saveInBackground { (success, error) in
                if let error = error {
                    HelperAndKeys.showAlertWithMessage(theMessage: error.localizedDescription, title: "Erreur création de commerce", viewController: self)
                } else {
                    if success {
                        // Commerce crée on sauvegarde les stats
                        self.newCommerceID = newCommerce.objectId!
                        self.saveStatForPurchase(forUser: currentUser, andCommerce: newCommerce)
                        self.queryCommercesArrayBasedOnUser()
                        // [4] Une fois la création faite -> afficher page de création de commerce
                        self.hasPaidForNewCommerce = true
                        self.performSegue(withIdentifier: "ajoutCommerce", sender: self)
                    } else {
                        HelperAndKeys.showAlertWithMessage(theMessage: "Erreur lors de la création d'un commerce merci de prendre contact rapidement avec l'équipe WeeClik.", title: "Erreur création de commerce", viewController: self)
                    }
                }
            }
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue. Vous semblez ne pas être connecté. Veuillez vous re-connecter. Puis recommencer votre achat.", title: "Problème de connexion", viewController: self)
        }
    }
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
//        logInController.signUpController?.emailAsUsername = true
        logInController.signUpController?.fields = [.usernameAndPassword, .signUpButton, .additional, .dismissButton]
        logInController.signUpController?.signUpView?.usernameField?.keyboardType = .emailAddress
        logInController.signUpController?.signUpView?.additionalField?.isSecureTextEntry = true
        logInController.signUpController?.signUpView?.additionalField?.keyboardType = .alphabet
//        logInController.signUpController?.signUpView?.additionalField?.textContentType = .password
        logInController.signUpController?.signUpView?.usernameField?.placeholder = "Email"
        logInController.signUpController?.signUpView?.additionalField?.placeholder = "Confirmation du mot de passe"
        
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
        user.email = user.username
        user.saveInBackground()
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
        // ["username": "jilji@gmail.com", "password": "es", "additional": "es"]
        
        if HelperAndKeys.isValidEMail(info["username"] ?? "") {
            // Email + MDP OK
            if info["password"] == info["additional"] {
                return true
            } else {
                // MDP différents
                HelperAndKeys.showAlertWithMessage(theMessage: "Le mot de passe et sa confirmation sont différents", title: "Erreur de mot de passe", viewController: signUpController)
                return false
            }
        } else {
            // Email invalide
            HelperAndKeys.showAlertWithMessage(theMessage: "L'adresse email saisie est incorrecte", title: "Email invalide", viewController: signUpController)
            return false
        }
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
