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
import Localize_Swift

class MonCompteVC: UIViewController {
    var isPro = false                   // Savoir si l'utilisateur est de type pro
    var userProfilePicURL = ""          // Image de profil de l'utilisateur (uniquement facebook pour le moment)
    var commerces: [PFObject]! = []    // La liste des commerces dans le BAAS
    var partagesDates = [Date]()       // Date des partages
    var currentUser = PFUser.current()  // Utilisateur connecté

    @IBOutlet weak var nouveauCommerceButton: UIButton!
    @IBOutlet weak var imageProfil: UIImageView!
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
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.getBackToHome(_:)))]

        guard let user = currentUser else { return }
        user.fetchInBackground(block: { (user, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else if let user = user as? PFUser {
                self.currentUser = user
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let current = PFUser.current() else {return}

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
            if let choosingNav = storyboard?.instantiateViewController(withIdentifier: "choose_type_compte") as? UINavigationController,
                let choosingVC = choosingNav.topViewController as? ProcessInscriptionVC {
                choosingVC.newUser = current
                present(choosingNav, animated: true, completion: nil)
            }
        }

        if let vueConnexion = vueConnexion {
            vueConnexion.removeFromSuperview()
        }

        // Récupère ces commerces (favoris si utilisateur normal)
        queryCommercesArrayBasedOnUser()
    }

    /// Regarde si une image de profil a été chargé
    /// sinon si une image est lié via facebook
    /// Sinon on affiche l'image de base weeclik
    func updateProfilPic(forUser user: PFUser) {
        guard imageProfil != nil else { return }
        if let profilFile = user["profilPicFile"] as? PFFileObject,
            let url = profilFile.url, url != "" {
            userProfilePicURL = url
        } else if let profilPicURL = user["profilePictureURL"] as? String,
                profilPicURL != "" {
            userProfilePicURL = profilPicURL
        }

        imageProfil.layer.borderColor = UIColor(red: 0.86, green: 0.33, blue: 0.34, alpha: 1.00).cgColor
        imageProfil.clipsToBounds = true
        let placeholderImage = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
        let updateUI = userProfilePicURL != ""
        imageProfil.sd_setImage(with: URL(string: self.userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload, completed: nil)
        imageProfil.layer.cornerRadius = updateUI ? self.imageProfil.frame.size.width / 2 : 0
        imageProfil.layer.borderWidth = updateUI ? 3 : 0
        imageProfil.layer.masksToBounds = updateUI ? true : false
    }

    func isProUpdateUI() {
//        print("Bouton height \(isPro)")
//        print("Is iPhone X : \(HelperAndKeys.isPhoneX)")

        if leftButtonConstraint != nil {
            leftButtonConstraint.constant  = HelperAndKeys.isPhoneX ? 16 : 0
        }

        if rightButtonConstraint != nil {
            rightButtonConstraint.constant = HelperAndKeys.isPhoneX ? 16 : 0
        }

        if buttonHeight != nil {
            buttonHeight.constant = isPro ? 50 : 0
        }

        if noCommercesLabel != nil {
            let noCommercesOwned  = "Vous ne possedez aucun commerce pour le moment".localized()
            let noSharedCommerces = "Vous n'avez pour le moment partagé aucun commerce".localized()
            noCommercesLabel.text = isPro ? noCommercesOwned : noSharedCommerces
        }

    }

    @IBAction func getBackToHome(_ sender: Any) { self.dismiss(animated: true) }

    @IBAction func logOut(_ sender: Any) {
        PFUser.logOutInBackground()
        getBackToHome(self)
    }

    func updateUIBasedOnUser() {
        isProUpdateUI()
        changeProfilInfoTVC.reloadData()
        commercesTableView.reloadData()
    }
}

extension MonCompteVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.changeProfilInfoTVC {
            return "Mon profil".localized()
        } else {
            if isPro {
                return "Mes commerces".localized()
            }
            return "Mes Partages".localized()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.changeProfilInfoTVC { return 1 } else {
            guard let comm = commerces else { return 0 }

            if comm.isEmpty {
                isProUpdateUI()
            } else {
                if let noCommerceView = noCommerceView {
                    noCommerceView.removeFromSuperview()
                }
            }
            return commerces.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == changeProfilInfoTVC {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emailChangeCell")

            if let user = PFUser.current() {
                cell?.textLabel?.text = (user["name"] != nil) ? user["name"] as? String : ""
                cell?.detailTextLabel?.text = user.email
            } else {
                cell?.textLabel?.text = "Nom Prénom".localized()
                cell?.detailTextLabel?.text = "email".localized()
            }

            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "commercesCell") as! MonCompteCommerceCell
            let obj = Commerce(parseObject: self.commerces[indexPath.row])

            cell.partageIcon.tintColor = UIColor.red

            if isPro {

                if self.isPro {
                    cell.descriptionLabel.isHidden = false
                } else {
                    cell.descriptionLabel.isHidden = true
                }

                cell.titre.text = "\(obj.nom)"
                cell.nbrPartage.text = "\(obj.partages)"

                if let imageThumbnailFile = obj.thumbnail {
                    cell.commercePlaceholder.sd_setImage(with: URL(string: imageThumbnailFile.url!))
                } else {
                    cell.commercePlaceholder.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: obj.type)
                }

                if (obj.brouillon) {
                    cell.descriptionLabel.text = "Brouillon - Sauvegarder pour publier".localized()
                    cell.descriptionLabel.textColor = .lightText
                } else {
                    cell.descriptionLabel.text = "\(obj.statut.description)"
                    switch obj.statut {
                    case .canceled, .error, .unknown, .pending:
                        cell.descriptionLabel.textColor = UIColor.red
                        break
                    case .paid:
                        cell.descriptionLabel.textColor = UIColor.init(hexFromString: "#00d06b")
                        break
                    }
                }
            } else {

                cell.descriptionLabel.isHidden = false

                cell.titre.text = "\(obj.nom)"
                cell.nbrPartage.text = "\(obj.partages)"

                if let imageThumbnailFile = obj.thumbnail {
                    cell.commercePlaceholder.sd_setImage(with: URL(string: imageThumbnailFile.url!))
                } else {
                    cell.commercePlaceholder.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: obj.type)
                }
                let lastPartage = partagesDates[indexPath.row]
                let paris = Region(calendar: Calendars.gregorian, zone: Zones.europeParis, locale: Locales.french)
                cell.descriptionLabel.text = "Dernier partage : \(lastPartage.convertTo(region: paris).toFormat("dd MMM yyyy"))".localized()
            }

            return cell
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
                detailViewController.commerceObject = Commerce(parseObject: self.commerces[indexPath.row])
                detailViewController.commerceID = self.commerces[indexPath.row].objectId!
                detailViewController.routeCommerceId = self.commerces[indexPath.row].objectId!
                self.navigationController?.pushViewController(detailViewController, animated: true)
            }
        }
    }
}

