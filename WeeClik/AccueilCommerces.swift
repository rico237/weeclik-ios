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
// TODO: Ajouter les boutons du menu
// TODO: Gerer les pbs de connexions si trop long afficher un message d'erreur
// TODO: Ajouter les commerces favoris
// TODO: Ajouter le filtre des commerces selon le filtre de leboncoin ios

import UIKit
import DropDownMenuKit
import Parse
import SVProgressHUD
import KJNavigationViewAnimation
import KRLCollectionViewGridLayout
import SDWebImage
import CoreLocation
import AZDialogView
import CRNotifications
import BulletinBoard
import Sparrow

class AccueilCommerces: UIViewController {

    let columnLayout = GridFlowLayout(cellsPerRow: 2, minimumInteritemSpacing: 10, minimumLineSpacing: 10, sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    
    var titleView       : DropDownTitleView!
    var toutesCat       : Array<String>!
    var catCells        : Array<DropDownMenuCell> = []
    var commerces       : Array<Commerce> = []
    var didLoad         : Bool! = false     // Pour charger le contenu du menu des catégories
    var firstLoad       : Bool! = false     // Whether we have loaded the first set of objects
    var currentPage     : Int! = 0          // The last page that was loaded
    var lastLoadCount   : Int! = -1         // The count of objects from the last load. Set to -1 when objects haven't loaded, or there was an error.
    let itemsPerPages   : Int! = 25         // Nombre de commerce chargé à la fois (eviter la surchage de réseau etc.)
    var locationGranted : Bool! = false     // On a obtenu la position de l'utilisateur
    let locationManager = CLLocationManager()
    var latestLocationForQuery : CLLocation!
    let defaults        = UserDefaults.standard
    var prefFiltreLocation = false            // Savoir si les commerces sont filtrés par location ou partages
    var titleChoose : String! = ""
    
    @IBOutlet weak var labelHeaderCategorie: UILabel!
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var headerTypeCommerceImage: UIImageView!
    @IBOutlet var navigationBarMenu: DropDownMenu!
    @IBOutlet weak var viewKJNavigation: KJNavigationViewAnimation!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var introBulletin = BulletinDataSource.makeFilterNextPage()
    
    
    lazy var filterBulletinManager : BulletinManager = {
        let bulletinPageIntro = BulletinDataSource.makeFilterPage()
        bulletinPageIntro.actionHandler = { item in
            // Action par position
            self.prefFiltreLocation = true
            item.displayNextItem()
        }
        bulletinPageIntro.alternativeHandler = { (item : BulletinItem) in
            // Action par nombre
            self.prefFiltreLocation = false
            item.displayNextItem()
        }
        introBulletin.actionHandler = { (item : BulletinItem) in
            item.manager?.dismissBulletin(animated:true)
            
            self.defaults.set(self.prefFiltreLocation, forKey: HelperAndKeys.getLocationPreferenceKey())
            self.defaults.synchronize()
            
            if self.prefFiltreLocation {
                self.checkLocationServicePermission()
            } else {
                self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: false)
            }
        }
        bulletinPageIntro.nextItem = introBulletin
        return BulletinManager(rootItem : bulletinPageIntro)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter  = kCLDistanceFilterNone
        
        self.collectionView.delegate   = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor  = HelperAndKeys.getBackgroundColor()
        self.collectionView.collectionViewLayout = columnLayout
        
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .always
        } else {
            // Fallback on earlier versions
        }
        
        // Choisir le filtrage par defaut (Position ou partage)
        if defaults.contains(key: HelperAndKeys.getLocationPreferenceKey()) {
            // la clé existe donc on peut recuperer la valeure
            prefFiltreLocation = defaults.bool(forKey: HelperAndKeys.getLocationPreferenceKey())
        } else {
            // la clé n'existe pas
            defaults.set(prefFiltreLocation, forKey: HelperAndKeys.getLocationPreferenceKey())
            defaults.synchronize()
        }
        
        if self.prefFiltreLocation {
            self.locationManager.startUpdatingLocation()
        }
        
        // Liste toutes les catégories possibles
        toutesCat = HelperAndKeys.getListOfCategories()
        
