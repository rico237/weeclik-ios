//
//  AjoutCommerceVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 04/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO: Ajouter reachability + demander si ils veulent uploader lles images et videos en mode cellular

import UIKit
import CoreLocation
import Parse
import TLPhotoPicker  // TODO: Regarder sur le github de la lib si je peux récup facilement le fichier video pour l'upload
import Photos
import AVKit
import SVProgressHUD
import WXImageCompress
import SwiftDate

enum UploadingStatus {
    case success
    case error
    case none
}

class AjoutCommerceVC: UITableViewController {
    
    var photoArray : [UIImage]!     = [#imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon")]          // Tableau de photos
    var loadedPhotos                = [PFObject]()          // Toutes les images conservés en BDD par le commerce
    var videoArray                  = [TLPHAsset]()         // Tableau de videos
    var thumbnailArray : [UIImage]  = [UIImage()]           // Tableau de preview des vidéos
    var selectedVideoData           = Data()                // Data de vidéos
    var didUseFinalSave             = false                 // Utilisé le bouton de sauvegarde
    var savedCommerce : Commerce?   = nil                   // Objet Commerce si on a pas utilisé le bouton sauvegarde
    var isSaving = false                                    // Sauvegarde du commerce en cours
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!       // Bouton annuler
    @IBOutlet weak var saveButton: UIBarButtonItem!         // Bouton Sauvegarder
    
    var objectIdCommerce    = ""
    var editingMode         = false                         // Mode edit d'un commerce
    var loadedFromBAAS      = false                         // Commerce venant de la BDD cloud
    
    var photos = [PFObject]()                               // Photos to be processed for saving
    var videos = [PFObject]()                               // Videos to pe processed for saving
    
    lazy var geocoder = CLGeocoder()                        // TODO: remplacer par une lib de geocoding ?
    
    // Payment Status View Outlets
    @IBOutlet weak var statusDescription: UILabel!
    @IBOutlet weak var seeMoreButton: UIButton!
    @IBOutlet weak var paymentButton: UIButton!
    
    // Valeur des champs entrées
    // TextField
    var nomCommerce         = ""
    var telCommerce         = ""
    var mailCommerce        = ""
    var adresseCommerce     = ""
    var siteWebCommerce     = ""
    var categorieCommerce   = ""
    // TextViews
    var descriptionCommerce = ""
    var promotionsCommerce  = ""
    
    // IndexPath pour les photos & videos
    var selectedRow      : Int  = 0
    var videoSelectedRow : Int  = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SVProgressHUD.setHapticsEnabled(true)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(1.5)
        
        let use = UserDefaults.standard
        if let comm = use.object(forKey: "lastCommerce") as? Commerce {
            self.loadedFromBAAS = false
            print("Commerce dans les userDefaults")
            savedCommerce = comm
        }
        
        if objectIdCommerce != "" {
            self.editingMode = true
            self.loadedFromBAAS = true
            
            SVProgressHUD.show(withStatus: "Chargement du commerce")
            savedCommerce = Commerce(objectId: objectIdCommerce)
        }
        
        self.tableView.tableHeaderView?.frame.size.height = 160
        
        self.loadCommerceInformations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if editingMode {
            self.saveButton.title = "Modifier"
            self.cancelButton.title = "Annuler"
            self.title = "MODIFIER COMMERCE"
        } else {
            self.saveButton.title = "Enregistrer"
            self.cancelButton.title = "Annuler"
            self.title = "NOUVEAU COMMERCE"
        }
    }
    
