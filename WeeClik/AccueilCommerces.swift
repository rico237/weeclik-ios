//
//  AccueilCommerces.swift
//  WeeClik
//
//  Created by Herrick Wolber on 21/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO : Ajouter un message si il n'ya pas d'objet
// TODO : Ajouter un systeme de pagination pour le chargement des commerces
// TODO : Gerer les pbs de connexions si trop long afficher un message d'erreur

// UP : Ajouter les commerces favoris
// UP : Ajouter le filtre des commerces selon le filtre de leboncoin ios

import UIKit
import Parse
import SVProgressHUD
import KJNavigationViewAnimation
import KRLCollectionViewGridLayout
import SDWebImage
import CoreLocation
import CRNotifications
import BLTNBoard
import SPPermission

// Life Cycle & other functions
class AccueilCommerces: UIViewController {

    let columnLayout = GridFlowLayout(cellsPerRow: 2, minimumInteritemSpacing: 10, minimumLineSpacing: 10, sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    
    private let refreshControl = UIRefreshControl()
    
    let network: NetworkManager = NetworkManager.sharedInstance
    var toutesCat       : Array<String>!    = HelperAndKeys.getListOfCategories()
    var commerces       : [Commerce]   = []
    var currentPage     : Int! = 0                      // The last page that was loaded
    var lastLoadCount   : Int! = -1                     // The count of objects from the last load. Set to -1 when objects haven't loaded, or there was an error.
    let itemsPerPages   : Int! = 25                     // Nombre de commerce chargé à la fois (eviter la surchage de réseau etc.)
    let locationManager         = CLLocationManager()
    var latestLocationForQuery : CLLocation!
    let defaults                = UserDefaults.standard
    var prefFiltreLocation      = false                 // Savoir si les commerces sont filtrés par location ou partages
    var locationGranted : Bool! = false                 // On a obtenu la position de l'utilisateur
    var titleChoose : String!   = "Restauration"        // First category to be loaded
    
    @IBOutlet weak var labelHeaderCategorie: UILabel!
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var headerTypeCommerceImage: UIImageView!
    @IBOutlet weak var viewKJNavigation: KJNavigationViewAnimation!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    var introBulletin = BulletinDataSource.makeFilterNextPage()
    
    lazy var filterBulletinManager : BLTNItemManager = {
        let bulletinPageIntro = BulletinDataSource.makeFilterPage()
        bulletinPageIntro.actionHandler = { item in
            // By location
            self.prefFiltreLocation = true
            item.manager?.displayNextItem()
        }
        bulletinPageIntro.alternativeHandler = { (item : BLTNItem) in
            // By number
            self.prefFiltreLocation = false
            item.manager?.displayNextItem()
        }
        introBulletin.actionHandler = { (item : BLTNItem) in
            // Last action
            item.manager?.dismissBulletin(animated:true)
            
            if self.prefFiltreLocation {
                self.checkLocationServicePermission()
            } else {
                self.chooseCategorie(itemChoose: self.titleChoose)
            }
            
            HelperAndKeys.setPrefFiltreLocation(filtreLocation: self.prefFiltreLocation)
        }
        bulletinPageIntro.next = introBulletin
        bulletinPageIntro.requiresCloseButton = false
        return BLTNItemManager(rootItem : bulletinPageIntro)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Init location manager (get user location)
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter  = kCLDistanceFilterNone
        // Init collectionview for commerces (object cells)
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        if #available(iOS 10.0, *) {
            self.collectionView.refreshControl = refreshControl
        } else {
            self.collectionView.addSubview(refreshControl)
        }
        self.refreshControl.addTarget(self, action: #selector(refreshCollectionData(_:)), for: .valueChanged)
        self.collectionView.backgroundColor  = HelperAndKeys.getBackgroundColor()
        self.collectionView.collectionViewLayout = columnLayout
        if #available(iOS 11.0, *) {self.collectionView.contentInsetAdjustmentBehavior = .always}
        
        // Init of retracting header (header image)
        viewKJNavigation.topbarMinimumSpace = .custom(height: 200)
        viewKJNavigation.setupFor(CollectionView: collectionView, viewController: self)
        
        // Choisir le filtrage par defaut (Position ou partage)
        if defaults.contains(key: HelperAndKeys.getPrefFilterLocationKey()) {
            // la clé existe donc on peut recuperer la valeure
            self.prefFiltreLocation = HelperAndKeys.getPrefFiltreLocation()
        } else {
            // la clé n'existe pas
            HelperAndKeys.setPrefFiltreLocation(filtreLocation: false)
            self.prefFiltreLocation = HelperAndKeys.getPrefFiltreLocation()
        }
        
        // Check for location permission
        // If doesn't exist permission will be asked when user want to
        if defaults.contains(key: HelperAndKeys.getLocationPreferenceKey()) {
            // Key exist so we fetch the value
            self.locationGranted = HelperAndKeys.getLocationGranted()
        }
        
        // Update user position if filtre location is enabled
        if self.prefFiltreLocation || self.locationGranted {
            self.locationManager.startUpdatingLocation()
        }
        print("First load")
        // Load first object based on location or number of sharing
        self.chooseCategorie(itemChoose: self.titleChoose)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        if self.commerces.count != 0 {
            self.discretReload()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        HelperAndKeys.setLocationGranted(locationGranted: self.locationGranted)
        HelperAndKeys.setPrefFiltreLocation(filtreLocation: self.prefFiltreLocation)
    }
    
    func discretReload(){
        print("Discret reload")
        self.queryObjectsFromDB(typeCategorie: self.titleChoose, withHUD: false)
    }
    
    @objc private func refreshCollectionData(_ sender: Any) {
        // From refresh
        print("refresh reload")
        self.queryObjectsFromDB(typeCategorie: self.titleChoose)
    }
}


// Parse functions (model in MVC)
extension AccueilCommerces {
    func chooseCategorie(itemChoose: String) {
        // Update UI
        self.titleChoose = itemChoose
        self.labelHeaderCategorie.text = itemChoose
        self.headerTypeCommerceImage.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: titleChoose)
        
        // Update Data
        self.queryObjectsFromDB(typeCategorie: titleChoose)
    }
    
    func queryObjectsFromDB(typeCategorie : String, withHUD showHud: Bool = true){
        print("Ftech with show hud \(showHud)")
//        print("Fetch new items with location pref : \(self.prefFiltreLocation) \nand location granted : \(self.locationGranted)")
        self.refreshControl.beginRefreshing()
        
        NetworkManager.isReachable { (networkInstance) in
            if showHud {
                SVProgressHUD.setDefaultMaskType(.clear)
                SVProgressHUD.setDefaultStyle(.dark)
                SVProgressHUD.show(withStatus: "Chargement en cours")
            }
            
            self.commerces = []
            let query = PFQuery(className: "Commerce")
            query.whereKey("typeCommerce", equalTo: typeCategorie)
            query.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])
            query.whereKey("statutCommerce", equalTo: 1)
            query.whereKey("brouillon", equalTo: false)
            
            if self.prefFiltreLocation {
                let userPosition = PFGeoPoint(location: self.latestLocationForQuery)
                query.whereKey("position", nearGeoPoint: userPosition)
                query.order(byAscending: "position")
            } else {
                query.order(byDescending: "nombrePartages")
            }
            query.findObjectsInBackground { (objects : [PFObject]?, error : Error?) in
                
                if let error = error {
                    if error.code == PFErrorCode.errorInvalidSessionToken.rawValue {
                        PFUser.logOut()
                        self.chooseCategorie(itemChoose: self.titleChoose)
                    }
                    
                    if showHud {
                        SVProgressHUD.showError(withStatus: ParseErrorCodeHandler.handleParseError(error: error))
                        SVProgressHUD.dismiss(withDelay: 2)
                    }
                } else if let objects = objects {
                    for obj in objects {
                        let commerce = Commerce(parseObject: obj)
                        self.commerces.append(commerce)
                    }
                    
                    // tri du tableau par position
                    if self.prefFiltreLocation {
                        let sorteCommerce = self.commerces.sorted(by: {
                            PFGeoPoint(location: self.latestLocationForQuery).distanceInKilometers(to: $0.location) < PFGeoPoint(location: self.latestLocationForQuery).distanceInKilometers(to: $1.location)
                        })
                        self.commerces = sorteCommerce
                    }
                    
                    if showHud {
                        SVProgressHUD.dismiss(withDelay: 1)
                    }
                    
                }
                print("Did finish loading commerces")
                self.collectionView.reloadData()
            }
        }
        