// Data related
extension MonCompteVC {
    func queryCommercesArrayBasedOnUser() {
        if isPro {
            // Prend les commerces du compte pro
            guard let currentUser = currentUser else { return }
            let queryCommerce = PFQuery(className: "Commerce")
            queryCommerce.whereKey("owner", equalTo: currentUser as Any)
            queryCommerce.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])
            queryCommerce.findObjectsInBackground(block: { (objects, error) in
                guard let objects = objects else {
                    if let error = error { ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true) }
                    return
                }
                self.commerces = objects
                self.updateUIBasedOnUser()
            })
        } else {
            // Prend les commerces favoris de l'utilisateur
            if let currentUser = currentUser,
                let partages = currentUser["mes_partages"] as? [String],
                let partages_dats = currentUser["mes_partages_dates"] as? [Date] {
                //                if let partages = partages {
                // FIXME: Ameliorer cette query
                let partagesQuery = PFQuery(className: "Commerce")
                partagesQuery.whereKey("objectId", containedIn: partages)
                partagesQuery.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])
                partagesQuery.findObjectsInBackground { (objects, error) in
                    guard let objects = objects else {
                        if let error = error { ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true) }
                        return
                    }
                    // Parcour tous les ids
                    self.partagesDates.removeAll()
                    self.commerces.removeAll()
                    for i in 0...partages.count - 1 {
                        let obId = partages[i]
                        // synchronisation du commerce et des dates de partage
                        for (index, commerce) in objects.enumerated() where commerce.objectId == obId {
                            self.commerces.append(commerce)
                            self.partagesDates.append(partages_dats[index])
                        }
                    }
                    self.updateUIBasedOnUser()
                }
            } else {
                HelperAndKeys.showNotification(type: "E", title: "Problème de connexion".localized(), message: "Problème lors de la récupération de vos partages".localized(), delay: 3)
            }
        }
    }
}

