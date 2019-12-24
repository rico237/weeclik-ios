//
//  AjoutCommerceVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 04/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO: Ajouter reachability + demander si ils veulent uploader les images et videos en mode cellular
// TODO: Ajouter de véritable vérification sur le champs

// TODO: Migrer les fonctions de modification de commerce vers le service
// TODO: UTILISER DES COMPLETIONS
// TODO: AOUTER un bool si la position a été changé et update la localisation uniquement si changé
// TODO: Faire de meme avec les videos & photos, check si elle ont été modifié

import UIKit
import Parse
import TLPhotoPicker
import Photos
import AVKit
import SVProgressHUD
import WXImageCompress
import SwiftDate
import ZAlertView
import AppImageViewer
import DTTextField
import Validator

enum UploadingStatus {
    case success
    case error
    case location
    case none
}

class AjoutCommerceVC: UITableViewController {

    var photoArray : [UIImage]!     = [#imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon")]          // Tableau de photos
    var loadedPhotos                = [PFObject]()          // Toutes les images conservés en BDD par le commerce
    var loadedVideos                = [PFObject]()          // Toutes les vidéos conservés en BDD par le commerce
    var videoArray                  = [TLPHAsset]()         // Tableau de videos
    var thumbnailArray : [UIImage]  = [UIImage]()           // Tableau de preview des vidéos
    var selectedVideoData           = Data()                // Data de vidéos
    var savedCommerce : Commerce?                           // Objet Commerce si on a pas utilisé le bouton sauvegarde
    var isSaving = false                                    // Sauvegarde du commerce en cours

    // UI Changes
    var photosHaveChanged = false                           // Save photos only if they have changed
    var videosHaveChanged = false                           // Save videos only if they have changed

    @IBOutlet weak var cancelButton: UIBarButtonItem!       // Bouton annuler
    @IBOutlet weak var saveButton: UIBarButtonItem!         // Bouton Sauvegarder

    var objectIdCommerce    = ""
    var editingMode         = false                         // Mode edit d'un commerce
    var loadedFromBAAS      = false                         // Commerce venant de la BDD cloud
    var videoIsLocal        = false                         // Video loaded from local or BaaS

    var photos = [PFObject]()                               // Photos to be processed for saving
    var videos = [PFObject]()                               // Videos to pe processed for saving

    // Payment Status View Outlets
    @IBOutlet weak var statusDescription: UILabel!
    @IBOutlet weak var seeMoreButton: UIButton!
    @IBOutlet weak var paymentButton: UIButton!

    var isValidForm = false
    var isAdresseWriten = false

    // TextFields with input errors
    var nameTextField: DTTextField!
    var telTextField: DTTextField!
    var mailTextField: DTTextField!
    var adresseTextField: DTTextField!

    var textFields = [DTTextField]()

    let nameRule = ValidationRuleLength(min: 3, error: NomCommerceFormValidationError())
    let telRule  = IsPhoneNumberValidationRule()

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
    var selectedRow: Int      = 0
    var videoSelectedRow: Int = 0
}

extension AjoutCommerceVC {
    override func viewDidLoad() {
        super.viewDidLoad()

        SVProgressHUD.setHapticsEnabled(true)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(0.7)
        
        if editingMode {
            self.saveButton.title = "Modifier".localized()
            self.cancelButton.title = "Retour".localized()
            self.title = "MODIFIER COMMERCE".localized()
        } else {
            self.saveButton.title = "Enregistrer".localized()
            self.cancelButton.title = "Retour".localized()
            self.title = "NOUVEAU COMMERCE".localized()
        }

        tableView.tableHeaderView?.frame.size.height = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SVProgressHUD.show(withStatus: "Chargement du commerce".localized())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let comm = UserDefaults.standard.object(forKey: "lastCommerce") as? Commerce {
            self.loadedFromBAAS = false
            print("Commerce dans les userDefaults")
            savedCommerce = comm
        }

        if objectIdCommerce != "" {
            self.editingMode = true
            self.loadedFromBAAS = true

            savedCommerce = Commerce(objectId: objectIdCommerce)
        }
        
        self.loadCommerceInformations()
        
//        textFields = [nameTextField, telTextField, mailTextField, adresseTextField]
        textFields = [nameTextField]
        initFormInputs()
    }

