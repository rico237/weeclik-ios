//
//  AccueilCommerces.swift
//  WeeClik
//
//  Created by Herrick Wolber on 21/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO: Ajouter un message si il n'ya pas d'objet
// TODO: Ajouter un systeme de pagination pour le chargement des commerces
// TODO: Filtrer les commerce par geolocalisation autour de l'utilisateur
// TODO: Ajouter un système de recherche par type de commerce et par nom
// TODO: Ajouter les boutons du menu
// TODO: Gerer les pbs de connexions si trop long afficher un message d'erreur
// TODO: Ajouter les commerces favoris
// TODO: Ajouter le filtre des commerces selon le filtre de leboncoin ios

import UIKit
import DropDownMenuKit
import Parse
import ParseUI
import SVProgressHUD
import KJNavigationViewAnimation
import KRLCollectionViewGridLayout
import SDWebImage
import STLocationRequest
import CoreLocation
import AZDialogView
import CRNotifications
import BulletinBoard
import ParseFacebookUtilsV4

class AccueilCommerces: UIViewController {

    var titleView       : DropDownTitleView!
    var toutesCat       : Array<String>!
    var catCells        : Array<DropDownMenuCell> = []
    var commerces       : Array<Commerce> = []
    var didLoad         : Bool! = false     // Pour charger le contenu du menu des catégories
    var firstLoad       : Bool! = false     // Whether we have loaded the first set of objects
    var currentPage     : Int! = 0          // The last page that was loaded
    var lastLoadCount   : Int! = -1         // The count of objects from the last load. Set to -1 when objects haven't loaded, or there was an error.
    let itemsPerPages   : Int! = 25         // Nombre de commerce chargé à la fois (eviter la surchage de réseau etc.)
    var locationGranted : Bool! = false
    let locationManager = CLLocationManager()
    var latestLocationForQuery : CLLocation!
    var prefFiltreLocation = false            // Savoir si les commerces sont filtrés par location ou partages
    
    @IBOutlet weak var labelHeaderCategorie: UILabel!
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var headerTypeCommerceImage: UIImageView!
    @IBOutlet var navigationBarMenu: DropDownMenu!
    @IBOutlet weak var viewKJNavigation: KJNavigationViewAnimation!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var layoutCollection: KRLCollectionViewGridLayout {
        return self.collectionView?.collectionViewLayout as! KRLCollectionViewGridLayout
    }
    
    var introBulletin = BulletinDataSource.makeIntroFilterPage()
    
    lazy var filterBulletinManager : BulletinManager = {
        let bulletinPageIntro = BulletinDataSource.makeFilterPage(isLocation: self.prefFiltreLocation)
        bulletinPageIntro.actionHandler = { item in
            self.prefFiltreLocation = !self.prefFiltreLocation
            print("Préférence  \(self.prefFiltreLocation)")
            item.manager?.dismissBulletin(animated: true)
        }
        bulletinPageIntro.alternativeHandler = { (item : BulletinItem) in
            item.displayNextItem()
//            item.manager?.dismissBulletin(animated: true)
        }
        bulletinPageIntro.nextItem = introBulletin
        return BulletinManager(rootItem : bulletinPageIntro)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter  = kCLDistanceFilterNone
        
        self.collectionView.backgroundColor  = HelperAndKeys.getBackgroundColor()
        
        // Liste toutes les catégories possibles
        toutesCat = HelperAndKeys.getListOfCategories()
        
        
        // Creation du Menu catégories
        viewKJNavigation.topbarMinimumSpace = .custom(height: 150)
        collectionView.delegate   = self
        collectionView.dataSource = self
        viewKJNavigation.setupFor(CollectionView: collectionView, viewController: self)
        
        
        // Ajout du contenu au Menu catégories
        let title = prepareNavigationBarMenuTitleView()
        prepareNavigationBarMenu(title)
        
        
        // Mise en place de la taille des cellules pour chaque commerce (notre grille de commerce)
        let inset = 10 as CGFloat
        layoutCollection.sectionInset = UIEdgeInsets(top: inset*2, left: inset, bottom: inset*2, right: inset)
        layoutCollection.numberOfItemsPerLine = 2
        layoutCollection.aspectRatio = 1
        
//        self.checkLocationServicePermission()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationBarMenu.container = view
        didLoad = true
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Login_icon") , style: .plain, target: self, action: #selector(showConnectionPage))]
    }
    