        // Creation du Menu catégories
        viewKJNavigation.topbarMinimumSpace = .custom(height: 150)
        viewKJNavigation.setupFor(CollectionView: collectionView, viewController: self)
        
        // Ajout du contenu au Menu catégories
        let title = prepareNavigationBarMenuTitleView()
        prepareNavigationBarMenu(title)
        
        self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: self.prefFiltreLocation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationBarMenu.container = view
        didLoad = true
    }
    
    @IBAction func showProfilPage(_ sender: Any){ self.performSegue(withIdentifier: "routeConnecte", sender: self) }
    
    @IBAction func logOut(_ sender: Any) {
        PFUser.logOutInBackground()
        HelperAndKeys.showAlertWithMessage(theMessage: "Vous êtes bien déconnecté", title: "Deconnexion", viewController: self)
    }
    
    @IBAction func filterBarbuttonPressed(_ sender: Any) {
        filterBulletinManager.prepare()
        filterBulletinManager.presentBulletin(above: self)
    }
    
    @IBAction func searchBarButtonPressed(_ sender:Any){
        print("Search")
    }
    
    func checkLocationServicePermission() {
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == .denied {
                // Location Services are denied
                HelperAndKeys.showSettingsAlert(withTitle: "Localisation désactivé", withMessage: "Nous n'arrivons a determiner votre position, afin de vous afficher les commerces près de vous.", presentFrom: self)
                self.locationGranted = false
            } else {
                if CLLocationManager.authorizationStatus() == .notDetermined {
                    SPRequestPermission.dialog.interactive.present(on: self, with: [.locationWhenInUse], dataSource: PermissionDataSource(), delegate: self)
                } else {
                    // The user has already allowed your app to use location services. Start updating location
                    self.locationManager.startUpdatingLocation()
                    locationGranted = true
                    self.setLocationSteps()
                }
            }
        } else {
            // Location Services are disabled
            HelperAndKeys.showSettingsAlert(withTitle: "Localisation désactivé", withMessage: "La localisation est désactivé nous ne pouvons déterminer votre position. Veuillez l'activer afin de continuer.", presentFrom: self)
            self.locationGranted = false
        }
    }
    
    func setLocationSteps(){
        HelperAndKeys.setAppFirstLoadFinished()
        HelperAndKeys.setLocationFilterPreference(locationGranted: self.prefFiltreLocation)
        self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: self.prefFiltreLocation)
    }
    
    func queryObjectsFromDB(typeCategorie : String, withLocation : Bool){
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Chargement en cours")
        
        self.prefFiltreLocation = withLocation
        
        self.commerces = []
        let query = PFQuery(className: "Commerce")
        query.whereKey("typeCommerce", equalTo: typeCategorie)
        query.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])
        query.whereKey("statutCommerce", equalTo: 1)
        
        if withLocation {
            let userPosition = PFGeoPoint(location: latestLocationForQuery)
            query.whereKey("position", nearGeoPoint: userPosition)
            query.order(byAscending: "position")
        } else {
            query.order(byDescending: "nombrePartages")
        }
        query.findObjectsInBackground { (objects : [PFObject]?, error : Error?) in
            if error == nil {
                if let arr = objects{
                    for obj in arr {
                        let commerce = Commerce(parseObject: obj)
                        self.commerces.append(commerce)
                    }
                    
                    // tri du tableau par position
                    if withLocation {
                        let sorteCommerce = self.commerces.sorted(by: {
                            PFGeoPoint(location: self.latestLocationForQuery).distanceInKilometers(to: $0.location) < PFGeoPoint(location: self.latestLocationForQuery).distanceInKilometers(to: $1.location)
                        })
                        self.commerces = sorteCommerce
                    }
                    
                    self.collectionView.reloadData()
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            } else {
                if let err = error{
                    let nsError = err as NSError
                    if nsError.code == PFErrorCode.errorInvalidSessionToken.rawValue {
                        PFUser.logOut()
                        self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: self.locationGranted)
                    }
                    
//                    SVProgressHUD.showError(withStatus: HelperAndKeys.handleParseError(error: (err as NSError)))
                    SVProgressHUD.dismiss(withDelay: 2)
                }
            }
            
         self.collectionView.reloadData()
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "commerceDetailSegue" {
            if let cell = sender as? UICollectionViewCell {
                let indexPath = self.collectionView.indexPath(for: cell)!
                let detailViewController = segue.destination as! DetailCommerceViewController
                detailViewController.commerceObject = self.commerces[indexPath.row]
            }
        }
    }
}