    func refreshUIPaymentStatus() {
        tableView.tableHeaderView?.frame.size.height = 160
        
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
                self.statusDescription.text = "Statut : \n\(savedCommerce.statut.label())\nFin : \(endSub.convertTo(region: paris).toFormat("dd MMM yyyy 'à' HH:mm"))".localized()
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
                self.statusDescription.text = "Statut : \nInconnu".localized()
                self.seeMoreButton.isEnabled = false
                self.paymentButton.isHidden = true
                self.paymentButton.isUserInteractionEnabled = false
            }
        } else {
            // Nouveau commerce
            self.statusDescription.text = "Statut : \nInconnu".localized()
            self.seeMoreButton.isEnabled = false
            self.paymentButton.isHidden = true
            self.paymentButton.isUserInteractionEnabled = false
        }
    }

    func loadCommerceInformations() {
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
                                    if let imageData    = try? fileImage.getData() {
                                        self.photoArray.remove(at: index)
                                        self.photoArray.insert(UIImage(data: imageData) ?? UIImage(named: "Plus_icon")!, at: index)
                                    }
                                }
                            }

                        }
                    }

                    self.refreshUI()
                }

                // Charger les vidéos
                let queryVideos = PFQuery(className: "Commerce_Videos")
                queryVideos.whereKey("leCommerce", equalTo: comm.pfObject!)
                queryVideos.addDescendingOrder("createdAt")
                queryVideos.findObjectsInBackground { (objects, error) in
                    if let error = error {
                        self.refreshUI(status: .error, error: error, feedBack: true)
                    } else {
                        // Success getting videos
                        if let videoBDD = objects {
                            for (index, obj) in videoBDD.enumerated() {
                                self.loadedVideos.append(obj)
                                // 3 première images
                                if index < 1 {
                                    let fileImage       = obj["thumbnail"] as! PFFileObject
                                    if let imageData    = try? fileImage.getData() {
                                        self.thumbnailArray.removeAll()
                                        self.thumbnailArray.append(UIImage(data: imageData) ?? UIImage())
                                    }
                                }
                            }
                            self.videoIsLocal = false
                        }
                    }

                    self.refreshUI()
                }
            }

        }
    }

    func refreshUI(status: UploadingStatus = .none, error: Error? = nil, feedBack: Bool = false) {
        // Paiement
        self.refreshUIPaymentStatus()

        switch status {
        case .success:
            SVProgressHUD.showSuccess(withStatus: nil)
        case .error:
            SVProgressHUD.showError(withStatus: "Erreur de chargement du commerce".localized())
            if let error = error {ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: feedBack)}
        case .none, .location:
            SVProgressHUD.dismiss(withDelay: 0.7)
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @IBAction func cancelAction(_ sender: Any) {
        if editingMode { self.navigationController?.popViewController(animated: true) }
        else { self.navigationController?.dismiss(animated: true) }
    }

    @IBAction func saveInformations(_ sender: Any) {
        if !isSaving { // isSaving = false
            saveButton.isEnabled = false
            
            if isValidForm || (!nomCommerce.isEmptyStr && !adresseCommerce.isEmptyStr) {
                SVProgressHUD.show(withStatus: "Sauvegarde en cours".localized())
                finalSave()
            } else {
                showBasicToastMessage(withMessage:"Le nom de votre commerce et son adresse sont obligatoires".localized(), state: .error)
                saveButton.isEnabled = true
            }
        }
    }

    func finalSave() {
        isSaving = true

        // [1] Sauvegarde du commerce
        let fetchComm = Commerce(withName: nomCommerce, tel: telCommerce, mail: mailCommerce, adresse: adresseCommerce, siteWeb: siteWebCommerce, categorie: categorieCommerce, description: descriptionCommerce, promotions: promotionsCommerce, owner:PFUser.current()!) // Comerce Object
        fetchComm.objectId = objectIdCommerce
        fetchComm.brouillon = false
        
        fetchComm.getPFObject(objectId: objectIdCommerce, fromBaas: loadedFromBAAS) { (commerceObject, error) in
            guard let commerceToSave = commerceObject else {
                if let error = error {self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)}
                return
            }
            // Retrieved object
            commerceToSave.saveInBackground { (success, error) in
                if let error = error {
                    self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
                } else {
                    // Update général des informations du commerce
                    ParseService.shared.updateGeoLocation(forCommerce: fetchComm) { (success, error) in
                        if let error = error {
//                            self.saveOfCommerceEnded(status: .location, error: error, feedBack: true)
                            self.saveOfCommerceEnded(status: .none, error: error, feedBack: false)
//                            if (self.photosHaveChanged || self.videosHaveChanged) {
//                                self.loadCommerceInformations()
//                            }
                        }
                    }
                    ParseService.shared.updateExistingParseCommerce(fromCommerce: fetchComm) { (success, error) in
                        if success {
                            // [2] Sauvegarde des photos
                            if self.photosHaveChanged {
                                self.savePhotosWithCommerce(commerceId: self.objectIdCommerce)
                            } else if self.videosHaveChanged {
                                self.saveVideosWithCommerce(commerceId: self.objectIdCommerce)
                            } else {
                                self.saveOfCommerceEnded(status: .success)
                            }
                        } else if let error = error {
                            self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
                        }
                    }
                }
            }
        }
    }

    func saveVideosWithCommerce(commerceId : String) {
        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerceId)

        // Une video a été ajouté par l'utilisateur
        if !videoArray.isEmpty {
            ParseService.shared.deleteAllVideosForCommerce(commerce: commerceToSave) { (success, error) in
                if let error = error {
                    self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
                } else {
                    for (index, videoAsset) in self.videoArray.enumerated() {
                        // Si on réussit a prendre les data de la vidéo, on sauvegarde
                        if let asset = videoAsset.phAsset {

                            let options = PHVideoRequestOptions()
                            options.version = .current
                            options.deliveryMode = .fastFormat
                            options.isNetworkAccessAllowed = true

                            videoAsset.exportVideoFile(options: options, progressBlock: { (progress) in }) { (url, mimeType) in
                                print("Video export \(url) & \(mimeType)")
                                guard let videoData = try? Data(contentsOf: url) else {
                                    self.saveOfCommerceEnded(status: .error, error: nil, feedBack: true)
                                    return
                                }
                                
                                print("Done getting video data\nNow tries to save pffile object")

                                let pffile            = PFFileObject(data: videoData, contentType: mimeType)
                                let video             = PFObject(className: "Commerce_Videos")
                                let thumbnail         = PFFileObject(data: self.thumbnailArray[index].wxCompress().jpegData(compressionQuality: 1)!, contentType: "image/jpeg")

                                video["thumbnail"]    = thumbnail
                                video["leCommerce"]   = commerceToSave
                                video["time"]         = asset.duration.stringFormatted()
                                video["nameVideo"]    = self.nomCommerce + " - Vidéo de présentation"
                                video["video"]        = pffile

                                video.acl             = ParseHelper.getUserACL(forUser: PFUser.current())

                                pffile.saveInBackground({ (success, error) in
                                    if let error = error {
                                        print("Erreur while uploading \(error.localizedDescription)")
                                    } else if success {
                                        video.saveInBackground()
                                    }
                                }, progressBlock: { (progress32) in
                                    print("Video upload progress = \(progress32)")
                                })
                            }
                        }
                    }
                }
                // [4] Mise a jour du commerce avec les photos & videos uploadés
                self.refreshCommerceMedia(commerceId: self.objectIdCommerce)
            }
        } else {
            // Si cette variable est true = l'utilisateur a demandé à supprimer une video
            if videosHaveChanged {
                ParseService.shared.deleteAllVideosForCommerce(commerce: commerceToSave)
            }
            // Aucune video ajouté on passe direct au refresh du commerce
            // [4] Mise a jour du commerce avec les photos & videos uploadés
            self.refreshCommerceMedia(commerceId: self.objectIdCommerce)
        }
    }

    func savePhotosWithCommerce(commerceId : String) {
        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerceId)
        var photos = [PFObject]()

        for image in self.photoArray where image != #imageLiteral(resourceName: "Plus_icon") {
            let obj = PFObject(className: "Commerce_Photos")
            let compressedImage = image.wxCompress()
            let file: PFFileObject!
            do {
                file = try PFFileObject(name: "photo.jpg", data: compressedImage.jpegData(compressionQuality: 1)!, contentType: "image/jpeg")
            } catch {
                print("Error while setting content type jpeg \n\tError : \(error)")
                file = PFFileObject(name: "photo.jpg", data: compressedImage.jpegData(compressionQuality: 1)!)
            }
            obj["photo"] = file
            obj["commerce"] = commerceToSave
            photos.append(obj)
        }

        if loadedFromBAAS {
            PFObject.deleteAll(inBackground: self.loadedPhotos) { (success, error) in
                if let error = error {
                    print("Save Photo func - Delete error")
                    self.saveOfCommerceEnded(status: .error, error: error, feedBack: false)
                } else {
                    if !photos.isEmpty {
                        self.savePhotos(photos: photos)
                    }
                }
            }
        }
    }
    
    func savePhotos(photos: [PFObject]) {
//        PFObject.saveAll(inBackground: photos, block: { (_, error) in
//            if let error = error {
//                print("Save Photo func - Delete error")
//                self.saveOfCommerceEnded(status: .error, error: error, feedBack: false)
//            } else {
//                self.photos = photos
//                // [3]. Upload de la video
//                if self.videosHaveChanged {
//                    self.saveVideosWithCommerce(commerceId: self.objectIdCommerce)
//                } else {
//                    self.refreshCommerceMedia(commerceId: self.objectIdCommerce)
//                }
//            }
//        })
        
        // try recursive function
        for (index, photo) in photos.enumerated() {
            if index == photos.count - 1 {
                photo.saveInBackground { (_, error) in
                    if let error = error {
                        print("Save Photo func - Delete error")
                        self.saveOfCommerceEnded(status: .error, error: error, feedBack: false)
                    } else {
                        self.photos = photos
                        self.refreshCommerceMedia(commerceId: self.objectIdCommerce, inBackground: true)
                    }
                }
                // [3]. Upload de la video
                if self.videosHaveChanged {
                    self.saveVideosWithCommerce(commerceId: self.objectIdCommerce)
                } else {
                    self.refreshCommerceMedia(commerceId: self.objectIdCommerce)
                }
            } else {
                photo.saveInBackground { (_, error) in
                    if let error = error {
                        print("Save Photo func - Delete error")
                        self.saveOfCommerceEnded(status: .error, error: error, feedBack: false)
                    }
                }
            }
        }
    }

    func refreshCommerceMedia(commerceId: String, inBackground: Bool = false) {
        if !photos.isEmpty {
            let query = PFQuery(className: "Commerce")
            query.whereKey("objectId", equalTo: commerceId)
            query.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])
            
            query.getFirstObjectInBackground { (object, error) in
                
                if let commerceToSave = object, let thumbnail = self.photos.first {
                    commerceToSave["photoSlider"] = self.photos
                    commerceToSave["thumbnailPrincipal"] = thumbnail
                    //                commerceToSave["videos"] = []
                    //                commerceToSave["video"] = video
                    commerceToSave.saveInBackground { (success, error) in
                        if let error =  error {
                            print("Commerce refresh with media")
                            if !inBackground {
                                self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
                            }
                        } else {
                            if success {
                                if !inBackground {
                                    self.saveOfCommerceEnded(status: .success)
                                }
                            } else {
                                if !inBackground {
                                    self.saveOfCommerceEnded(status: .error, error: error, feedBack: true)
                                }
                            }
                        }

                    }
                } else if let error = error {
                    print("RefreshCommerceMedia func")
                    if !inBackground {
                        self.saveOfCommerceEnded(status: .error, error: error)
                    }
                }
            }
        } else {
            if !inBackground {
                self.saveOfCommerceEnded(status: .success)
            }
        }
    }

    func saveOfCommerceEnded(status: UploadingStatus = .none, error: Error? = nil, feedBack: Bool = false) {
        switch status {
        case .success:
            SVProgressHUD.dismiss()
            var message = "Commerce sauvegardé avec succès"
            
            if videosHaveChanged || photosHaveChanged {
                message = "Vos images et vidéos ont été enregistré. Ces mises à jour seront éffectives d\'ici 1 min"
            }
            
            let dialog =  ZAlertView(title: "", message: message.localized(), closeButtonText: "OK".localized(), closeButtonHandler: { (alert) in
                alert.dismissAlertView()
                self.navigationController?.popViewController(animated: true)
            })
            ZAlertView.positiveColor = .systemBlue
            dialog.show()
            
            videosHaveChanged = false
            photosHaveChanged = false
            
        case .error:
            SVProgressHUD.showError(withStatus: "Erreur dans la sauvegarde du commerce".localized())
        case .none:
            SVProgressHUD.dismiss(withDelay: 1.5)
        case .location:
            SVProgressHUD.showError(withStatus: "L'adresse saisie est incorrecte".localized())
        }

        if let error = error {ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: feedBack)}

        isSaving = false
        self.saveButton.isEnabled = true
    }
}

