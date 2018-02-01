//
//  ChangeInfosVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 02/11/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

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
    
    @IBOutlet weak var nomPrenomTF: FormTextField!
    @IBOutlet weak var mailTF: FormTextField!
    @IBOutlet weak var profilPicture: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isPro = true // TODO: mettre une vrai condition
        self.profilPicture.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveProfilInformations))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentUser = PFUser.current()
        nomPrenomTF.text = currentUser?["name"] as? String
        mailTF.text = currentUser?.email!
    }
    
    @objc func saveProfilInformations(){
        currentUser!["name"] = nomPrenomTF.text
//        currentUser?.email = mailTF.text
        
        if fromCloud == false {
            selectedData = UIImageJPEGRepresentation(self.profilPicture.image!, 0.7)!
        }
        
        let profilPic = PFFile(name: "image_de_profil-"+(currentUser?.objectId)!, data: selectedData)
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