    func refreshUIPaymentStatus() {
        if editingMode {
            // Modification commerce existant
            if let savedCommerce = savedCommerce {
                // Est en mode brouillon
                // TODO: Disparait dans une navigation pop FIX URGENT
                if (savedCommerce.pfObject["brouillon"] as! Bool) {
                    self.tableView.tableHeaderView?.frame.size.height = 0
                } else {
                    self.tableView.tableHeaderView?.frame.size.height = 160
                }
                
                let paris = Region(calendar: Calendars.gregorian, zone: Zones.europeParis, locale: Locales.french)
                let endSub = savedCommerce.pfObject["endSubscription"] as! Date
                self.statusDescription.text = "Statut : \n\(savedCommerce.statut.label())\nFin : \(endSub.convertTo(region: paris).toFormat("dd MMM yyyy 'à' HH:mm"))"
                self.seeMoreButton.isEnabled = true
                if savedCommerce.statut == .paid || savedCommerce.statut == .error || savedCommerce.statut == .unknown {
                    self.paymentButton.isHidden = true
                    self.paymentButton.isUserInteractionEnabled = false
                } else {
                    // Canceled || Pending
                    self.paymentButton.isHidden = false
                    self.paymentButton.isUserInteractionEnabled = true
                }
            } else {
                self.statusDescription.text = "Statut : \nInconnu"
                self.seeMoreButton.isEnabled = false
                self.paymentButton.isHidden = true
                self.paymentButton.isUserInteractionEnabled = false
            }
        } else {
            // Nouveau commerce
            self.statusDescription.text = "Statut : \nInconnu"
            self.seeMoreButton.isEnabled = false
            self.paymentButton.isHidden = true
            self.paymentButton.isUserInteractionEnabled = false
        }
    }
    