    @IBAction func logOut(_ sender: Any) {
        PFUser.logOutInBackground()
    }
    
    @IBAction func filterBarbuttonPressed(_ sender: Any) {
        filterBulletinManager.prepare()
        filterBulletinManager.presentBulletin(above: self)
    }
    
    @objc func showConnectionPage(){
        if let user = PFUser.current(){
            // Utilisateur est déja connecté
            print("Utilisateur déja crée : \(user.description)")
            getFacebookInformations(user: user)
        }else{
            // Non connecté
            self.showDialogConnection()
        }
    }
    
    func getFacebookInformations(user : PFUser){
        
        let params = ["fields" : "email, name"]
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: params)
        
        graphRequest?.start(completionHandler: { (request, result, error) in
//            let err = error! as NSError
            if (error == nil) {
                // handle successful response
                if let data = result as? [String:Any] {
                    print("\(String(describing: data))")
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
        
        if let storyB = self.storyboard {
            let destination : UIViewController!
            
            if user["isPro"] != nil {
                let pro = user["isPro"] as! Bool
                if pro == true {
                    // Compte commerce
                    destination = storyB.instantiateViewController(withIdentifier: "profil_commerce")
                } else {
                    // Compte utilisateur
                    destination = storyB.instantiateViewController(withIdentifier: "profil_user")
                }
            } else {
                destination = storyB.instantiateViewController(withIdentifier: "choose_type_compte")
            }
            
            self.show(destination, sender: self)
        }
    }
    
    func checkLocationServicePermission() {
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == .denied {
                // Location Services are denied
                locationGranted = false
            } else {
                if CLLocationManager.authorizationStatus() == .notDetermined{
                    // Present the STLocationRequestController
                    self.presentLocationRequestController()
                } else {
                    // The user has already allowed your app to use location services. Start updating location
                    self.locationManager.startUpdatingLocation()
                    locationGranted = true
                }
            }
        } else {
            // Location Services are disabled
            HelperAndKeys.showAlertWithMessage(theMessage: "Nous n'arrivons a determiner votre position, afin de vous afficher les commerces prèsde vous.", title: "Localisation désactivé", viewController: self)
            locationGranted = false
        }
    }
    
    func presentLocationRequestController(){
        let locationRequestController = STLocationRequestController.getInstance()
        locationRequestController.titleText = "Nous avons besoin de votre position afin de vous afficher les commerces autour de vous"
        locationRequestController.allowButtonTitle = "Ok"
        locationRequestController.notNowButtonTitle = "Refuser"
        locationRequestController.authorizeType = .requestWhenInUseAuthorization
        locationRequestController.delegate = self
        locationRequestController.present(onViewController: self)
    }
    
    func queryObjectsFromDB(typeCategorie : String, withLocation : Bool){
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Chargement en cours")
        
        self.commerces = []
        let query = PFQuery(className: "Commerce")
        query.whereKey("typeCommerce", equalTo: typeCategorie)
        if withLocation{
//            let userPosition = PFGeoPoint(location: latestLocationForQuery)
//            query.whereKey("position", nearGeoPoint: userPosition)
            query.order(byDescending: "position")
        }else{
            query.order(byAscending: "nombrePartages")
        }
        query.includeKey("photosSlider")
        query.findObjectsInBackground { (objects : [PFObject]?, error : Error?) in
            
            if error == nil {
                if let arr = objects{
//                    print("Number of items in BDD : \(arr.count)")
                    
                    for obj in arr {
                        let commerce = Commerce(parseObject: obj)
                        self.commerces.append(commerce)
                    }
                    
                    let headerImage = HelperAndKeys.getImageForTypeCommerce(typeCommerce: typeCategorie)
                    self.headerTypeCommerceImage.image = headerImage
                    self.collectionView.reloadData()
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            } else {
                if let err = error{
//                    let _ = HelperAndKeys.handleParseError(errorCode: (error! as NSError).code)
                    SVProgressHUD.showError(withStatus: err.localizedDescription)
                    SVProgressHUD.dismiss(withDelay: 2)
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "commerceDetailSegue" {
            if let cell = sender as? UICollectionViewCell {
                let indexPath = self.collectionView.indexPath(for: cell)!
                let detailViewController = segue.destination as! DetailCommerceViewController
                detailViewController.commerceObject = self.commerces[indexPath.row] // like this
            }
        }
    }
}

extension AccueilCommerces : UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.commerces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commerceCell", for: indexPath) as! CommerceViewCell
        
        let textColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)
        
        let comm = self.commerces[indexPath.row]
        
        // Ajout du contenu (valeures)
        cell.nomCommerce.text = comm.nom
        cell.nombrePartageLabel.text = String(comm.partages)
        
        // Ajout de couleur
        cell.nomCommerce.textColor = textColor
        cell.nombrePartageLabel.textColor = textColor
        
        if let imageThumbnailFile = comm.thumbnail {
            cell.thumbnailPicture.sd_setImage(with: URL(string: imageThumbnailFile.url!))
        }else if let coverPhoto = comm.coverPhoto{
            cell.thumbnailPicture.sd_setImage(with: URL(string: coverPhoto.url!))
        }
        else {
            cell.thumbnailPicture.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: comm.type)
        }
        
        
        let background = cell.viewWithTag(999)!
        background.setCardView(view: background)
        return cell
    }
}

extension AccueilCommerces : DropDownMenuDelegate {
    
    func prepareNavigationBarMenuTitleView() -> String {
        titleView = DropDownTitleView()
        titleView.addTarget(self,
                            action: #selector(AccueilCommerces.willToggleNavigationBarMenu(_:)),
                            for: .touchUpInside)
        
        titleView.titleLabel.textColor = UIColor.white
        titleView.imageView.tintColor = UIColor.white
        
        navigationItem.titleView = titleView
        
        return titleView.title!
    }
    
    func prepareNavigationBarMenu(_ currentChoice: String) {
        navigationBarMenu = DropDownMenu(frame: view.bounds)
        navigationBarMenu.delegate = self
        
        for string in toutesCat  {
            
            let cell = DropDownMenuCell()
            cell.textLabel!.text = string
            cell.menuAction = #selector(AccueilCommerces.choose(_:))
            cell.menuTarget = self
            if currentChoice == cell.textLabel!.text {
                cell.accessoryType = .checkmark
            }
            
            catCells.append(cell)
        }
        
        navigationBarMenu.menuCells = catCells
        navigationBarMenu.selectMenuCell(catCells[13])
//        navigationBarMenu.selectMenuCell(catCells.first!)
        
        // For a simple gray overlay in background
        navigationBarMenu.backgroundView = UIView(frame: navigationBarMenu.bounds)
        navigationBarMenu.backgroundView!.backgroundColor = UIColor.black
        navigationBarMenu.backgroundAlpha = 0.7
    }
    
    @IBAction func showToolbarMenu() {if titleView.isUp {titleView.toggleMenu()}}
    // Quand on appui sur la bar de navigation
    @IBAction func willToggleNavigationBarMenu(_ sender: DropDownTitleView) {if sender.isUp {navigationBarMenu.hide()} else {navigationBarMenu.show()}}
    // Quand on appui sur le fond
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {if menu == navigationBarMenu {titleView.toggleMenu()} else {menu.hide()}}
    
    /**
     
     Choose action
     
     */
    
    @IBAction func choose(_ sender: AnyObject) {
        let itemChoose = (sender as! DropDownMenuCell).textLabel!.text
        titleView.title = itemChoose
        labelHeaderCategorie.text = itemChoose!
        queryObjectsFromDB(typeCategorie: itemChoose!, withLocation: locationGranted)
        if didLoad {
            titleView.toggleMenu()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in }, completion: nil)
    }
}

extension AccueilCommerces : KJNavigaitonViewScrollviewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewKJNavigation.scrollviewMethod?.scrollViewDidScroll(scrollView)
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewKJNavigation.scrollviewMethod?.scrollViewWillBeginDragging(scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewKJNavigation.scrollviewMethod?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewKJNavigation.scrollviewMethod?.scrollViewDidEndDecelerating(scrollView)
    }
}

