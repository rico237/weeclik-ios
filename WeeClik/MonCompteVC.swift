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
    // Savoir si l'utilisateur est de type pro
    var isPro = false {
        didSet {
            refreshUserUI()
            refreshCommercesUI()
        }
    }
    var userProfilePicURL = ""          // Image de profil de l'utilisateur (uniquement facebook pour le moment)
    var commerces = [PFObject]()     // La liste des commerces dans le BAAS
    var partagesDates = [Date]()        // Date des partages
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
        checkTypeOfUser(user: user)
        user.fetchInBackground(block: { (user, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else if let user = user as? PFUser {
                self.currentUser = user
                self.checkTypeOfUser(user: user)
            }
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let current = PFUser.current() else { return }
        currentUser = current
        checkTypeOfUser(user: current)
        current.fetchInBackground(block: { (user, error) in
            guard let user: PFUser = user as? PFUser else { return }
            self.currentUser = user
            if let error = error {
                Log.all.error("Error while fetching user : \(error.debug)")
            } else {
                // Recup si l'utilisateur est un pro (commercant)
                if user["isPro"] as? Bool != nil,
                    user["inscriptionDone"] as? Bool == true {
                    // isPro is set
                    self.checkTypeOfUser(user: user)
                } else {
                    // Nil found
                    // Redirect -> Choosing controller from pro statement
                    if let choosingNav = self.storyboard?.instantiateViewController(withIdentifier: "choose_type_compte") as? UINavigationController,
                        let choosingVC = choosingNav.topViewController as? ProcessInscriptionVC {
                        choosingVC.newUser = current
                        self.present(choosingNav, animated: true, completion: nil)
                    }
                }
            }
        })

        if let vueConnexion = vueConnexion {
            vueConnexion.removeFromSuperview()
        }

        // Récupère ces commerces (favoris si utilisateur normal)
        queryCommercesArrayBasedOnUser()
    }

    @IBAction func getBackToHome(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func logOut() {
        PFUser.logOutInBackground()
        dismiss(animated: true, completion: nil)
    }
}

// Timer
extension MonCompteVC {
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(refresh), userInfo: nil, repeats: false)
        timer.tolerance = 0.2
        RunLoop.current.add(timer, forMode: .common)
    }
    
    func stopTimer() {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
    
    @objc
    func refresh() {
        stopTimer()
        queryCommercesArrayBasedOnUser()
        refreshUserData()
    }
    
    func refreshUserData() {
        guard let user = currentUser else { return }
        
        user.fetchInBackground(block: { (_ user, error) in
            guard let user = user else {
                if let error = error { Log.all.error("Error while fetching user : \(error.debug)") }
                return
            }
            
            if let isPro = user["isPro"] as? Bool {
                self.isPro = isPro
            } else {
                self.isPro = false
                self.setDefaultProValue()
            }
        })
    }
}

// Refresh UI
extension MonCompteVC {
    /// Regarde si une image de profil a été chargé
    /// sinon si une image est lié via facebook
    /// Sinon on affiche l'image de base weeclik
    func updateProfilPic() {
        guard imageProfil != nil, let user = currentUser else { return }
        
        if let profilFile = user["profilPicFile"] as? PFFileObject,
           let url = profilFile.url, url.isEmpty == false {
            userProfilePicURL = url
        } else if let profilPicURL = user["profilePictureURL"] as? String,
                  profilPicURL.isEmpty == false {
            userProfilePicURL = profilPicURL
        }

        imageProfil.layer.borderColor = UIColor(red: 0.86, green: 0.33, blue: 0.34, alpha: 1.00).cgColor
        imageProfil.clipsToBounds = true
        let placeholderImage = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
        if userProfilePicURL.isEmpty {
            imageProfil.image = placeholderImage
        } else {
            imageProfil.sd_setImage(with: URL(string: userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload, completed: nil)
        }
        
        imageProfil.layer.cornerRadius = userProfilePicURL.isEmpty ? 0 : imageProfil.frame.size.width / 2
        imageProfil.layer.masksToBounds = userProfilePicURL.isEmpty ? false : true
    }
    
    func updateUI() {
        guard currentUser != nil else {
            let buttonHeight  = nouveauCommerceButton.frame.size.height
            let bottomPadding = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
            bottomButtonConstraint.constant = -buttonHeight - bottomPadding
            return
        }

        if bottomButtonConstraint != nil {
            let buttonHeight  = nouveauCommerceButton.frame.size.height
            let bottomPadding = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
            bottomButtonConstraint.constant = isPro ? 0 : -buttonHeight - bottomPadding
        }

        if noCommercesLabel != nil {
            let noCommercesOwned  = "Vous ne possedez aucun commerce pour le moment".localized()
            let noSharedCommerces = "Vous n'avez pour le moment partagé aucun commerce".localized()
            noCommercesLabel.text = isPro ? noCommercesOwned : noSharedCommerces
        }
    }
    
    func refreshCommercesUI() {
        updateUI()
        commercesTableView.reloadData()
    }
    
    func refreshUserUI() {
        updateNavigationBarBasedOnUser()
        updateProfilPic()
        changeProfilInfoTVC.reloadData()
    }
    
    func updateNavigationBarBasedOnUser() {
        guard currentUser != nil else {
            navigationItem.rightBarButtonItems = []
            return
        }
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Logout_icon"), style: .plain, target: self, action: #selector(logOut))]
        
        if isPro && commerces.isEmpty == false {
            for commercePFObject in commerces {
                if Commerce(parseObject: commercePFObject).statut != .paid {
                    navigationItem.rightBarButtonItems = [
                        UIBarButtonItem(image: UIImage(named: "Logout_icon"), style: .plain, target: self, action: #selector(logOut)),
                        editButtonItem
                    ]
                    break
                }
            }
        }
    }
}

extension MonCompteVC: UITableViewDelegate, UITableViewDataSource {
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(!editing, animated: animated)
        
        commercesTableView.setEditing(!commercesTableView.isEditing, animated: animated)
        editButtonItem.title = commercesTableView.isEditing ? "Ok".localized() : "Modifier".localized()
        
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
            guard commerces.isEmpty == false else {
                updateUI()
                return 0
            }

            self.refreshNoCommerceView()
            return commerces.count
        }
    }
    
    func refreshNoCommerceView() {
        guard let noCommerceView = noCommerceView else { return }
        var noCommerceViewFrame = noCommerceView.frame
        
        if commerces.isEmpty {
            // Show "No commerce view"
            noCommerceViewFrame.origin.x = 0
        } else {
            // Hide "No commerce view"
            noCommerceViewFrame.origin.x = UIScreen.main.bounds.height
        }
        
        noCommerceView.frame = noCommerceViewFrame
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == changeProfilInfoTVC {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "emailChangeCell") else { return UITableViewCell() }

            if let user = currentUser {
                cell.textLabel?.text = (user["name"] != nil) ? user["name"] as? String : ""
                cell.detailTextLabel?.text = user.email
            } else {
                cell.textLabel?.text = "Nom Prénom".localized()
                cell.detailTextLabel?.text = "email".localized()
            }

            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "commercesCell") as? MonCompteCommerceCell else { return UITableViewCell() }
            
            let commerce = Commerce(parseObject: commerces[indexPath.row])
            cell.partageIcon.tintColor = .systemRed
            cell.descriptionLabel.isHidden = false
            cell.titre.text = "\(commerce.nom)"
            cell.nbrPartage.text = "\(commerce.partages)"

            if let imageThumbnailFile = commerce.thumbnail, let url = imageThumbnailFile.url {
                cell.commercePlaceholder.sd_setImage(with: URL(string: url))
            } else {
                cell.commercePlaceholder.image = commerce.type.image
            }
            
            if isPro {
                // Utilisateur pro
                if (commerce.brouillon) {
                    cell.descriptionLabel.text = "Brouillon - Sauvegarder pour publier".localized()
                    cell.descriptionLabel.textColor = .black
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
                // Utiliseur normal
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
                if let ajoutCommerceVC = story.instantiateViewController(withIdentifier: "ajoutCommerce") as? AjoutCommerceVC {
                    ajoutCommerceVC.editingMode = true
                    ajoutCommerceVC.objectIdCommerce = commerces[indexPath.row].objectId!
                    navigationController?.pushViewController(ajoutCommerceVC, animated: true)
                }
            } else {
                if let detailViewController = story.instantiateViewController(withIdentifier: "DetailCommerceViewController") as? DetailCommerceViewController {
                    detailViewController.commerceObject = Commerce(parseObject: commerces[indexPath.row])
                    detailViewController.commerceID = commerces[indexPath.row].objectId!
                    detailViewController.routeCommerceId = commerces[indexPath.row].objectId!
                    navigationController?.pushViewController(detailViewController, animated: true)
                }
            }
        }
    }
}

