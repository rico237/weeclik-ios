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
import SVProgressHUD // FIXME: Replace with this pod : IHProgressHUD + remove from pull to refresh
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

    var toutesCat: [CommerceType] = CommerceType.allCases
    var commerces: [Commerce]   = []
    let locationManager         = CLLocationManager()
    var latestLocationForQuery: CLLocation!
    let defaults                = UserDefaults.standard
    var prefFiltreLocation      = false                 // Savoir si les commerces sont filtrés par location ou partages
    var locationGranted         = false                 // On a obtenu la position de l'utilisateur
    var isLoadingCommerces      = false               // si la fonction de chargement des commerces est en cours
    var titleChoose: String     = "Restauration".localized()        // First category to be loaded
    var selectedIndex: Int = 0

    @IBOutlet weak var labelHeaderCategorie: UILabel!
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var headerTypeCommerceImage: UIImageView!
//    @IBOutlet weak var viewKJNavigation: KJNavigationViewAnimation!
    @IBOutlet weak var viewKJNavigation: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    var introBulletin = BulletinDataSource.makeFilterNextPage()

    lazy var filterBulletinManager: BLTNItemManager = {
        let bulletinPageIntro = BulletinDataSource.makeFilterPage()
        bulletinPageIntro.actionHandler = { item in
            // By location
            self.prefFiltreLocation = true
            item.manager?.displayNextItem()
        }
        bulletinPageIntro.alternativeHandler = { (item: BLTNItem) in
            // By number
            self.prefFiltreLocation = false
            item.manager?.displayNextItem()
        }
        introBulletin.actionHandler = { (item: BLTNItem) in
            // Last action
            item.manager?.dismissBulletin(animated: true)

            if self.prefFiltreLocation {
                self.checkLocationServicePermission()
            } else {
                self.chooseCategorie(itemChoose: self.titleChoose, withHud: true)
            }

            HelperAndKeys.setPrefFiltreLocation(filtreLocation: self.prefFiltreLocation)
        }
        bulletinPageIntro.next = introBulletin
        bulletinPageIntro.requiresCloseButton = false
        return BLTNItemManager(rootItem: bulletinPageIntro)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Init location manager (get user location)
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter  = kCLDistanceFilterNone

        self.refreshControl.attributedTitle = NSAttributedString(string: "")
//        self.refreshControl.addTarget(self, action: #selector(refreshCollectionData(_:)), for: .valueChanged)
        
//        self.collectionView.refreshControl = refreshControl
        self.collectionView.backgroundColor  = Colors.backgroundColor
        self.collectionView.collectionViewLayout = columnLayout
        self.collectionView.contentInsetAdjustmentBehavior = .always

        // Init of retracting header (header image)
//        viewKJNavigation.topbarMinimumSpace = .custom(height: 250)
//        viewKJNavigation.setupFor(CollectionView: collectionView, viewController: self)

        // Choisir le filtrage par defaut (Position ou partage)
        if defaults.contains(key: Constants.UserDefaultsKeys.prefFilterLocationKey) {
            // la clé existe donc on peut recuperer la valeure
            self.prefFiltreLocation = HelperAndKeys.getPrefFiltreLocation()
        } else {
            // la clé n'existe pas
            HelperAndKeys.setPrefFiltreLocation(filtreLocation: false)
            self.prefFiltreLocation = HelperAndKeys.getPrefFiltreLocation()
        }

        // Check for location permission
        // If doesn't exist permission will be asked when user want to
        if defaults.contains(key: Constants.UserDefaultsKeys.prefFilterLocationKey) {
            // Key exist so we fetch the value
            self.locationGranted = HelperAndKeys.getLocationGranted()
        }

        // Demande de filtre par position sans authorisation de prendre la geoposition
        if self.prefFiltreLocation {
            self.checkLocationServicePermission()
        } else {
            // Load first object based on number of sharing
            self.chooseCategorie(itemChoose: self.titleChoose, withHud: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        if self.prefFiltreLocation && self.locationGranted {
            self.locationManager.startUpdatingLocation()
        } else {
            discretReload()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        HelperAndKeys.setLocationGranted(locationGranted: self.locationGranted)
        HelperAndKeys.setPrefFiltreLocation(filtreLocation: self.prefFiltreLocation)
    }

    func discretReload() {
        chooseCategorie(itemChoose: titleChoose, withHud: false)
    }

    @objc private func refreshCollectionData(_ sender: Any) {
        // From refresh
        self.discretReload()
    }
}

// Parse functions (model in MVC)
extension AccueilCommerces {
    func chooseCategorie(itemChoose: String, withHud showHud: Bool) {
        // Update UI
        titleChoose = itemChoose
        labelHeaderCategorie.text = itemChoose
        headerTypeCommerceImage.image = toutesCat[selectedIndex].image

        // Update Data
        queryObjectsFromDB(typeCategorie: titleChoose, withHUD: showHud)
    }

    func queryObjectsFromDB(typeCategorie: String, withHUD showHud: Bool = true) {
        // Chargement des commerces
        self.refreshControl.beginRefreshing()
        self.commerces = [Commerce]()
        if showHud {
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.setDefaultStyle(.dark)
            SVProgressHUD.show(withStatus: "Chargement en cours".localized())
        }
        // Regarder du coté du discret reload et du query qui pourraient être appelé en meme temps
        if self.prefFiltreLocation {
            self.locationManager.startUpdatingLocation()
        } else {
            ParseService.shared.sharingPrefsCommerces(withType: typeCategorie) { (commerces, error) in
                self.globalObjects(commerces: commerces, error: error, hudView: showHud)
            }
        }
    }

    func globalObjects(commerces: [Commerce]?, error: Error?, hudView: Bool) {
        if let commerces = commerces {
            self.commerces = commerces
        } else if let error = error {
            ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true) {
                self.chooseCategorie(itemChoose: self.titleChoose, withHud: false)
            }
        }
        DispatchQueue.global(qos: .default).async(execute: {
            if hudView {
                SVProgressHUD.dismiss(withDelay: 1)
            }
        })
        collectionView.reloadData()
        isLoadingCommerces = false
        refreshControl.endRefreshing()
    }
}
// MARK: Routing & Navigation Bar functions
extension AccueilCommerces {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "commerceDetailSegue",
            let cell = sender as? UICollectionViewCell,
            let detailViewController = segue.destination as? DetailCommerceViewController {
            
            let indexPath = self.collectionView.indexPath(for: cell)!
            detailViewController.commerceID = self.commerces[indexPath.row].objectId!
            detailViewController.routeCommerceId = self.commerces[indexPath.row].objectId!
            detailViewController.commerceObject = self.commerces[indexPath.row]
            
        } else if segue.identifier == "searchSegue",
            let navigationController = segue.destination as? UINavigationController,
            let searchController = navigationController.topViewController as? SearchViewController {
                searchController.commerces = self.commerces
        }
    }
    @IBAction func showProfilPage(_ sender: Any) {
        performSegue(withIdentifier: "routeConnecte", sender: self)
    }

    @IBAction func logOut(_ sender: Any) {
        PFUser.logOutInBackground()
        showBasicToastMessage(withMessage: "Vous êtes bien déconnecté".localized())
    }

    // Selection between location and max number of share
    @IBAction func filterBarbuttonPressed(_ sender: Any) {
        filterBulletinManager.showBulletin(above: self)
    }
}
// Functions for collections (Data & Delegate)
extension AccueilCommerces: UICollectionViewDelegate, UICollectionViewDataSource {
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
            selectedIndex = indexPath.row
            self.chooseCategorie(itemChoose: toutesCat[indexPath.row].rawValue, withHud: true)
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
            cell.typeName.text = self.toutesCat[indexPath.row].rawValue
            cell.backgroundCategorie.image = toutesCat[indexPath.row].image
            return cell
        }
        // Commerce cells
        else {

            if ((self.commerces[safe: indexPath.row]) != nil) {
                // Dans l'index
                collectionView.register(UINib(nibName: "CommerceCVC", bundle: nil), forCellWithReuseIdentifier: "commerceCell")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commerceCell", for: indexPath) as! CommerceCVC
                let textColor = UIColor(red: 0.11, green: 0.69, blue: 0.96, alpha: 1.00)

                let comm = self.commerces[indexPath.row]
                // Ajout du contenu (valeures)
                cell.nomCommerce.text = comm.nom
                cell.nombrePartageLabel.text = String(comm.partages)

                let distanceFromUser = comm.calculDistanceEntreDeuxPoints(location: self.latestLocationForQuery)
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
                    cell.thumbnailPicture.image = toutesCat[selectedIndex].image
                }

                return cell
            } else {
                // En dehors de l'index
                return UICollectionViewCell()
            }
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
        locationManager.stopUpdatingLocation()
        latestLocationForQuery = locations.last
