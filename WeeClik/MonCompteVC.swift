//
//  MonCompteVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 21/10/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import ParseFacebookUtilsV4

class MonCompteVC: UIViewController {
    var isPro = false
    var commerces : [PFObject]! = []
    var currentUser = PFUser.current()
    
    @IBOutlet weak var imageProfil : UIImageView!
    @IBOutlet weak var buttonHeight: NSLayoutConstraint!
    @IBOutlet weak var vueConnexion: UIView!
    @IBOutlet weak var gridView: UIView!
    @IBOutlet weak var changeProfilInfoTVC: UITableView!
    @IBOutlet weak var commercesTableView: UITableView!
    
    @IBOutlet weak var noCommerceView: UIView!
    @IBOutlet weak var noCommercesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isPro = true
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:)))]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            try PFUser.current()?.fetch()
        } catch let error as NSError {
            print("Error catching user infos : \n Num : \(error.code) \nDescription : \(error.localizedDescription)")
        }

        self.currentUser = PFUser.current()
        self.imageProfil.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
        
        if (PFUser.current() != nil){
            if let vue = vueConnexion{
                vue.removeFromSuperview()
            }
            self.updateUIBasedOnUser()
            self.queryCommercesArrayBasedOnUser()
        }
    }
    
    @IBAction func changeImageProfil(){
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
        self.changeProfilInfoTVC.reloadData()
        self.commercesTableView.reloadData()
    }
}

extension MonCompteVC : UITableViewDelegate, UITableViewDataSource {
    
    func queryCommercesArrayBasedOnUser(){
        if isPro {
            // Prend les commerces du compte pro
            let queryCommerce = PFQuery(className: "Commerce")
            queryCommerce.whereKey("owner", equalTo: currentUser as Any)
            queryCommerce.findObjectsInBackground(block: { (objects, error) in
                if error != nil {
                    self.commerces = objects
                    self.updateUIBasedOnUser()
                }
            })
        } else {
            // Prend les commerces favoris de l'utilisateur
            let queryCommerce = PFUser.query()
            queryCommerce?.whereKey("objectId", equalTo: currentUser?.objectId?.description as Any)
            queryCommerce?.findObjectsInBackground(block: { (objects, error) in
                if error != nil {
                    let obj = objects![0] as PFObject
                    self.commerces = obj["mes_partages"] as! [PFObject]
                    self.updateUIBasedOnUser()
                }
            })
        }
    }
    
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
            if commerces.count == 0 {
                if isPro {
                    // Compte pro
                    noCommercesLabel.text = "Vous ne possedez aucun commerce pour le moment"
                    self.buttonHeight.constant = 40
                } else {
                    noCommercesLabel.text = "Vous n'avez pour le moment partagé aucun commerce"
                    self.buttonHeight.constant = 0
                }
            } else {
                if let vue = noCommerceView {
                    vue.removeFromSuperview()
                }
            }
            return commerces.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.changeProfilInfoTVC {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emailChangeCell")
            cell?.textLabel?.text = (PFUser.current() != nil) ? currentUser!["name"] as! String : "Nom Prénom"
            cell?.detailTextLabel?.text = (PFUser.current() != nil) ? currentUser?.email : "email"
            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "commercesCell")
            let commerceObj = Commerce(parseObject: self.commerces[indexPath.row])
            cell?.textLabel?.text = commerceObj.nom + " - " + String(commerceObj.partages) + " partages"
            cell?.detailTextLabel?.text = commerceObj.statut
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView ==  self.commercesTableView {
            // Afficher le détail d'un commerce
            let detailViewController = DetailCommerceViewController()
            let commerceObj = Commerce(parseObject: self.commerces[indexPath.row])
            detailViewController.commerceObject = commerceObj
            self.navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
}



extension MonCompteVC : PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate{
    
    @IBAction func showParseUI(){
        let logInController = PFLogInViewController()
        logInController.delegate = self
        logInController.fields = [PFLogInFields.usernameAndPassword,
                                  PFLogInFields.logInButton,
                                  PFLogInFields.signUpButton,
                                  PFLogInFields.passwordForgotten,
                                  PFLogInFields.dismissButton,
                                  PFLogInFields.facebook]
        logInController.emailAsUsername = true
        logInController.facebookPermissions = ["email", "public_profile"]
        logInController.logInView?.logo?.alpha = 0
        
        logInController.signUpController?.signUpView?.logo?.alpha = 0
        
        self.present(logInController, animated: true, completion: nil)
    }
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        print("succesful login : \(user.description)")
        logInController.dismiss(animated: true)
//        self.getFacebookInformations(user: user)
//        nextViewControllerWithUser(user: user, controller: logInController)
    }
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        if let parseError = error{
            let nserror = parseError as NSError
            print("Erreur de login : \nCode (\(nserror.code))\n     -> \(nserror.localizedDescription)")
        }
    }
    
    // Inscription classique (par mail)
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        signUpController.dismiss(animated: true)
        print("succesful signup : \(user.description)")
//        nextViewControllerWithUser(user: user, controller: signUpController)
    }
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?) {
        if let parseError = error{
            let nserror = parseError as NSError
            print("Erreur de signup : \nCode (\(nserror.code))\n     -> \(nserror.localizedDescription)")
        }
    }
    
    func nextViewControllerWithUser(user : PFUser, controller : UIViewController? = nil){
        
        if let story = self.storyboard {
            print("\nstory\n")
            var identifier : String
            let inscrit = user["inscriptionDone"] as! Bool
            //            identifier = inscrit ? "profil_commerce" : "choose_type_compte"
            identifier = "profil_commerce"
            let nav = story.instantiateViewController(withIdentifier: identifier) as! UINavigationController
            
            if let vc = controller{
                if inscrit == false {
                    // Utilisateur non inscrit
                    _ = nav.viewControllers[0] as! ProcessInscriptionVC
//                    process.viewController = vc
                } else {
                    // Utilisateur deja inscrit
                    let nav = story.instantiateViewController(withIdentifier: identifier) as! UINavigationController
                    _ = nav.viewControllers[0] as! MonCompteVC
                }
                vc.present(nav, animated: true)
            } else {
                self.present(nav, animated: true)
            }
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