    func loadCommerceInformations(){
        if let comm = savedCommerce {
            
            nomCommerce         = comm.nom
            telCommerce         = comm.tel
            mailCommerce        = comm.mail
            adresseCommerce     = comm.adresse
            siteWebCommerce     = comm.siteWeb
            categorieCommerce   = comm.type
            descriptionCommerce = comm.descriptionO
            promotionsCommerce  = comm.promotions
            
            if loadedFromBAAS {
                // Charger les différentes images associés
                let queryPhotos = PFQuery(className: "Commerce_Photos")
                queryPhotos.whereKey("commerce", equalTo: comm.pfObject!)
                queryPhotos.addDescendingOrder("createdAt")
                
                queryPhotos.findObjectsInBackground { (objects, error) in
                    
                    if let error = error {
                        self.refreshUI(status: .error, error: error, feedBack: true)
                    } else {
                        // Success
                        
                        if let photosBDD = objects {
                            self.photoArray = [#imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon")]
                            for (index, obj) in photosBDD.enumerated() {
                                self.loadedPhotos.append(obj) // Tous les images (afin de les supprimer avant l'update)
                                // 3 première images
                                if index < 3 {
                                    let fileImage       = obj["photo"] as! PFFileObject
                                    if let imageData    = try? fileImage.getData(){
                                        self.photoArray.remove(at: index)
                                        self.photoArray.insert(UIImage(data: imageData) ?? UIImage(named: "Plus_icon")!, at: index)
                                    }
                                }
                            }
                            
                        }
                    }
                
                    self.refreshUI()
                }
            }
            
        }
    }
    
    func refreshUI(status: UploadingStatus = .none, error: Error? = nil, feedBack: Bool = false){
        // Paiement
        self.refreshUIPaymentStatus()
        
        switch status {
        case .success:
            SVProgressHUD.showSuccess(withStatus: nil)
        case .error:
            SVProgressHUD.showError(withStatus: "Erreur de chargement du commerce")
        case .none:
            SVProgressHUD.dismiss(withDelay: 1.5)
        }
        
        if let error = error {
            ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: feedBack)
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
        }
    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Sauvegarder les infos pour editions plus tard
        if !didUseFinalSave{
            localSave()
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if editingMode {self.navigationController?.popViewController(animated: true)}
        else {self.navigationController?.dismiss(animated: true)}
    }
    
    @IBAction func saveInformations(_ sender: Any){
        if !isSaving { // isSaving = false
            self.saveButton.isEnabled = false
            
            SVProgressHUD.show(withStatus: "Sauvegarde en cours")
            self.finalSave()
        }
    }
    
    func localSave(){
        // Sauvegarde des infos dans le tel
//        print("Local save")
//        let localCommerce = getCommerceFromInfos()
//        print(localCommerce.description)
        
        //        let userDefaults = UserDefaults.standard
        //        userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: localCommerce), forKey: "lastCommerce")
        //        userDefaults.synchronize()
        
        // TO GET
        //        if let data = userDefaults.object(forKey: "lastCommerce") as? NSData {
        //            let comm = NSKeyedUnarchiver.unarchiveObject(with: data as Data)
        //        }
    }
    
    func finalSave() {
        
        didUseFinalSave = true
        isSaving = true
        
        // [1] Sauvegarde du commerce
        let fetchComm = Commerce(withName: nomCommerce, tel: telCommerce, mail: mailCommerce, adresse: adresseCommerce, siteWeb: siteWebCommerce, categorie: categorieCommerce, description: descriptionCommerce, promotions: promotionsCommerce, owner:PFUser.current()!) // Comerce Object
        let commerceToSave = fetchComm.getPFObject(objectId: self.objectIdCommerce, fromBaas: self.loadedFromBAAS) // PFObject
        commerceToSave.saveInBackground { (success, error) in
            if let error = error {
                self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
            } else {
                self.updateGeoLocation(commerce: fetchComm)
                // [2] Sauvegarde des photos
                self.savePhotosWithCommerce(commerceId: self.objectIdCommerce)
            }
        }

        // [3] Sauvegarde des videos
//        self.saveVideosWithCommerce(commerceId: self.objectIdCommerce)
//        videos = self.saveVideosWithCommerce(commerceId: self.objectIdCommerce)
        
//        // [4] Mise a jour du commerce avec les photos & videos uploadés
//        self.refreshCommerceMedia(commerceId: self.objectIdCommerce)
    }
    
    func updateGeoLocation(commerce: Commerce){
        // Update location from adresse
        geocoder.geocodeAddressString(commerce.adresse) { (placemarks, error) in
            
            if let error = error {
                print("GeocodeAdress error = \(error.localizedDescription)")
            } else {
                if let placemarks = placemarks, placemarks.count > 0 {
                    if let location = placemarks.first?.location {
                        //                        print("location : \(location.debugDescription)")
                        if self.loadedFromBAAS {
                            let commerceToSave = commerce.pfObject
                            commerceToSave!["location"] = PFGeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            commerceToSave!.saveInBackground()
                        } else {
                            let comm = Commerce(withName: self.nomCommerce, tel: self.telCommerce, mail: self.mailCommerce, adresse: self.adresseCommerce, siteWeb: self.siteWebCommerce, categorie: self.categorieCommerce, description: self.descriptionCommerce, promotions: self.promotionsCommerce, owner:PFUser.current()!)
                            comm.location = PFGeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                        }
                    }
                }
            }
        }
    }
    
    func saveVideosWithCommerce(commerceId : String) {
        
        SVProgressHUD.show(withStatus: "Sauvegarde de la vidéo en cours")
        
        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerceId)

        // Une video a été ajouté par l'utilisateur
        if self.videoArray.count != 0 {
            // Parcours de toutes les vidéos ajoutés
            for i in 0..<self.videoArray.count {
                
                let video = self.videoArray[i]
                
                // Si on réussit a prendre les data de la vidéo
                // Dans ce cas on sauvegarde
                if let asset = video.phAsset {
                    
                    let options = PHVideoRequestOptions()
                    options.version = .original
                    options.deliveryMode = .automatic
                    options.isNetworkAccessAllowed = true
                    
                    video.exportVideoFile(options: options, progressBlock: { (progress) in
                        print("Progress \(progress)")
                    }) { (url, unknown) in
                        
                        print("Video export \(url) & \(unknown)")
                        
                        print("try")
                        var videoData: Data?
                        do {
                            videoData = try Data(contentsOf: url)
                        } catch {
                            print("exception catch at block - while uploading video")
                            videoData = nil
                            return
                        }
                        
                        print("Done getting video data\n Now tries to save pffile object")
                        
                        let pffile          = PFFileObject(data: videoData!, contentType: "video/mp4")  // video/mov ??
                        let obj             = PFObject(className: "Commerce_Videos")
                        let thumbnail       = PFFileObject(name: "thumbnail.jpg", data: self.thumbnailArray[i].jpegData(compressionQuality: 0.5)!)
                        
                        obj["thumbnail"]    = thumbnail
                        obj["leCommerce"]   = commerceToSave
                        obj["time"]         = asset.duration.stringFormatted()
                        obj["nameVideo"]    = self.nomCommerce + "__video-presentation-\(i)"
                        obj["video"]        = pffile
                        
                        
                        pffile.saveInBackground({ (success, error) in
                            if let error = error {
                                print("Erreur while uploading \(error.localizedDescription)")
                            } else {
                                // Pas d'erreur
                                if success {
                                    // OK
                                    print("Upload réussi")
//                                    obj.saveInBackground()
                                } else {
                                    print("Upload failed")
                                }
                            }
                        }, progressBlock: { (progress32) in
                            print("Progress : \(progress32)%")
                        })
                            
                        
                    }
                    
//                    DispatchQueue.main.async {
//                        PHImageManager().requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset, mix, nil) in
//
//
//                            let myAsset = asset as? AVURLAsset
//                            print("try")
//
//                            do {
//                                let videoData = try Data(contentsOf: (myAsset?.url)!)
//                                let pffile = PFFileObject(data: videoData, contentType: "video/mp4")
//
//                                let obj = PFObject(className: "Commerce_Videos")
//                                let thumbnail = PFFileObject(name: "thumbnail.jpg", data: self.thumbnailArray[i].jpegData(compressionQuality: 0.5)!)
//
//                                obj["thumbnail"]  = thumbnail
//                                obj["leCommerce"] = commerceToSave
//                                obj["nameVideo"]  = self.nomCommerce + "__video-presentation-\(i)"
//                                obj["video"] = pffile
//
//
//                                pffile.saveInBackground({ (success, error) in
//                                    if let error = error {
//                                        print("Erreur while uploading \(error.localizedDescription)")
//                                    } else {
//                                        // Pas d'erreur
//                                        if success {
//                                            // OK
//                                            print("Upload réussi")
////                                            obj.saveInBackground()
//                                        } else {
//                                            print("Upload failed")
//                                        }
//                                    }
//                                }, progressBlock: { (progress32) in
//                                    print("Progress : \(progress32)%")
//                                })
//
//                            } catch  {
//                                print("exception catch at block - while uploading video")
//                            }
//
//                        })
//                    }
                    
                    
                }
            }
        }
        
    }
    