extension AccueilCommerces : STLocationRequestControllerDelegate{
    @objc func locationRequestControllerDidChange(_ event: STLocationRequestControllerEvent) {
        switch event {
        case .locationRequestAuthorized:
            self.locationManager.startUpdatingLocation()
            locationGranted = true
            break
        case .locationRequestDenied:
            locationGranted = false
            break
        case .notNowButtonTapped:
            locationGranted = false
            break
        case .didPresented:
            locationGranted = false
            break
        case .didDisappear:
            locationGranted = false
            break
        }
    }
}

extension AccueilCommerces: CLLocationManagerDelegate {
    
    /// CLLocationManagerDelegate DidFailWithError Methods
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error. The Location couldn't be found. \(error)")
    }
    
    /// CLLocationManagerDelegate didUpdateLocations Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        self.latestLocationForQuery = locations.last
    }
    
}

extension AccueilCommerces : PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate{
    func showDialogConnection(){
        definesPresentationContext = true
        // En vous inscrivant, vous pourrez profiter de tous les avantages de l'application, tels que les promotions des commerçants ou l'accès direct à vos commerces favoris.
        let dialog = AZDialogViewController(title: "Connexion", message: "Veuillez vous connecter afin d'accéder à votre espace personnel")
        dialog.dismissDirection = .bottom
        dialog.dismissWithOutsideTouch = true
        dialog.showSeparator = true
        dialog.allowDragGesture = false
        dialog.addAction(AZDialogAction(title: "Connexion") { (dialog) -> (Void) in
            self.showParseUI()
            dialog.dismiss()
        })
        dialog.cancelEnabled = true
        dialog.cancelButtonStyle = { (button,height) in
            button.setTitle("ANNULER", for: [])
            return true // must return true, otherwise cancel button won't show.
        }
        dialog.show(in: self)
    }
    
    func showParseUI(){
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
        
        if let presented = self.presentedViewController {
            presented.removeFromParentViewController()
        }
        
        self.present(logInController, animated: true, completion: nil)
    }

    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        self.getFacebookInformations(user: user)
        print("Login")
        logInController.dismiss(animated: true)
        if let story = self.storyboard {
            let nav = story.instantiateViewController(withIdentifier: "choose_type_compte") as! UINavigationController
            self.present(nav, animated: true)
        }
//        print("succesful login : \(user.description)")
    }
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        if let parseError = error{
            let nserror = parseError as NSError
            print("Erreur de login : \nCode (\(nserror.code))\n     -> \(nserror.localizedDescription)")
        }
    }
    
    // Inscription classique (par mail)
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
       print("succesful signup : \(user.description)")
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
}

extension UIView {
    func setCardView(view : UIView){
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 3;
    }
    
    func setShadow(view : UIView){
        
        view.layer.cornerRadius = 0
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 0)
        
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 20, height: 20);
        view.layer.shadowOpacity = 1
        view.layer.shadowPath = shadowPath.cgPath
    }
}