// Status View Functions
extension AjoutCommerceVC {
    @IBAction func seeMoreDetailAboutStatus(_ sender: Any) {
        if savedCommerce!.statut == .error || savedCommerce!.statut == .unknown || savedCommerce!.statut == .pending {
            let horsLigneMessage = "Votre commerce est toujours sur Weeclik mais invisible de tout le monde car il y a surement eu une erreur dans le paiement ou que lʼabonnement nʼest plus valable".localized()
            let dialog =  ZAlertView(title: "", message: horsLigneMessage, closeButtonText: "OK", closeButtonHandler: { (alert) in
                alert.dismissAlertView()
            })
            ZAlertView.positiveColor = .systemBlue
            dialog.show()
        } else if savedCommerce!.statut == .paid {
            let dialog =  ZAlertView(title: "", message: "Votre commerce est en ligne et visible de tous, prêt à être partagé".localized(), closeButtonText: "OK".localized(), closeButtonHandler: { (alert) in
                alert.dismissAlertView()
            })
            ZAlertView.positiveColor = .systemBlue
            dialog.show()
        }
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

    func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {

        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, _) in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, _, _) in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
    func showSelection(forPhoto : Bool) {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        
        var configure = TLPhotosPickerConfigure()
        configure.cancelTitle = "Annuler".localized()
        configure.doneTitle = "Terminer".localized()
        configure.defaultCameraRollTitle = forPhoto ? "Choisir une photo".localized() : "Choisir une vidéo".localized()
        configure.tapHereToChange = "Tapper ici pour changer".localized()
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
            configure.maxVideoDuration = TimeInterval(60) // 60 secondes
            configure.maxSelectedAssets = 1
        }