    func savePhotosWithCommerce(commerceId : String) {
        SVProgressHUD.show(withStatus: "Sauvegarde des photos en cours")
        
        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerceId)
        var photos = [PFObject]()
        
        for image in self.photoArray {
            if image != #imageLiteral(resourceName: "Plus_icon") {
                let obj = PFObject(className: "Commerce_Photos")
                let compressedImage = image.wxCompress()
                let file: PFFileObject!
                do {
                    file = try PFFileObject(name: "photo.jpg", data: compressedImage.jpegData(compressionQuality: 0.6)!, contentType: "image/jpeg")
                } catch {
                    print("Error while setting content type jpeg")
                    file = PFFileObject(name: "photo.jpg", data: compressedImage.jpegData(compressionQuality: 0.6)!)
                }
                
                obj["photo"] = file
                obj["commerce"] = commerceToSave
                photos.append(obj)
            }
        }
        
        if loadedFromBAAS {
            PFObject.deleteAll(inBackground: self.loadedPhotos) { (success, error) in
                if let error = error {
                    print("Save Photo func - Delete error")
                    self.saveOfCommerceEnded(status: .error, error: error, feedBack: false)
                } else {
                    if photos.count != 0 {
                        PFObject.saveAll(inBackground: photos, block: { (success, error) in
                            if let error = error {
                                print("Save Photo func - Delete error")
                                self.saveOfCommerceEnded(status: .error, error: error, feedBack: false)
                            } else {
                                self.photos = photos
                                
                                // [4] Mise a jour du commerce avec les photos & videos uploadés
                                self.refreshCommerceMedia(commerceId: self.objectIdCommerce)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func refreshCommerceMedia(commerceId:String){
        
        SVProgressHUD.show(withStatus: "Mise à jour du commerce avec les photos")
        
        if photos.count != 0 {
            let query = PFQuery(className: "Commerce")
            query.whereKey("objectId", equalTo: commerceId)
            query.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])
            var commerceToSave : PFObject
            
            do {
                try commerceToSave = query.getFirstObject()
                
                commerceToSave["photoSlider"] = photos
                commerceToSave["thumbnailPrincipal"] = photos[0]
                commerceToSave["videos"] = []
//                commerceToSave["video"] = video
                commerceToSave.saveInBackground { (success, error) in
                    if let error =  error {
                        print("Commerce refresh with media")
                        self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
                    } else {
                        if success {
                            self.saveOfCommerceEnded(status: .success)
                            
                        } else {
                            self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
                        }
                    }
                    
                }
                
            } catch  {
                print("RefreshCommerceMedia func")
                self.saveOfCommerceEnded(status: .error, error: error)
            }
        }
    }
    
    func saveOfCommerceEnded(status: UploadingStatus = .none, error: Error? = nil, feedBack: Bool = false){
        isSaving = false
        
        switch status {
        case .success:
            SVProgressHUD.showSuccess(withStatus: "Commerce sauvegardé avec succès")
        case .error:
            SVProgressHUD.showError(withStatus: "Erreur dans la sauvegarde du commerce")
        case .none:
            SVProgressHUD.dismiss(withDelay: 1.5)
        }
        
        if let error = error {
            ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: feedBack)
        }
        
        self.saveButton.isEnabled = true
    }
    
}

// Status View Functions
extension AjoutCommerceVC {
    @IBAction func seeMoreDetailAboutStatus(_ sender: Any) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "renewOfCommerce" {
            let paymentVC = segue.destination as! PaymentVC
            paymentVC.renewingCommerceId = objectIdCommerce
            paymentVC.commerceAlreadyExists = true
        }
    }
}

extension AjoutCommerceVC: TLPhotosPickerViewControllerDelegate {
    func showSelection(forPhoto : Bool) {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        var configure = TLPhotosPickerConfigure()
        configure.cancelTitle = "Annuler"
        configure.doneTitle = "Terminer"
        configure.defaultCameraRollTitle = forPhoto ? "Choisir une photo" : "Choisir une vidéo"
        configure.tapHereToChange = "Tapper ici pour changer"
        configure.allowedLivePhotos = false
        
        if forPhoto {
            // Configuration photo
            configure.mediaType = .image
            configure.allowedVideo = false
            configure.usedCameraButton = false
            configure.maxSelectedAssets = 1
        } else {
            // Configuration video
            configure.allowedVideo = true
            configure.allowedVideoRecording = false
            configure.mediaType = .video
            configure.maxVideoDuration = TimeInterval(20) // 20 secondes
            configure.maxSelectedAssets = 1
        }
        
        configure.autoPlay = false
        viewController.configure = configure
        self.present(viewController, animated: true)
    }
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        if withTLPHAssets.count != 0 {
            let asset = withTLPHAssets[0]
            if asset.type == .photo || asset.type == .livePhoto {
                if let image = asset.fullResolutionImage {
                    self.refreshCollectionWithDataForPhoto(data: image.jpegData(compressionQuality: 1) ?? #imageLiteral(resourceName: "Plus_icon").jpegData(compressionQuality: 0.5)!)
                } else {
                    SVProgressHUD.showProgress( 0, status: "Chargement")
                    self.getImage(phasset: asset.phAsset)
                }
                
                for photo in self.photoArray {
                    print(photo)
                }
                print("\n\n")
            }
            else {
                // Videos
                if let thumb = asset.fullResolutionImage {
                    self.refreshCollectionWithDataForVideo(thumbnail: thumb)
                } else {
                    SVProgressHUD.showProgress( 0, status: "Chargement")
                    self.getVideoThumbnail(phasset: asset.phAsset)
                }
                // Store assets so we can load data later to upload on servers
                self.videoArray = withTLPHAssets
            }
        } else {
            print("Aucun objet retourné")
        }
        
    }
    
    func refreshCollectionWithDataForPhoto(data : Data){
        DispatchQueue.main.async {
            self.photoArray.remove(at: self.selectedRow)
            self.photoArray.insert(UIImage(data: data)!, at: self.selectedRow)
            self.refreshUI()
        }
    }
    
    func refreshCollectionWithDataForVideo(thumbnail : UIImage){
        DispatchQueue.main.async {
            self.thumbnailArray.remove(at: self.videoSelectedRow)
            self.thumbnailArray.insert(thumbnail, at: self.videoSelectedRow)
            self.refreshUI()
        }
    }
    
    func getImage(phasset: PHAsset?){
        guard let asset = phasset else {
            return
        }
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.version = .current
        options.resizeMode = .exact
        options.progressHandler = { (progress: Double, error, stop, info) in
            SVProgressHUD.showProgress(Float(progress), status: "Chargement de la photo")
        }
        _ = PHCachingImageManager().requestImageData(for: asset, options: options) { (imageData, dataUTI, orientation, info) in
            if let data = imageData,let _ = info {
                
                self.refreshCollectionWithDataForPhoto(data: data)
            }
        }
    }
    
    func getVideoThumbnail(phasset: PHAsset?){
        guard let asset = phasset else {
            return
        }
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.deliveryMode = .fastFormat
        videoRequestOptions.version = .original
        videoRequestOptions.isNetworkAccessAllowed = true
        videoRequestOptions.progressHandler = { (progress, error, stop, info) in
            SVProgressHUD.showProgress(Float(progress), status: "Chargement de la vidéo")
        }
        
        _ = PHImageManager().requestAVAsset(forVideo: asset, options: videoRequestOptions, resultHandler: { (avaAsset, audioMix, info) in
            if let successAvaAsset = avaAsset {
                let generator = AVAssetImageGenerator(asset: successAvaAsset)
                generator.appliesPreferredTrackTransform = true
                
                let myAsset = successAvaAsset as? AVURLAsset
                do {
                    let videoData = try Data(contentsOf: (myAsset?.url)!)
                    self.selectedVideoData = videoData  //Set video data to nil in case of video
                }
                catch let error as NSError
                {
                    self.handleLoadingExceptions(forPhoto: false, withError: error)
                }
                
                do {
                    let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
                    let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                    let thumbnail = UIImage(cgImage: imageRef)
                    self.refreshCollectionWithDataForVideo(thumbnail: thumbnail)
                }
                catch let error as NSError
                {
                    self.handleLoadingExceptions(forPhoto: true, withError: error)
                }
            }
        })
    }
}

// UITableVC Delegates & Datasource methods
extension AjoutCommerceVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if section == 4 {return 4}
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {return 7}
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: // Case Nom du commerce
            return 50
        case 1: // Case photos
            return (tableView.bounds.width - (3 - 1) * 7) / 3
        case 2: // Case vidéo
            return 0 // 150
        case 3: // Case selection de la catégorie
            return 150
        case 4: // Case informations supplémentaires
            return 50 // Taille d'une cellule = 50 * nombre de champs d'informations = 4
        default:
            return 100
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 { return 0 } // Video
        return 30
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Nom du commerce"
        case 1:
            return "Photos du commerce"
        case 2:
            return "Vidéo de présentation (optionnel)"
        case 3:
            return "Catégorie du commerce"
        case 4:
            return "Informations du commerce"
        case 5:
            return "Description de votre commerce"
        case 6:
            return "Mes promotions"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? AjoutPhotoTVC else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            self.videoSelectedRow = indexPath.row
            self.showSelection(forPhoto: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "singleInformationCell", for: indexPath) as! NouveauCommerceCell
            cell.setTextFieldViewDataDelegate(delegate: self, tag: 100, placeHolder: "Nom de votre établissement")
            cell.contentTF.text = self.nomCommerce
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCollectionView", for: indexPath) as! AjoutPhotoTVC
            cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! VideoCell
            cell.videoPreview.image = self.thumbnailArray[self.videoSelectedRow]
            return cell
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categorieCell", for: indexPath) as! SelectionCategorieTVCell
            cell.setPickerViewDataSourceDelegate(dataSourceDelegate: self)
            if self.categorieCommerce != "" {
                let listCat = HelperAndKeys.getListOfCategories()
                let index_Int = listCat.firstIndex(of: self.categorieCommerce)
                if index_Int != nil {
                    cell.categoriePickerView.selectRow(index_Int!, inComponent: 0, animated: false)
                }
            }
            return cell
        } else if indexPath.section == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "informationsCommerceCell", for: indexPath) as! NouveauCommerceCell
            var place = ""
            switch indexPath.row {
            case 0:
                place = "Numéro de téléphone"
                cell.contentTF.keyboardType = .phonePad
                cell.contentTF.text = self.telCommerce
                break
            case 1:
                place = "Mail de contact"
                cell.contentTF.keyboardType = .emailAddress
                cell.contentTF.text = self.mailCommerce
                break
            case 2:
                place = "Adresse du commerce"
                cell.contentTF.text = self.adresseCommerce
                break
            case 3:
                place = "Site internet"
                cell.contentTF.keyboardType = .URL
                cell.contentTF.text = self.siteWebCommerce
                break
            default:
                break
            }
            cell.setTextFieldViewDataDelegate(delegate: self, tag: (indexPath.row + 2) * 100, placeHolder: place)
            return cell
        } else if indexPath.section == 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath) as! DescriptionAndPromotionsTVCell
            cell.setTextViewDataSourceDelegate(dataSourceDelegate: self, withTag: 100)
            cell.textViewDescAndPromotions.text = self.descriptionCommerce
            return cell
        } else if indexPath.section == 6 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "promotionsCell", for: indexPath) as! DescriptionAndPromotionsTVCell
            cell.setTextViewDataSourceDelegate(dataSourceDelegate: self, withTag: 200)
            cell.textViewDescAndPromotions.text = self.promotionsCommerce
            return cell
        }
        else {
            // Default value never used
            return UITableViewCell()
        }
    }
}