extension MonCompteVC {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailProfil" {
            guard let profilChangeViewController = segue.destination as? ChangeInfosVC else { return }
            profilChangeViewController.isPro = self.isPro
        }
    }
}

extension MonCompteVC: PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    @IBAction func showParseUI() {
        // Login Part
        let logInController = ParseLoginSignupHelper.parseLoginViewController()
        logInController.delegate = self
        logInController.signUpController!.delegate = self
        self.presentFullScreen(viewController: logInController, completion: nil)
    }

    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        if PFFacebookUtils.isLinked(with: user) {
            self.getFacebookInformations(user: user)
        }
        logInController.dismiss(animated: true)
    }

    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        if let error = error {
            print("Erreur de login : \nCode (\(error.code))\n     -> \(error.localizedDescription)")
            HelperAndKeys.showAlertWithMessage(theMessage: "Le mot de passe / email n'est pas valide".localized(), title: "Erreur lors de la connexion".localized(), viewController: logInController)
        }
    }

    // Inscription classique (par mail)
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        user.email = user.username
        user.saveInBackground()
        signUpController.dismiss(animated: true, completion: nil)
    }

    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?) {
        if let error = error {
            print("Erreur de signup : \nCode (\(error.code))\n     -> \(error.localizedDescription)")
            HelperAndKeys.showAlertWithMessage(theMessage: "Le mot de passe / email n'est pas valide".localized(), title: "Erreur lors de la connexion".localized(), viewController: signUpController)
        }
    }

    // Fonction pour definir des mots de passe trop faibles
    func signUpViewController(_ signUpController: PFSignUpViewController, shouldBeginSignUp info: [String: String]) -> Bool {
        print("Aucune conditions particulières pour le mot de passe")
        // ["username": "jilji@gmail.com", "password": "es", "additional": "es"]

        if (info["username"]!).isValidEmail() {
            // Email + MDP OK
            if info["password"] == info["additional"] {
                return true
            } else {
                // MDP différents
                HelperAndKeys.showAlertWithMessage(theMessage: "Le mot de passe et sa confirmation sont différents".localized(), title: "Erreur de mot de passe".localized(), viewController: signUpController)
                return false
            }
        } else {
            // Email invalide
            HelperAndKeys.showAlertWithMessage(theMessage: "L'adresse email saisie est incorrecte".localized(), title: "Email invalide".localized(), viewController: signUpController)
            return false
        }
    }

    func getFacebookInformations(user: PFUser) {
        let params = ["fields": "email, name"]
        let graphRequest = GraphRequest(graphPath: "me", parameters: params)

        graphRequest.start(completionHandler: { (_, result, error) in
            if let error = error {
                print("Some other error : \nCode (\(error.code))\n     -> \(error.localizedDescription)")
                HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue lors de votre connexion via Facebook, veuillez réesayer plus tard".localized(), title: "Connexion Facebook échoué".localized(), viewController: self)
            } else {
                // handle successful response
                if let data = result as? [String: Any] {
                    user["name"] = data["name"] as! String
                    user["email"] = data["email"] as! String
                    let facebookId = data["id"] as! String
                    user["facebookId"] = facebookId
                    user["profilePictureURL"] = "https://graph.facebook.com/" + facebookId + "/picture?type=large&return_ssl_resources=1"
                    user.saveInBackground()
                }
            }
        })
    }
}
