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
            queryCommerce?.findObjectsInBackground(block: { (objects, error) in
                if objects != nil {
//                    print("Nombre de commerces : \(objects?.count ?? 0)")
                    let obj = objects![0] as PFObject
                    self.commerces = obj["mes_partages"] as? [PFObject]
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
            if isPro {
                let story = UIStoryboard(name: "Main", bundle: nil)
                let ajoutCommerceVC = story.instantiateViewController(withIdentifier: "ajoutCommerce") as! AjoutCommerceVC
                ajoutCommerceVC.editingMode = true
                self.navigationController?.pushViewController(ajoutCommerceVC, animated: true)
            } else {
                let detailViewController =  DetailCommerceViewController()
                
                self.navigationController?.pushViewController(detailViewController, animated: true)
            }
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
        
        logInController.signUpController?.delegate = self
        logInController.signUpController?.signUpView?.logo?.alpha = 0
        
        self.present(logInController, animated: true, completion: nil)
    }
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
//        print("succesful login : \(user.description)")
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
        user["mes_partages"] = []
        user["isPro"] = self.isPro
        user["inscriptionDone"] = true
        user["mes_partages_dates"] = []
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Sauvegarde des informations")
        
        user.saveInBackground { (success, err) in
            if success {
                SVProgressHUD.dismiss(withDelay: 1, completion: {
                    print("succesful signup : \(user.description)")
                    self.dismiss(animated: true, completion: nil)
                })
            } else {
                SVProgressHUD.dismiss(withDelay: 1, completion: {
                    let er = err! as NSError
                    print("Error de sauvegarde utilisateur : \n\t-> Code : \(er.code)\n\t-> Description : \(er.localizedDescription)")
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?) {
        if let parseError = error{
            let nserror = parseError as NSError
            print("Erreur de signup : \nCode (\(nserror.code))\n     -> \(nserror.localizedDescription)")
        }
    }
    
    func nextViewControllerWithUser(user : PFUser, controller : UIViewController? = nil){
        
        if let story = self.storyboard {
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