        NetworkManager.isUnreachable { (networkInstance) in
            // TODO: ajouter un message / illustration si pas de connection
            print("No connection")
        }
        
        self.refreshControl.endRefreshing()
    }
}
// Routing & Navigation Bar functions
extension AccueilCommerces {
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "commerceDetailSegue" {
            if let cell = sender as? UICollectionViewCell {
                let indexPath = self.collectionView.indexPath(for: cell)!
                let detailViewController = segue.destination as! DetailCommerceViewController
                detailViewController.commerceObject = self.commerces[indexPath.row]
            }
        } else if segue.identifier == "searchSegue" {
            let nav = segue.destination as! UINavigationController
            let searchController = nav.topViewController as! SearchViewController
            searchController.commerces = self.commerces
        }
    }
    @IBAction func showProfilPage(_ sender: Any){
        // routeConnecte
        self.performSegue(withIdentifier: "routeConnecte", sender: self)
    }
    
    @IBAction func logOut(_ sender: Any) {
        PFUser.logOutInBackground()
        HelperAndKeys.showAlertWithMessage(theMessage: "Vous êtes bien déconnecté", title: "Deconnexion", viewController: self)
    }
    
    // Selection between location and max number of share
    @IBAction func filterBarbuttonPressed(_ sender: Any) {
        filterBulletinManager.showBulletin(above: self)
    }
}
// Functions for collections (Data & Delegate)
extension AccueilCommerces : UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            // Menu
            return self.toutesCat.count
        } else {
            // Commerces
            return self.commerces.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 0 {
            // Menu
            // Hack for text to be visible when selected
            collectionView.deselectItem(at: indexPath, animated: false)
            self.chooseCategorie(itemChoose: self.toutesCat[indexPath.row])
            collectionView.reloadData()
        } else {
            // Objects
            self.performSegue(withIdentifier: "commerceDetailSegue", sender: collectionView.cellForItem(at: indexPath))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Categories selection
        if collectionView.tag == 0 {
            // Register nib's cell
            collectionView.register(UINib(nibName: "CategoriesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CategoriesCollectionViewCell")
            // Cell creation
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoriesCollectionViewCell", for: indexPath) as! CategoriesCollectionViewCell
            cell.typeName.text = self.toutesCat[indexPath.row]
            cell.backgroundCategorie.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: self.toutesCat[indexPath.row])
            return cell
        }
        // Commerce cells
        else {
            collectionView.register(UINib(nibName: "CommerceCVC", bundle: nil), forCellWithReuseIdentifier: "commerceCell")
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commerceCell", for: indexPath) as! CommerceCVC
            let textColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)
            let comm = self.commerces[indexPath.row]
            
            // Ajout du contenu (valeures)
            cell.nomCommerce.text = comm.nom
            cell.nombrePartageLabel.text = String(comm.partages)
            let distanceFromUser = self.calculDistanceEntreDeuxPoints(commerce: comm)
            comm.distanceFromUser = distanceFromUser
            
            cell.imageDistance.tintColor = textColor
            
            if self.locationGranted {
                // Autorisation de position
                cell.distanceLabel.text = comm.distanceFromUser == "" ? "--" : comm.distanceFromUser
            } else {
                cell.distanceLabel.text = "--"
            }
            
            // Ajout de couleur
            cell.nomCommerce.textColor = textColor
            cell.nombrePartageLabel.textColor = textColor
            cell.distanceLabel.textColor = textColor
            
            if let imageThumbnailFile = comm.thumbnail {
                cell.thumbnailPicture.sd_setImage(with: URL(string: imageThumbnailFile.url!))
            } else {
                cell.thumbnailPicture.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: comm.type)
            }
            
            return cell
        }
    }
}
// Header Window above objects
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
// Functions for location and distance
extension AccueilCommerces : CLLocationManagerDelegate {
    /// CLLocationManagerDelegate DidFailWithError Methods
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error. The Location couldn't be found. \(error)")
    }
    
    /// CLLocationManagerDelegate didUpdateLocations Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        self.latestLocationForQuery = locations.last
    }
    
    func calculDistanceEntreDeuxPoints(commerce : Commerce) -> String {
        guard (self.latestLocationForQuery != nil) else {
            return "--"
        }
        let distance = PFGeoPoint(location: self.latestLocationForQuery).distanceInKilometers(to: commerce.location)
        
        if distance < 1 {
            commerce.distanceFromUser = "\(Int(distance * 1000)) m"
        } else {
            commerce.distanceFromUser = "\(Int(distance)) Km"
        }
        return commerce.distanceFromUser
    }
}
// Functions for requesting localisation permission
extension AccueilCommerces : SPPermissionDialogDelegate {
    func didHide() {}
    