        configure.autoPlay = false
        viewController.configure = configure
        present(viewController, animated: true)
    }

    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        guard !withTLPHAssets.isEmpty, let asset = withTLPHAssets.first else {
            print("Aucun objet retourné")
            return
        }
        
        if asset.type == .photo || asset.type == .livePhoto {
            self.photosHaveChanged = true
            if let image = asset.fullResolutionImage {
                self.refreshCollectionWithDataForPhoto(data: image.wxCompress().jpegData(compressionQuality: 1) ?? #imageLiteral(resourceName: "Plus_icon").wxCompress().jpegData(compressionQuality: 1)!)
            } else {
                self.getImage(phasset: asset.phAsset)
            }
        } else {
            // Videos
            self.videosHaveChanged = true
            if let thumb = asset.fullResolutionImage {
                self.refreshCollectionWithDataForVideo(thumbnail: thumb.wxCompress())
            } else {
                self.getVideoThumbnail(phasset: asset.phAsset)
            }
            // Store assets so we can load data later to upload on servers
            self.videoArray = withTLPHAssets
            self.videoIsLocal = true
        }
    }

    func refreshCollectionWithDataForPhoto(data : Data) {
        DispatchQueue.main.async {
            self.photoArray.remove(at: self.selectedRow)
            self.photoArray.insert(UIImage(data: data)!, at: self.selectedRow)
            self.refreshUI()
        }
    }

    func refreshCollectionWithDataForVideo(thumbnail : UIImage) {
        DispatchQueue.main.async {
            if self.thumbnailArray.count != 0 {
                self.thumbnailArray.remove(at: self.videoSelectedRow)
            }
            self.thumbnailArray.insert(thumbnail, at: self.videoSelectedRow)
            self.refreshUI()
        }
    }

    func getImage(phasset: PHAsset?) {
        guard let asset = phasset else { return }
        asset.imageRepresentation { (image, data, error) in
            guard error != nil else { return }
            if let image = image, let imageData = image.jpegData(compressionQuality: 1) {
                self.refreshCollectionWithDataForPhoto(data: imageData)
            } else if let data = data {
                self.refreshCollectionWithDataForPhoto(data: data)
            }   
        }
//        let options = PHImageRequestOptions()
//        options.isSynchronous = false
//        options.isNetworkAccessAllowed = true
//        options.deliveryMode = .opportunistic
//        options.version = .current
//        options.resizeMode = .exact
//        options.progressHandler = { (progress, error, stop, info) in
//            SVProgressHUD.showProgress(Float(progress), status: "Chargement de la photo".localized())
//        }
//
//        PHCachingImageManager().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, _) in
//            if let image = image, let data = image.wxCompress().jpegData(compressionQuality: 1) {
//                self.refreshCollectionWithDataForPhoto(data: data)
//            }
//        }
    }

    func getVideoThumbnail(phasset: PHAsset?) {
        guard let asset = phasset else { return }
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.deliveryMode = .fastFormat
        videoRequestOptions.version = .original
        videoRequestOptions.isNetworkAccessAllowed = true
        videoRequestOptions.progressHandler = { (progress, error, stop, info) in
            print("Video thumbnail progress = \(progress)")
        }

        PHImageManager().requestAVAsset(forVideo: asset, options: videoRequestOptions, resultHandler: { (avaAsset, _, _) in
            if let successAvaAsset = avaAsset {
                let generator = AVAssetImageGenerator(asset: successAvaAsset)
                generator.appliesPreferredTrackTransform = true

                let myAsset = successAvaAsset as? AVURLAsset
                do {
                    let videoData = try Data(contentsOf: (myAsset?.url)!)
                    self.selectedVideoData = videoData  //Set video data to nil in case of video
                } catch let error as NSError {
                    self.handleLoadingExceptions(forPhoto: false, withError: error)
                }

                do {
                    let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
                    let imageRef  = try generator.copyCGImage(at: timestamp, actualTime: nil)
                    let thumbnail = UIImage(cgImage: imageRef).wxCompress()
                    self.refreshCollectionWithDataForVideo(thumbnail: thumbnail)
                } catch let error as NSError {
                    self.handleLoadingExceptions(forPhoto: true, withError: error)
                }
            }
        })
    }
}