class PermissionDataSource : SPRequestPermissionDialogInteractiveDataSource {
    override func headerTitle() -> String {
        return "Demande d'autorisation"
    }
    
    override func headerSubtitle() -> String {
        return "Weeclik a besoin de votre autorisation pour fonctionner"
    }
    
    override func cancelForAlertDenidPermission() -> String {
        return "Annuler"
    }
    
    override func settingForAlertDenidPermission() -> String {
        return "Réglages"
    }
    
    override func subtitleForAlertDenidPermission() -> String {
        return "Autorisation refusé. Merci de les changer dans les réglages."
    }
}

extension AccueilCommerces: SPRequestPermissionEventsDelegate {
    func didHide() {}
    
    func didSelectedPermission(permission: SPRequestPermissionType) {}
    
    func didAllowPermission(permission: SPRequestPermissionType) {
        if case .locationWhenInUse = permission {
            self.locationManager.startUpdatingLocation()
            self.locationGranted = true
            self.prefFiltreLocation = true
            self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: true)
        }
    }
    
    func didDeniedPermission(permission: SPRequestPermissionType) {
        if case .locationWhenInUse = permission {
            self.locationGranted = false
            self.prefFiltreLocation = false
            self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: false)
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension AccueilCommerces : UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.commerces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commerceCell", for: indexPath) as! AccueilCollectionViewCell

        let textColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)

        let comm = self.commerces[indexPath.row]

        // Ajout du contenu (valeures)
        cell.nomCommerce.text = comm.nom
        
        if self.prefFiltreLocation {
            // Filtré par positions
            cell.nombrePartageLabel.text = self.calculDistanceEntreDeuxPoints(commerce: comm)
            cell.imagePartage.isHidden = self.calculDistanceEntreDeuxPoints(commerce: comm) == "" ? true : false
            cell.imagePartage.image = UIImage(named: "Map_icon")
        } else {
            // Filtré par nombre de partages
            cell.nombrePartageLabel.text = String(comm.partages)
            cell.imagePartage.image = UIImage(named: "PartagesIcon")
        }

        // Ajout de couleur
        cell.nomCommerce.textColor = textColor
        cell.nombrePartageLabel.textColor = textColor

        if let imageThumbnailFile = comm.thumbnail {
            cell.thumbnailPicture.sd_setImage(with: URL(string: imageThumbnailFile.url!))
        } else {
            cell.thumbnailPicture.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: comm.type)
        }
        return cell
    }

    func calculDistanceEntreDeuxPoints(commerce : Commerce) -> String {
        guard (self.latestLocationForQuery != nil) else {
            return ""
        }
        
        var distance = GeoHelper.distance(lat1: self.latestLocationForQuery.coordinate.latitude, lon1: self.latestLocationForQuery.coordinate.longitude, lat2: (commerce.location?.latitude)!, lon2: (commerce.location?.longitude)!, unit: "K")

        if distance < 1 {
            distance *= 1000
            commerce.distanceFromUser = "\(Int(distance)) m"
            return "\(Int(distance)) m"
        } else {
            commerce.distanceFromUser = "\(Int(distance)) Km"
            return "\(Int(distance)) Km"
        }
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
        titleChoose = itemChoose
        labelHeaderCategorie.text = itemChoose!
        let headerImage = HelperAndKeys.getImageForTypeCommerce(typeCommerce: titleChoose)
        self.headerTypeCommerceImage.image = headerImage
        
        // Au premier chargement on ne fait pas de requette
        if HelperAndKeys.isAppFirstLoadFinished() {
            self.locationGranted = HelperAndKeys.hasGrantedLocationFilter()
            self.queryObjectsFromDB(typeCategorie: titleChoose, withLocation: self.locationGranted)
        }
        
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
