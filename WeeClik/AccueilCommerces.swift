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
import STLocationRequest
import CoreLocation
import AZDialogView
import CRNotifications
import BulletinBoard

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
            if self.prefFiltreLocation == false{
                self.prefFiltreLocation = true
            }
            item.displayNextItem()
//            item.manager?.dismissBulletin(animated: true)
        }
        bulletinPageIntro.alternativeHandler = { (item : BulletinItem) in
            // Action par nombre
            if self.prefFiltreLocation == true {
                self.prefFiltreLocation = !self.prefFiltreLocation
            }
            item.displayNextItem()
        }
        introBulletin.actionHandler = { (item : BulletinItem) in
            item.manager?.dismissBulletin(animated:true)
            
            self.defaults.set(self.prefFiltreLocation, forKey: HelperAndKeys.getLocationPreferenceKey())
            self.defaults.synchronize()
            
            self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: self.prefFiltreLocation)
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
        
        
        // Liste toutes les catégories possibles
        toutesCat = HelperAndKeys.getListOfCategories()
        
        
        // Creation du Menu catégories
        viewKJNavigation.topbarMinimumSpace = .custom(height: 150)
        viewKJNavigation.setupFor(CollectionView: collectionView, viewController: self)
        
        
        // Ajout du contenu au Menu catégories
        let title = prepareNavigationBarMenuTitleView()
        prepareNavigationBarMenu(title)
        
        self.checkLocationServicePermission()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationBarMenu.container = view
        didLoad = true
        
        
        
//        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Login_icon") , style: .plain, target: self, action: #selector(showConnectionPage)), UIBarButtonItem(image: UIImage(named:"Logout_icon"), style: .plain, target: self, action: #selector(logOut(_:)))]
//        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Login_icon") , style: .plain, target: self, action: #selector(showConnectionPage)), UIBarButtonItem(image: UIImage(named:"Logout_icon"), style: .plain, target: self, action: #selector(logOut(_:)))]
    }
    
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
        query.includeKeys(["thumbnailPrincipal", "photosSlider"])
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
//                    print("Number of items in BDD : \(arr.count)")
                    
                    for obj in arr {
                        let commerce = Commerce(parseObject: obj)
                        self.commerces.append(commerce)
                    }
                    
                    self.collectionView.reloadData()
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            } else {
                if let err = error{
                    let nsError = err as NSError
//                    if nsError.code == PFErrorCode.errorInvalidSessionToken.rawValue {
                        PFUser.logOut()
                        self.queryObjectsFromDB(typeCategorie: self.titleChoose, withLocation: self.locationGranted)
//                    }
//                    let errorHandle = HelperAndKeys.handleParseError(error: (err as NSError))
//                    SVProgressHUD.showError(withStatus: err.localizedDescription + " code : \(nsError.code)")
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
                detailViewController.commerceObject = self.commerces[indexPath.row]
            }
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
        
        print(self.prefFiltreLocation)
        
        if self.prefFiltreLocation {
            // Filtré par positions
            cell.nombrePartageLabel.text = self.calculDistanceEntreDeuxPoints(commerce: comm)
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
//        print(self.locationGranted)
//        print("First Load Finished : \(HelperAndKeys.isAppFirstLoadFinished())")
        
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

extension AccueilCommerces : STLocationRequestControllerDelegate{
    @objc func locationRequestControllerDidChange(_ event: STLocationRequestControllerEvent) {
        switch event {
        case .locationRequestAuthorized:
            self.locationManager.startUpdatingLocation()
            HelperAndKeys.setAppFirstLoadFinished()
            locationGranted = true
            HelperAndKeys.setLocationFilterPreference(locationGranted: self.locationGranted)
            self.queryObjectsFromDB(typeCategorie: titleChoose, withLocation: locationGranted)
            break
        case .locationRequestDenied, .notNowButtonTapped:
            HelperAndKeys.setAppFirstLoadFinished()
            locationGranted = false
            HelperAndKeys.setLocationFilterPreference(locationGranted: self.locationGranted)
            self.queryObjectsFromDB(typeCategorie: titleChoose, withLocation: locationGranted)
            break
        case  .didPresented, .didDisappear:
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