// UITableVC Delegates & Datasource methods
extension AjoutCommerceVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 4 {return 4} // Section 4 = informations du commerce
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
            return 150
        case 3: // Case selection de la catégorie
            return 150
        case 4: // Case informations supplémentaires
            return 50 // Taille d'une cellule = 50 * nombre de champs d'informations = 4
        default:
            return 100
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {return 30}

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Nom du commerce (requis)".localized()
        case 1:
            return "Photos du commerce".localized()
        case 2:
            return "Vidéo de présentation".localized()
        case 3:
            return "Catégorie du commerce".localized()
        case 4:
            return "Informations du commerce (requis)".localized()
        case 5:
            return "Description de votre commerce".localized()
        case 6:
            return "Mes promotions".localized()
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
            if self.thumbnailArray.isEmpty {
                self.showSelection(forPhoto: false)
            } else {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let seeAction = UIAlertAction(title: "Voir la vidéo".localized(), style: .default) { (_) in
                    if self.videoIsLocal {
                        if let asset = self.videoArray[self.videoSelectedRow].phAsset {
                            self.getURL(ofPhotoWith: asset, completionHandler: { (url) in
                                if let url = url {
                                    self.showVideoPlayerWithVideoURL(withUrl: url)
                                } else {
                                    self.showAlertWithMessage(message: "Il y a eu une erreur lors du chargement de la video".localized(), title: "Erreur de chargement".localized(), completionAction: nil)
                                }
                            })
                        } else {
                            self.showAlertWithMessage(message: "Il y a eu une erreur lors du chargement de la video".localized(), title: "Erreur de chargement".localized(), completionAction: nil)
                        }
                    } else {
                        let video = self.loadedVideos[self.videoSelectedRow]["video"] as! PFFileObject
                        if let url = URL(string: video.url!) {
                            self.showVideoPlayerWithVideoURL(withUrl: url)
                        } else {
                            self.showAlertWithMessage(message: "Il y a eu une erreur lors du chargement de la video".localized(), title: "Erreur de chargement".localized(), completionAction: nil)
                        }
                    }

                }
                let modifyAction = UIAlertAction(title: "Changer de vidéo".localized(), style: .default) { (_) in self.showSelection(forPhoto: false)}
                let deleteAction = UIAlertAction(title: "Supprimer la vidéo".localized(), style: .destructive) { (_) in
                    self.thumbnailArray[indexPath.row] = UIImage()
                    self.videoArray = [] // FIXME: retravailler pour supprimer la vidéo à un index precis et pas rendre le tableau vide
                    self.selectedVideoData = Data()
                    self.videosHaveChanged = true
                    tableView.reloadData()
                }
                let cancelAction = UIAlertAction(title: "Annuler".localized(), style: .cancel) { (_) in alert.dismiss(animated: true)}

                alert.addAction(seeAction)
                alert.addAction(modifyAction)
                alert.addAction(deleteAction)
                alert.addAction(cancelAction)

                present(alert, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "singleInformationCell", for: indexPath) as! NouveauCommerceCell
            cell.setTextFieldViewDataDelegate(delegate: self, tag: 100, placeHolder: "Nom de votre établissement".localized())
            cell.contentTF.addTarget(self, action: #selector(AjoutCommerceVC.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
            cell.contentTF.text = self.nomCommerce
            nameTextField = cell.contentTF as? DTTextField
            nameTextField.floatingDisplayStatus = .never
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCollectionView", for: indexPath) as! AjoutPhotoTVC
            cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! VideoCell
            if thumbnailArray.isEmpty {
                cell.videoPreview.image = UIImage()
            } else {
                cell.videoPreview.image = thumbnailArray[indexPath.row]
            }
            return cell
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categorieCell", for: indexPath) as! SelectionCategorieTVCell
            cell.setPickerViewDataSourceDelegate(dataSourceDelegate: self)
            if !categorieCommerce.isEmptyStr {
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
                place = "Numéro de téléphone".localized()
                cell.contentTF.keyboardType = .phonePad
                cell.contentTF.text = self.telCommerce
            case 1:
                place = "Mail de contact".localized()
                cell.contentTF.keyboardType = .emailAddress
                cell.contentTF.text = self.mailCommerce
            case 2:
                place = "Adresse du commerce (Requis)".localized()
                cell.contentTF.keyboardType = .default
                cell.contentTF.text = self.adresseCommerce
            case 3:
                place = "Site internet".localized()
                cell.contentTF.keyboardType = .URL
                cell.contentTF.text = self.siteWebCommerce
            default:
                break
            }
            cell.setTextFieldViewDataDelegate(delegate: self, tag: (indexPath.row + 2) * 100, placeHolder: place)
            cell.contentTF.addTarget(self, action: #selector(AjoutCommerceVC.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
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
        } else {
            // Default value never used
            return UITableViewCell()
        }
    }
}