// Data related
extension MonCompteVC {
    func queryCommercesArrayBasedOnUser() {
        guard let currentUser = currentUser else { return }
        
        currentUser.fetchInBackground { (user, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else if let user = user as? PFUser {
                self.currentUser = user
                if let isPro = user["isPro"] as? Bool {
                    self.isPro = isPro
                } else {
                    self.isPro = false
                    self.setDefaultProValue()
                }
                if self.isPro {
                    // Prend les commerces du compte pro
                    let queryCommerce = PFQuery(className: "Commerce")
                    queryCommerce.whereKey("owner", equalTo: user as Any)
                    queryCommerce.includeKeys(["thumbnailPrincipal"])
                    queryCommerce.findObjectsInBackground(block: { (objects, error) in
                        guard let objects = objects else {
                            if let error = error { ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true) }
                            return
                        }
                        self.commerces = objects
                        self.refreshCommercesUI()
                    })
                } else {
                    // Prend les commerces favoris de l'utilisateur
                    guard let partages = user["mes_partages"] as? [String],
                        let partagesDats = user["mes_partages_dates"] as? [Date],
                        partages.isEmpty == false,
                        partagesDats.isEmpty == false,
                        partages.count == partagesDats.count else {
                            self.partagesDates.removeAll()
                            self.commerces.removeAll()
                            self.refreshCommercesUI()
                            self.startTimer()
                            return
                    }
                    
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
                        
                        for (index, commerceId) in partages.enumerated() {
                            if let queryCommerce = objects.first(where: { $0.objectId == commerceId }) {
                                self.commerces.append(queryCommerce)
                                self.partagesDates.append(partagesDats[index])
                            }
                        }

                        self.refreshCommercesUI()
                    }
                }
                
                self.startTimer()
            }
        }
    }
    
    func setDefaultProValue() {
        guard let user = PFUser.current() else { return }
        
        user.fetchInBackground { (user, error) in
            if let user = user as? PFUser {
                user["isPro"] = false
                user.saveInBackground()
            } else if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: false)
            }
        }
    }
    
    func checkTypeOfUser(user: PFUser) {
        if let isPro = user["isPro"] as? Bool {
            self.isPro = isPro
        } else {
            self.isPro = false
        }
    }
    
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
        dismiss(animated: true)
    }

    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        if let error = error {
            Log.all.error("Erreur de login : \n\(error.debug)")
            logInController.showAlertWithMessage(message: "Le mot de passe / email n'est pas valide".localized(),
                                                 title: "Erreur lors de la connexion".localized(),
                                                 completionAction: nil)
        }
    }

    // Inscription classique (par mail)
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        user.email = user.username
        user["additional"] = ""
        user.saveInBackground()
        
        dismiss(animated: true, completion: nil)
    }

    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?) {
        if let error = error {
            Log.all.error("Erreur de login : \n\(error.debug)")
            signUpController.showAlertWithMessage(message: "Le mot de passe / email n'est pas valide".localized(),
                                                  title: "Erreur lors de la connexion".localized(),
                                                  completionAction: nil)
        }
    }

    // Fonction pour definir des mots de passe trop faibles
    func signUpViewController(_ signUpController: PFSignUpViewController, shouldBeginSignUp info: [String: String]) -> Bool {
        Log.all.info("Aucune conditions particulières pour le mot de passe")
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
}
