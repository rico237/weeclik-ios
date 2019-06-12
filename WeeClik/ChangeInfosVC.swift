//
//  ChangeInfosVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 02/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO: faire des providers pour les données de l'user

import UIKit
import Photos
import SVProgressHUD
import TLPhotoPicker
import Parse

class ChangeInfosVC: UIViewController {
    var isPro = false
    var currentUser = PFUser.current()
    var selectedData = Data()
    var fromCloud = false
    var userProfilePicURL = ""          // Image de profil de l'utilisateur (uniquement facebook pour le moment)
    
    @IBOutlet weak var nomPrenomTF: FormTextField!
    @IBOutlet weak var mailTF: FormTextField!
    @IBOutlet weak var profilPicture: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profilPicture.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveProfilInformations))
        mailTF.isEnabled = false
        mailTF.isUserInteractionEnabled = false
    }
    
    func updateProfilPic(forUser user: PFUser){
        // Regarde si une image de profil a été chargé
        // sinon si une image est lié via facebook
        // Sinon on affiche l'image de base weeclik
        if let profilFile = user["profilPicFile"] as? PFFileObject {
            if let url = profilFile.url {
                if url != "" {
                    self.userProfilePicURL = url
                }
            }
        } else if let profilPicURL = user["profilePictureURL"] as? String {
            if profilPicURL != "" {
                self.userProfilePicURL = profilPicURL
            }
        }
        
        if self.profilPicture != nil {
            
            self.profilPicture.layer.borderColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00).cgColor
            self.profilPicture.clipsToBounds = true
            
            if self.userProfilePicURL != "" {
                let placeholderImage = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
                self.profilPicture.sd_setImage(with: URL(string: self.userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload , completed: nil)
                self.profilPicture.layer.cornerRadius = self.profilPicture.frame.size.width / 2
                self.profilPicture.layer.borderWidth = 3
                self.profilPicture.layer.masksToBounds = true
            } else {
                self.profilPicture.layer.cornerRadius = 0
                self.profilPicture.layer.borderWidth = 0
                self.profilPicture.layer.masksToBounds = false
                self.profilPicture.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentUser = PFUser.current()
        nomPrenomTF.text = currentUser?["name"] as? String
        mailTF.text = currentUser?.email!
        self.updateProfilPic(forUser: currentUser!)
    }
    
    @objc func saveProfilInformations(){
        currentUser!["name"] = nomPrenomTF.text
        //        TODO: Pouvoir véritablement changer l'adresse email de l'utilisateur
        //        currentUser?.email = mailTF.text
        
        if fromCloud == false {
            selectedData = self.profilPicture.image!.jpegData(compressionQuality: 0.7)!
        }
        
        let profilPic = PFFileObject(name: "image_de_profil-"+(currentUser?.objectId)!, data: selectedData)
        currentUser!["profilPicFile"] = profilPic
        currentUser?.saveInBackground()
        
        let alert = UIAlertController(title: "Modification enregistré", message: "Vos informations ont été changé avec succès", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: { (alert) in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    @IBAction func changeProfilPic(_ sender: Any) {
        self.showSelection()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mdpChange" {
            let vc = segue.destination as! MotDePasseVC
            vc.isPro = self.isPro
        }
    }
}

extension ChangeInfosVC : TLPhotosPickerViewControllerDelegate {
    func showSelection(){
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        var configure = TLPhotosPickerConfigure()
        configure.cancelTitle = "Annuler"
        configure.doneTitle = "Terminer"
        configure.defaultCameraRollTitle = "Choisir une photo"
        configure.tapHereToChange = "Tapper ici pour changer"
        configure.allowedLivePhotos = false
        configure.mediaType = .image
        configure.allowedVideo = false
        configure.usedCameraButton = false
        configure.maxSelectedAssets = 1
        configure.autoPlay = false
        viewController.configure = configure
        self.present(viewController, animated: true)
    }
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        if withTLPHAssets.count != 0 {
            let asset = withTLPHAssets[0]
            if asset.type == .photo || asset.type == .livePhoto {
                if asset.fullResolutionImage == nil {
                    fromCloud = true
                    self.getImage(phasset: asset.phAsset)
                } else {
                    fromCloud = false
                    self.profilPicture.image = asset.fullResolutionImage
                }
            }
        }
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
                SVProgressHUD.showProgress(Float(progress), status:"Chargement")
            }
            _ = PHCachingImageManager().requestImageData(for: asset, options: options) { (imageData, dataUTI, orientation, info) in
                if let data = imageData,let _ = info {
                    self.selectedData = data
                    self.profilPicture.image = UIImage(data: data)
                }
            }
        }
    }
}