// Other functions
extension AjoutCommerceVC {
    func handleLoadingExceptions(forPhoto : Bool, withError : NSError) {
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

        if photoArray[indexPath.row] == #imageLiteral(resourceName: "Plus_icon") {
            showSelection(forPhoto: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            let seeAction = UIAlertAction(title: "Voir la photo".localized(), style: .default) { (_) in
                let appImage = ViewerImage.appImage(forImage: self.photoArray[indexPath.row])
                let viewer = AppImageViewer(originImage: self.photoArray[indexPath.row], photos: [appImage], animatedFromView: self.view)
                self.present(viewer, animated: true, completion: nil)
            }
            let modifyAction = UIAlertAction(title: "Changer de photo".localized(), style: .default) { (_) in self.showSelection(forPhoto: true)}
            let deleteAction = UIAlertAction(title: "Supprimer la photo".localized(), style: .destructive) { (_) in
                self.photoArray[indexPath.row] = #imageLiteral(resourceName: "Plus_icon")
                self.photosHaveChanged = true
                collectionView.reloadData()
            }
            let cancelAction = UIAlertAction(title: "Annuler".localized(), style: .cancel) { (_) in alert.dismiss(animated: true)}

            alert.addAction(seeAction)
            alert.addAction(modifyAction)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)

            present(alert, animated: true)
        }
    }
}

