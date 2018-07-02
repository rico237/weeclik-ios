//
//  AjoutCommerceVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 04/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import TLPhotoPicker
import Photos
import AVKit
import SVProgressHUD
import Async
import Crashlytics

class AjoutCommerceVC: UITableViewController {
    
    var photoArray : [UIImage]! = [#imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon")]      // Tableau de photos
    var videoArray = [TLPHAsset]()                  // Tableau de videos
    var thumbnailArray : [UIImage] = [UIImage()]    // Tableau de preview des vidéos
    var selectedVideoData = Data()                  // Data de vidéos
    var didUseFinalSave = false                     // Utilisé le bouton de sauvegarde
    var savedCommerce : Commerce? = nil             // Objet Commerce si on a pas utilisé le bouton sauvegarde
    var commerceIdToSave = ""                             // Id du commerce à sauvegarder
//    var pfCommerce : PFObject? = nil
    
    // Valeur des champs entrées
    // TextField
    var nomCommerce = "Halo"
    var telCommerce = "07"
    var mailCommerce = "@.fr"
    var adresseCommerce = "adresse"
    var siteWebCommerce = "http://"
    var categorieCommerce = "Restauration"
    // TextViews
    var descriptionCommerce = "Description"
    var promotionsCommerce = "promotions"
    
    // IndexPath pour les photos & videos
    var selectedRow : Int = 0
    var videoSelectedRow : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let use = UserDefaults.standard
        if let comm = use.object(forKey: "lastCommerce") as? Commerce {
            savedCommerce = comm
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadCommerceInformations()
        self.refreshUI()
    }
    
    func loadCommerceInformations(){
        if let comm = savedCommerce {
            nomCommerce = comm.nom
            telCommerce = comm.tel
            mailCommerce = comm.mail
            adresseCommerce = comm.adresse
            siteWebCommerce = comm.siteWeb
            categorieCommerce = comm.type
            descriptionCommerce = comm.descriptionO
            promotionsCommerce = comm.promotions
        }
    }
    
    func refreshUI(){
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Sauvegarder les infos pour editions plus tard
        if !didUseFinalSave{
            localSave()
        }
    }

    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func saveInformations(_ sender: Any){
        self.finalSave()
    }
    
    func localSave(){
        // Sauvegarde des infos dans le tel
        print("Local save")
        let localCommerce = getCommerceFromInfos()
        print(localCommerce.description)
        
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
        
        DispatchQueue.main.async {
            SVProgressHUD.show(withStatus: "Sauvegarde en cours")
        }
        
        var photos = [PFObject]()
        var videos = [PFObject]()
        
        // Sauvegarde du commerce
        commerceIdToSave =  self.saveCommerce()
        // Sauvegarde des photos
        photos = self.savePhotosWithCommerce(commerceId: commerceIdToSave)
        // Sauvegarde des videos
        videos = self.saveVideosWithCommerce(commerceId: commerceIdToSave)
        // Mise a jour du commerce avec les photos & videos uploadés
        self.refreshCommerceMedia(commerceId: commerceIdToSave, photos: photos, videos: videos)
    }
    
    func saveCommerce() -> String{
        // Sauvegarde finale pour paiement
        let commerceToSave = getCommerceFromInfos().getPFObject()
        
        do {
            try commerceToSave.save()
        } catch {
            print("Erreur : \(error)")
        }
        return commerceToSave.objectId!
    }
    
    func saveVideosWithCommerce(commerceId : String) -> [PFObject]{
        DispatchQueue.main.async {
            SVProgressHUD.show(withStatus: "Sauvegarde de la vidéo en cours")
        }
        
        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerceId)
        var videos = [PFObject]()
        let group = AsyncGroup()
        
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
                    print("1")
                    
                    group.userInitiated {
                        PHImageManager().requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset, mix, nil) in
                            let myAsset = asset as? AVURLAsset
                            print("try")
                            DispatchQueue.main.async {
                                do {
                                    let videoData = try Data(contentsOf: (myAsset?.url)!)
                                    
                                    
                                    let obj = PFObject(className: "Commerce_Videos")
                                    let thumbnail = PFFile(name: "thumbnail.jpg", data: UIImageJPEGRepresentation(self.thumbnailArray[i], 0.5)!)
                                    
                                    obj["thumbnail"] = thumbnail
                                    obj["leCommerce"]  = commerceToSave
                                    obj["nameVideo"] = self.nomCommerce + "___video-presentation-\(i)"
                                    obj["video"] = PFFile(name: "video.mp4", data: videoData)
                                    
                                    
                                    videos.append(obj)
                                    
                                    
                                    
                                } catch  {
                                    print("exception catch at block - while uploading video")
                                }
                            }
                        })
                    }
                    print("2")
                }
            }
            print("3")
            group.background {
                do{
                    print("Saving videos")
                    
                    try PFObject.saveAll(videos)
                    
                    print("4")
                    
                    print("Done")
                } catch {
                    print("Erreur : \(error)")
                }
            }
            print("5")
            group.wait()
            print("6")
        }
        
        return videos
    }
    
    func savePhotosWithCommerce(commerceId : String) -> [PFObject]{
        
        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerceId)
        var photos = [PFObject]()
        
        for image in self.photoArray {
            if image != #imageLiteral(resourceName: "Plus_icon") {
                let obj = PFObject(className: "Commerce_Photos")
                let file = PFFile(name: "photo.jpg", data: UIImageJPEGRepresentation(image, 0.7)!)
                
                obj["photo"] = file
                obj["commerce"] = commerceToSave
                photos.append(obj)
            }
        }
        
        if photos.count != 0 {
            DispatchQueue.main.async {
                SVProgressHUD.show(withStatus: "Sauvegarde des photos en cours")
            }
            
            do{
                
                print("Saving photos")
                try PFObject.saveAll(photos)
                print("Done")
                
            } catch {
                print("Erreur : \(error)")
            }
            
        }
        
        return photos
    }
    
    func refreshCommerceMedia(commerceId:String, photos: [PFObject], videos: [PFObject]){
        DispatchQueue.main.async {
            SVProgressHUD.show(withStatus: "Mise à jour du commerce avec les photos & vidéos")
        }
        
        if photos.count != 0 {
            let query = PFQuery(className: "Commerce")
            query.whereKey("objectId", equalTo: commerceId)
            var commerceToSave : PFObject
            do {
                try commerceToSave = query.findObjects()[0]
                
                commerceToSave["photoSlider"] = photos
                commerceToSave["thumbnailPrincipal"] = photos[0]
                try commerceToSave.save()
                
            } catch  {
                print(error.localizedDescription)
            }
        }
        
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
        }
    }
    
    func getCommerceFromInfos() -> Commerce{
        let comm = Commerce(withName: nomCommerce, tel: telCommerce, mail: mailCommerce, adresse: adresseCommerce, siteWeb: siteWebCommerce, categorie: categorieCommerce, description: descriptionCommerce, promotions: promotionsCommerce, owner:PFUser.current()!)
        comm.location = getLocationFromAddress(add: adresseCommerce)
        return comm
    }
    
    func getLocationFromAddress(add : String) -> PFGeoPoint{
        return PFGeoPoint(latitude: 0.0, longitude: 0.0)
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
                if asset.fullResolutionImage == nil {
                    DispatchQueue.main.async {
                        SVProgressHUD.showProgress(0, status: "Chargement")
                    }
                    self.getImage(phasset: asset.phAsset)
                } else {
                    self.photoArray[self.selectedRow] = asset.fullResolutionImage ?? #imageLiteral(resourceName: "Plus_icon")
                }
            }
            else {
                // Videos
                if asset.fullResolutionImage == nil {
                    DispatchQueue.main.async {
                        SVProgressHUD.showProgress(0, status: "Chargement")
                    }
                    self.getVideoThumbnail(phasset: asset.phAsset)
                } else {
                    self.thumbnailArray[self.videoSelectedRow] = asset.fullResolutionImage!
                }
                // Store assets so we can load data later to upload on servers
                self.videoArray = withTLPHAssets
            }
        }
    }
    
    func refreshCollectionWithDataForPhoto(data : Data){
        DispatchQueue.main.async {
            self.photoArray[self.selectedRow] = UIImage(data: data)!
        }
        self.refreshUI()
    }
    
    func refreshCollectionWithDataForVideo(thumbnail : UIImage){
        DispatchQueue.main.async {
            self.thumbnailArray[self.videoSelectedRow] = thumbnail
        }
        self.refreshUI()
    }
    
    func getImage(phasset: PHAsset?){
        if let asset = phasset {
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .opportunistic
            options.version = .current
            options.resizeMode = .exact
            options.progressHandler = { (progress,error,stop,info) in
                DispatchQueue.main.async {
                    SVProgressHUD.showProgress(Float(progress), status:"Chargement")
                }
            }
            _ = PHCachingImageManager().requestImageData(for: asset, options: options) { (imageData, dataUTI, orientation, info) in
                if let data = imageData,let _ = info {
                    self.refreshCollectionWithDataForPhoto(data: data)
                }
            }
        }
    }
    
    func getVideoThumbnail(phasset: PHAsset?){
        if let asset = phasset {
            let videoRequestOptions = PHVideoRequestOptions()
            videoRequestOptions.deliveryMode = .fastFormat
            videoRequestOptions.version = .original
            videoRequestOptions.isNetworkAccessAllowed = true
            videoRequestOptions.progressHandler = { (progress, error, stop, info) in
                DispatchQueue.main.async {
                    SVProgressHUD.showProgress(Float(progress), status:"Chargement")
                }
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
    
    func handleLoadingExceptions(forPhoto : Bool, withError : NSError){
        if forPhoto {
            print("Image generation failed with error \(withError.localizedDescription)")
        } else {
            print("exception catch while uploading video with error \(withError.localizedDescription)")
        }
    }
    
    func photoPickerDidCancel() {
        // Phrase a afficher quand il annule l'ajout de photos ou vidéos
        // Un commerce possédant des photos et une vidéo obtient plus de visites
    }
}

extension AjoutCommerceVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if section == 4 {return 4}
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
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
        } else if indexPath.section == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCollectionView", for: indexPath) as! AjoutPhotoTVC
            cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
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
                let index_Int = listCat.index(of: self.categorieCommerce)
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
        print("Textview with text : \(textView.text) and tag : \(textView.tag)")
    }
}
