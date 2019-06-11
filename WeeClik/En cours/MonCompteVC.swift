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
import SwiftDate

class MonCompteVC: UIViewController {
    var isPro = false                   // Savoir si l'utilisateur est de type pro
    var userProfilePicURL = ""          // Image de profil de l'utilisateur (uniquement facebook pour le moment)
    var commerces : [PFObject]! = []    // La liste des commerces dans le BAAS
    var currentUser = PFUser.current()  // Utilisateur connecté

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
        
        isProUpdateUI() // Update liste of commerce for pro users
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.getBackToHome(_:)))]
        
        PFUser.current()?.fetchInBackground(block: { (user, error) in
            if let error = error {
                print("Error catching user infos")
                ParseErrorCodeHandler.handleUnknownError(error: error)
            } else if let user = user as? PFUser {
                self.currentUser = user
            }
        })
        
        if let current = PFUser.current() {
            self.currentUser = current
            
            self.updateProfilPic(forUser: current)
            
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
    
    func updateProfilPic(forUser user: PFUser){
        // Regarde si une image de profil a été chargé
        // Sinon on affiche l'image de base weeclik
        if let profilPicURL = user["profilePictureURL"] as? String {
            if profilPicURL != "" {
                self.userProfilePicURL = profilPicURL
            }
        } else if let profilFile = user["profilPicFile"] as? PFFileObject {
            if let url = profilFile.url {
                if url != "" {
                    self.userProfilePicURL = url
                }
            }
        }
        
        if self.imageProfil != nil {
            
            self.imageProfil.layer.borderColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00).cgColor
            self.imageProfil.clipsToBounds = true
            
            if self.userProfilePicURL != "" {
                let placeholderImage = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
                self.imageProfil.sd_setImage(with: URL(string: self.userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload , completed: nil)
                self.imageProfil.layer.cornerRadius = self.imageProfil.frame.size.width / 2
                self.imageProfil.layer.borderWidth = 3
                self.imageProfil.layer.masksToBounds = true
            } else {
                self.imageProfil.layer.cornerRadius = 0
                self.imageProfil.layer.borderWidth = 0
                self.imageProfil.layer.masksToBounds = false
                self.imageProfil.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
            }
        }
    }
    
    func isProUpdateUI(){
//        print("Bouton height \(isPro)")
//        print("Is iPhone X : \(HelperAndKeys.isPhoneX)")

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

    @IBAction func getBackToHome(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func logOut(_ sender: Any) {
        PFUser.logOutInBackground()
        self.getBackToHome(self)
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
            
            if (obj.brouillon) {
                cell?.detailTextLabel?.text = "Brouillon - Sauvegarder pour publier"
            } else {
                cell?.detailTextLabel?.text = "\(obj.statut.description)"
            }
            
//            if isPro {
//                let obj = Commerce(parseObject: self.commerces[indexPath.row])
//
//                cell?.textLabel?.text = "\(obj.nom) - \(obj.partages) partages"
//
//                if (obj.brouillon) {
//                    cell?.detailTextLabel?.text = "Brouillon - Sauvegarder pour publier"
//                } else {
//                    cell?.detailTextLabel?.text = "\(obj.statut.description)"
//                }
//            } else {
//                let obj = self.commerces[indexPath.row]
//                let commerce = Commerce(parseObject: obj["commercePartage"] as! PFObject )
//                cell?.textLabel?.text = "\(commerce.nom) - Partagé \(obj["nbrPartage"] ?? "0") fois"
//                let arrayDate = obj["mes_partages_dates"] as! Array<String>
//                let paris = Region(calendar: Calendars.gregorian, zone: Zones.europeParis, locale: Locales.french)
//                let lastPartage = Date(arrayDate.first ?? "")
//                if let lastPartage = lastPartage {
//                    cell?.detailTextLabel?.text = "Dernier partage : \(lastPartage.convertTo(region: paris).toFormat("dd MMM yyyy 'à' HH:mm"))"
//                }
//            }
            
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
                } else if let error = error {
                    ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
                }
            })
        } else {
            // Prend les commerces favoris de l'utilisateur
            
//            let queryCommerce = PFQuery(className: "StatsPartage")
//            queryCommerce.whereKey("utilisateurPartageur", equalTo: currentUser!)
//            queryCommerce.includeKeys(["utilisateurPartageur", "commercePartage"])
//            queryCommerce.findObjectsInBackground { (objects, error) in
//                if let partages = objects {
//                    self.commerces = partages
//                    self.updateUIBasedOnUser()
//                } else if let error = error {
//                    ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
//                }
//            }
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
//            else if let err = error as NSError?, err.userInfo["error"]!["type"] == "OAuthException" {
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
