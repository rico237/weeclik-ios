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
    
    var timer: Timer!

    @IBOutlet weak var nouveauCommerceButton: UIButton!
    @IBOutlet weak var imageProfil: UIImageView!
    @IBOutlet weak var vueConnexion: UIView!
    @IBOutlet weak var gridView: UIView!
    @IBOutlet weak var changeProfilInfoTVC: UITableView!
    @IBOutlet weak var commercesTableView: UITableView!

    @IBOutlet weak var noCommerceView: UIView!
    @IBOutlet weak var noCommercesLabel: UILabel!

    // Contraintes du bouton de création d'un commerce
    @IBOutlet weak var rightButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftButtonConstraint: NSLayoutConstraint!
    @IBOutlet var bottomButtonConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:)))]

        guard let user = currentUser else { return }
        user.fetchInBackground(block: { (user, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else if let user = user as? PFUser {
                self.currentUser = user
            }
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBarBasedOnUser()
        guard let current = PFUser.current() else { return }

        currentUser = current
        updateProfilPic(forUser: current)

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
        imageProfil.sd_setImage(with: URL(string: userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload, completed: nil)
        imageProfil.layer.cornerRadius = updateUI ? imageProfil.frame.size.width / 2 : 0
        imageProfil.layer.borderWidth = updateUI ? 3 : 0
        imageProfil.layer.masksToBounds = updateUI ? true : false
    }

    func isProUpdateUI() {
        if leftButtonConstraint != nil && rightButtonConstraint != nil {
            leftButtonConstraint.constant  = HelperAndKeys.isPhoneX ? 0 : 0
            rightButtonConstraint.constant = HelperAndKeys.isPhoneX ? 0 : 0
        }

        if bottomButtonConstraint != nil {
            let buttonHeight  = nouveauCommerceButton.frame.size.height
            let bottomPadding = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
            bottomButtonConstraint.constant = isPro ? 0 : -buttonHeight - bottomPadding
        }
        
//        if isPro {
//            nouveauCommerceButton.roundCorners(.allCorners, radius: 5)
//        } else {
//            nouveauCommerceButton.roundCorners(.allCorners, radius: 0)
//        }

        if noCommercesLabel != nil {
            let noCommercesOwned  = "Vous ne possedez aucun commerce pour le moment".localized()
            let noSharedCommerces = "Vous n'avez pour le moment partagé aucun commerce".localized()
            noCommercesLabel.text = isPro ? noCommercesOwned : noSharedCommerces
        }
        
        updateNavigationBarBasedOnUser()
    }
    
    func updateNavigationBarBasedOnUser() {
        guard PFUser.current() != nil else {
            navigationItem.rightBarButtonItems = []
            return
        }
        
        if isPro {
            for commercePFObject in commerces {
                if Commerce(parseObject: commercePFObject).statut != .paid {
                    navigationItem.rightBarButtonItems = [
                        UIBarButtonItem(image: UIImage(named: "Logout_icon"), style: .plain, target: self, action: #selector(logOut)),
                        self.editButtonItem
                    ]
                    break
                } else {
                    navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Logout_icon"), style: .plain, target: self, action: #selector(logOut))]
                }
            }
        } else {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Logout_icon"), style: .plain, target: self, action: #selector(logOut))]
        }
    }

    @IBAction func getBackToHome(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func logOut() {
        PFUser.logOutInBackground()
        dismiss(animated: true, completion: nil)
    }

    func updateUIBasedOnUser() {
        isProUpdateUI()
        
        changeProfilInfoTVC.reloadData()
        commercesTableView.reloadData()
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(queryCommercesArrayBasedOnUser), userInfo: nil, repeats: false)
        timer.tolerance = 0.2
        RunLoop.current.add(timer, forMode: .common)
    }
    
    func stopTimer() {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
}

extension MonCompteVC: UITableViewDelegate, UITableViewDataSource {
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(!editing, animated: animated)
        
        commercesTableView.setEditing(!commercesTableView.isEditing, animated: animated)
        self.editButtonItem.title = commercesTableView.isEditing ? "Ok".localized() : "Modifier".localized()
        
        if commercesTableView.isEditing {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard tableView == commercesTableView else {return}
        
        if editingStyle == .delete {
            ParseService.shared.deleteCommerce(commerce: commerces[indexPath.row]) { (success, error) in
                if success {
                    self.commerces.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                } else if let error = error {
                    ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
                }
                self.commercesTableView.setEditing(self.commercesTableView.isEditing, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView != changeProfilInfoTVC && isPro {
            if Commerce(parseObject: commerces[indexPath.row]).statut != .paid {
                return true
            }
        }
        return false
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == changeProfilInfoTVC {
            return "Mon profil".localized()
        } else {
            if isPro { return "Mes commerces".localized() }
            return "Mes Partages".localized()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == changeProfilInfoTVC { return 1 } else {
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
            let commerce = Commerce(parseObject: commerces[indexPath.row])
            let cell = tableView.dequeueReusableCell(withIdentifier: "commercesCell") as! MonCompteCommerceCell
            cell.partageIcon.tintColor = .systemRed
            cell.descriptionLabel.isHidden = isPro ? false : true

            if isPro {
                // Utilisateur pro
                cell.titre.text = "\(commerce.nom)"
                cell.nbrPartage.text = "\(commerce.partages)"

                if let imageThumbnailFile = commerce.thumbnail {
                    cell.commercePlaceholder.sd_setImage(with: URL(string: imageThumbnailFile.url!))
                } else {
                    cell.commercePlaceholder.image = commerce.type.image
                }

                if (commerce.brouillon) {
                    cell.descriptionLabel.text = "Brouillon - Sauvegarder pour publier".localized()
                    cell.descriptionLabel.textColor = .lightText
                } else {
                    cell.descriptionLabel.text = "\(commerce.statut.description)"
                    switch commerce.statut {
                    case .canceled, .error, .unknown, .pending:
                        cell.descriptionLabel.textColor = .systemRed
                    case .paid:
                        cell.descriptionLabel.textColor = .systemGreen
                    }
                }
            } else {
                // Utilisateur

                cell.titre.text = "\(commerce.nom)"
                cell.nbrPartage.text = "\(commerce.partages)"

                if let imageThumbnailFile = commerce.thumbnail {
                    cell.commercePlaceholder.sd_setImage(with: URL(string: imageThumbnailFile.url!))
                } else {
                    cell.commercePlaceholder.image = commerce.type.image
                }
                let lastPartage = partagesDates[indexPath.row]
                let paris = Region(calendar: Calendars.gregorian, zone: Zones.europeParis, locale: Locales.french)
                cell.descriptionLabel.text = "Dernier partage : \(lastPartage.convertTo(region: paris).toFormat("dd MMM yyyy"))".localized()
            }

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView ==  commercesTableView {
            // Afficher le détail d'un commerce
            let story = UIStoryboard(name: "Main", bundle: nil)
            if isPro {
                let ajoutCommerceVC = story.instantiateViewController(withIdentifier: "ajoutCommerce") as! AjoutCommerceVC
                ajoutCommerceVC.editingMode = true
                ajoutCommerceVC.objectIdCommerce = commerces[indexPath.row].objectId!
                navigationController?.pushViewController(ajoutCommerceVC, animated: true)
            } else {
                let detailViewController = story.instantiateViewController(withIdentifier: "DetailCommerceViewController") as! DetailCommerceViewController
                detailViewController.commerceObject = Commerce(parseObject: commerces[indexPath.row])
                detailViewController.commerceID = commerces[indexPath.row].objectId!
                detailViewController.routeCommerceId = commerces[indexPath.row].objectId!
                navigationController?.pushViewController(detailViewController, animated: true)
            }
        }
    }
}

// Data related
extension MonCompteVC {
    @objc func queryCommercesArrayBasedOnUser() {
        if isPro {
            // Prend les commerces du compte pro
            guard let currentUser = currentUser else { return }
            let queryCommerce = PFQuery(className: "Commerce")
            queryCommerce.whereKey("owner", equalTo: currentUser as Any)
            queryCommerce.includeKeys(["thumbnailPrincipal"])
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
                let partagesDats = currentUser["mes_partages_dates"] as? [Date] {
                //                if let partages = partages {
                // FIXME: Ameliorer cette query
                let partagesQuery = PFQuery(className: "Commerce")
                partagesQuery.whereKey("objectId", containedIn: partages)
                partagesQuery.includeKeys(["thumbnailPrincipal"])
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
                            self.partagesDates.append(partagesDats[index])
                        }
                    }
                    self.updateUIBasedOnUser()
                }
            } else {
                let message =  "Problème lors de la récupération de vos partages".localized()
                HelperAndKeys.showNotification(type: "E", title: "Problème de connexion".localized(), message: message, delay: 3)
            }
        }
        
        startTimer()
    }
}

extension MonCompteVC {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailProfil" {
            guard let profilChangeViewController = segue.destination as? ChangeInfosVC else { return }
            profilChangeViewController.isPro = isPro
        }
    }
}

extension MonCompteVC: PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    @IBAction func showParseUI() {
        // Login Part
        let logInController = ParseLoginSignupHelper.parseLoginViewController()
        logInController.delegate = self
        logInController.signUpController!.delegate = self
        presentFullScreen(viewController: logInController, completion: nil)
    }

    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        if PFFacebookUtils.isLinked(with: user) {
            getFacebookInformations(user: user)
        }
        logInController.dismiss(animated: true)
    }

    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        if let error = error {
            print("Erreur de login : \nCode (\(error.code))\n     -> \(error.localizedDescription)")
            logInController.showAlertWithMessage(message: "Le mot de passe / email n'est pas valide".localized(),
                                                 title: "Erreur lors de la connexion".localized(),
                                                 completionAction: nil)
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
            signUpController.showAlertWithMessage(message: "Le mot de passe / email n'est pas valide".localized(),
                                                  title: "Erreur lors de la connexion".localized(),
                                                  completionAction: nil)
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
                signUpController.showAlertWithMessage(message: "Le mot de passe et sa confirmation sont différents".localized(),
                                                      title: "Erreur de mot de passe".localized(),
                                                      completionAction: nil)
                return false
            }
        } else {
            // Email invalide
            signUpController.showAlertWithMessage(message: "L'adresse email saisie est incorrecte".localized(),
                                                  title: "Email invalide".localized(),
                                                  completionAction: nil)
            return false
        }
    }

    func getFacebookInformations(user: PFUser) {
        let params = ["fields": "email, name"]
        let graphRequest = GraphRequest(graphPath: "me", parameters: params)

        graphRequest.start(completionHandler: { (_, result, error) in
            if let error = error {
                print("Some other error : \nCode (\(error.code))\n     -> \(error.localizedDescription)")
                self.showAlertWithMessage(message: "Une erreur est survenue lors de votre connexion via Facebook, veuillez réesayer plus tard".localized(),
                                          title: "Connexion Facebook échoué".localized(),
                                          completionAction: nil)
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