    func didAllow(permission: SPPermissionType) {
        if case .locationWhenInUse = permission {
            self.locationManager.startUpdatingLocation()
            self.locationGranted = true
            self.prefFiltreLocation = true
            HelperAndKeys.setPrefFiltreLocation(filtreLocation: true)
            HelperAndKeys.setLocationGranted(locationGranted: true)
            self.chooseCategorie(itemChoose: self.titleChoose)
        }
    }
    
    func didDenied(permission: SPPermissionType) {
        if case .locationWhenInUse = permission {
            self.locationGranted = false
            self.prefFiltreLocation = false
            HelperAndKeys.setPrefFiltreLocation(filtreLocation: false)
            HelperAndKeys.setLocationGranted(locationGranted: false)
            self.chooseCategorie(itemChoose: self.titleChoose)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func checkLocationServicePermission() {
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == .denied {
                // Location Services are denied
                HelperAndKeys.showSettingsAlert(withTitle: "Localisation désactivé", withMessage: "Nous n'arrivons a determiner votre position, afin de vous afficher les commerces près de vous.", presentFrom: self)
                self.locationGranted = false
            } else {
                if CLLocationManager.authorizationStatus() == .notDetermined {
                    SPPermission.Dialog.request(with: [.locationWhenInUse], on: self, delegate: self, dataSource: PermissionDataSource())
                } else {
                    // The user has already allowed your app to use location services. Start updating location
                    self.locationManager.startUpdatingLocation()
                    self.locationGranted = true
                }
            }
        } else {
            // Location Services are disabled
            HelperAndKeys.showSettingsAlert(withTitle: "Localisation désactivé", withMessage: "La localisation est désactivé nous ne pouvons déterminer votre position. Veuillez l'activer afin de continuer.", presentFrom: self)
            self.locationGranted = false
        }
        
        HelperAndKeys.setLocationGranted(locationGranted: self.locationGranted)
        self.chooseCategorie(itemChoose: self.titleChoose)
    }
}
// Custom UI for asking permission (alert controller)
class PermissionDataSource : SPPermissionDialogDataSource {
    
    // TODO: Maybe customize more
    
    var dialogTitle: String = "Demande d'autorisation"
    var dialogSubtitle: String = "Weeclik a besoin de votre autorisation pour fonctionner"
    var cancelTitle: String = "Annuler"
    var settingsTitle: String = "Réglages"
    
    func deniedSubtitle(for permission: SPPermissionType) -> String? {
        return "Autorisation refusé. Merci de les changer dans les réglages."
    }
}