//        print("Did update position : \(locations.last?.description ?? "No Location Provided")")
        ParseService.shared.locationPrefsCommerces(withType: titleChoose, latestKnownPosition: latestLocationForQuery) { (commerces, error) in
            self.locationGranted = true
            self.globalObjects(commerces: commerces, error: error, hudView: true)
        }
    }
}

// Header Window above objects
//extension AccueilCommerces: KJNavigaitonViewScrollviewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        viewKJNavigation.scrollviewMethod?.scrollViewDidScroll(scrollView)
//    }
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        viewKJNavigation.scrollviewMethod?.scrollViewWillBeginDragging(scrollView)
//    }
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        viewKJNavigation.scrollviewMethod?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
//    }
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        viewKJNavigation.scrollviewMethod?.scrollViewDidEndDecelerating(scrollView)
//    }
//}
// Functions for requesting localisation permission
extension AccueilCommerces: SPPermissionDialogDelegate {
    func didAllow(permission: SPPermissionType) {
        if permission == .locationAlwaysAndWhenInUse || permission == .locationAlwaysAndWhenInUse {
            locationGranted = true
            prefFiltreLocation = true
            HelperAndKeys.setPrefFiltreLocation(filtreLocation: true)
            HelperAndKeys.setLocationGranted(locationGranted: true)
            chooseCategorie(itemChoose: self.titleChoose, withHud: true)
        }
    }