extension AjoutCommerceVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func photoPickerDidCancel() {
        // TODO: Phrase a afficher quand il annule l'ajout de photos ou vidéos
        // Un commerce possédant des photos et une vidéo obtient plus de visites
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {return 1}
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {return HelperAndKeys.getListOfCategories().count}
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {return HelperAndKeys.getListOfCategories()[row]}
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {self.categorieCommerce = HelperAndKeys.getListOfCategories()[row]}
}

extension AjoutCommerceVC: UITextFieldDelegate, UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        switch textView.tag {
        case 100:
            descriptionCommerce = textView.text
        case 200:
            promotionsCommerce  = textView.text
        default:
            break
        }
        //        print("Textview with text : \(String(describing: textView.text)) and tag : \(textView.tag)")
    }
    @objc func textFieldDidChange(_ textField: UITextField) {
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
            nomCommerce     = textField.text ?? ""
        case 200:
            telCommerce     = textField.text ?? ""
        case 300:
            mailCommerce    = textField.text ?? ""
        case 400:
            adresseCommerce = textField.text ?? ""
        case 500:
            siteWebCommerce = textField.text ?? ""
        default:
            break
        }
        saveButton.isEnabled = true
        isValidForm = checkFormValidity(textField)
//        saveButton.isEnabled = checkFormValidity(textField)
        //        print("Textfield tag : \(textField.tag) and his text \(textField.text ?? "Aucun text")")
    }
    func checkFormValidity(_ textField: UITextField) -> Bool {
        /*
         tags : textfield
         100 = nom du commerce
         200 = numero du commerce
         300 = mail de contact du commerce
         400 = adresse du commerce
         500 = site internet
         */

        if textField.tag == 100 {
            if nameTextField.text?.count ?? 0 <= 0 {
//                nameTextField.showError();
                return false
            }
//            else { nameTextField.hideError() }
        }

        if textField.tag == 200 {
//            if let _ = telTextField.text?.isValidPhone() { telTextField.showError(); return false }
//            else { telTextField.hideError() }
        }

        if textField.tag == 300 {
//            if let _ = mailTextField.text { mailTextField.showError(); return false }
//            else { mailTextField.hideError() }
        }

        if textField.tag == 400 {
//            if let _ = adresseTextField.text { adresseTextField.showError(); return false }
//            else { adresseTextField.hideError() }
            if let text = textField.text, text.count <= 6 {
                return false
            }
        }

        return true
    }
    func initFormInputs() {
        // Multiple config
        for field in textFields {
            if field.isKind(of: DTTextField.self) {
                field.floatingDisplayStatus = .never
                field.canShowBorder = false
            }
        }
        // Error messages
        nameTextField.errorMessage      = "Champs requis".localized()
//        telTextField.errorMessage       = "Numéro de téléphone invalide".localized()
//        mailTextField.errorMessage      = "Mail saisi incorrect".localized()
//        adresseTextField.errorMessage   = "Champs requis".localized()
    }
}