// Other functions
extension AjoutCommerceVC {
    func handleLoadingExceptions(forPhoto : Bool, withError : NSError){
        if forPhoto {
            print("Image generation failed with error \(withError.localizedDescription)")
        } else {
            print("exception catch while uploading video with error \(withError.localizedDescription)")
        }
    }
}

extension AjoutCommerceVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        let imagev = cell.viewWithTag(21) as! UIImageView
        imagev.image = self.photoArray[indexPath.row]
        
        let background = cell.viewWithTag(999)!
        background.setCardView(view: background)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedRow = indexPath.row
        self.showSelection(forPhoto: true)
    }
}

extension AjoutCommerceVC: UIPickerViewDelegate, UIPickerViewDataSource{
    func photoPickerDidCancel() {
        // Phrase a afficher quand il annule l'ajout de photos ou vidéos
        // Un commerce possédant des photos et une vidéo obtient plus de visites
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {return 1}
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {return HelperAndKeys.getListOfCategories().count}
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {return HelperAndKeys.getListOfCategories()[row]}
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {self.categorieCommerce = HelperAndKeys.getListOfCategories()[row]}
}

extension AjoutCommerceVC: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        /*
         tags : textfield
         100 = nom du commerce
         200 = numero du commerce
         300 = mail de contact du commerce
         400 = adresse du commerce
         500 = site internet
         */
        switch textField.tag {
        case 100:
            nomCommerce = textField.text ?? ""
            break
        case 200:
            telCommerce = textField.text ?? ""
            break
        case 300:
            mailCommerce = textField.text ?? ""
            break
        case 400:
            adresseCommerce = textField.text ?? ""
            break
        case 500:
            siteWebCommerce = textField.text ?? ""
            break
        default:
            break
        }
        print("Textfield tag : \(textField.tag) and his text \(textField.text ?? "Aucun text")")
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        switch textView.tag {
        case 100:
            descriptionCommerce = textView.text
            break
        case 200:
            promotionsCommerce = textView.text
        default:
            break
        }
        print("Textview with text : \(String(describing: textView.text)) and tag : \(textView.tag)")
    }
}