    func didDenied(permission: SPPermissionType) {
        if permission == .locationAlwaysAndWhenInUse || permission == .locationAlwaysAndWhenInUse {
            locationGranted = false
            prefFiltreLocation = false
            HelperAndKeys.setPrefFiltreLocation(filtreLocation: false)
            HelperAndKeys.setLocationGranted(locationGranted: false)
            chooseCategorie(itemChoose: self.titleChoose, withHud: true)
            dismiss(animated: true, completion: nil)
        }
    }

    func checkLocationServicePermission() {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .denied:
                // Location Services are denied
                locationGranted = false
                showSettingsAlert(withTitle: "Position désactivé".localized(), withMessage: "Nous n'arrivons a determiner votre position, afin de vous afficher les commerces près de vous.\n\nVous pouvez autoriser la géolocalisation dans l'application \"Réglages\" de votre téléphone.".localized())
                
            case .authorizedAlways, .authorizedWhenInUse:
                // The user has already allowed your app to use location services. Start updating location
                locationGranted = true
                locationManager.startUpdatingLocation()
                
            case .notDetermined:
                SPPermission.Dialog.request(with: [.locationWhenInUse], on: self, delegate: self, dataSource: self)
                
            case .restricted:
                // Location Services are disabled
                locationGranted = false
                showSettingsAlert(withTitle: "Position désactivé".localized(), withMessage: "La localisation est désactivé nous ne pouvons déterminer votre position. Veuillez l'activer afin de continuer.".localized())
                
            default:
                SPPermission.Dialog.request(with: [.locationWhenInUse], on: self, delegate: self, dataSource: self)
            }
        }

        HelperAndKeys.setLocationGranted(locationGranted: locationGranted)
        chooseCategorie(itemChoose: titleChoose, withHud: false)
    }
}
// Custom UI for asking permission (alert controller)
extension AccueilCommerces: SPPermissionDialogDataSource {
    var dialogTitle: String { return "Demande de position".localized() }
    var dialogSubtitle: String { return "Position nécessaire pour ce filtre".localized() }
    var dialogComment: String { return "Cette fonctionnalité vous permet de voir les commerces autour de vous.".localized() }
    var cancelTitle: String { return "Annuler".localized() }
    var settingsTitle: String { return "Réglages".localized() }

    var allowTitle: String { return "Autoriser".localized() }
    var allowedTitle: String { return "Autorisé".localized() }

    func name(for permission: SPPermissionType) -> String? {
        if permission == .locationWhenInUse || permission == .locationAlwaysAndWhenInUse { return "Position".localized() }
        return nil
    }
    func description(for permission: SPPermissionType) -> String? {
        if permission == .locationWhenInUse || permission == .locationAlwaysAndWhenInUse {
            return "Permet de vous géolocaliser".localized() }
        return nil
    }
    func deniedTitle(for permission: SPPermissionType) -> String? { return "Refusé".localized() }
    func deniedSubtitle(for permission: SPPermissionType) -> String? {
        return "Autorisation refusé. Merci de les changer dans les réglages.".localized()
    }

    var showCloseButton: Bool { return false }
}
