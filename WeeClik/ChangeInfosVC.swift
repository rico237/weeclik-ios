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
    var fromCloud = false               // ???
    var userProfilePicURL = ""          // Image de profil de l'utilisateur (uniquement facebook pour le moment)
    var didSelectNewPhoto = false       // Indicateur de séléction d'une nouvelle photo

    @IBOutlet weak var imageProfilContainerView: UIView!
    @IBOutlet var profilPictureImageView: UIImageView!
    @IBOutlet weak var nomPrenomTF: FormTextField!
    @IBOutlet weak var mailTF: FormTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        SVProgressHUD.setHapticsEnabled(true)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(1.5)

        self.profilPictureImageView.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveProfilInformations))
        mailTF.isEnabled = false
        mailTF.isUserInteractionEnabled = false
    }

    func updateProfilPic(forUser user: PFUser) {
        guard profilPictureImageView != nil else {return}
        // Regarde si une image de profil a été chargé
        // sinon si une image est lié via facebook
        // Sinon on affiche l'image de base weeclik

        if !didSelectNewPhoto {
            // Load photo from cloud
            if let profilFile = user["profilPicFile"] as? PFFileObject, let url = profilFile.url, url != "" {
                self.userProfilePicURL = url
            } else if let profilPicURL = user["profilePictureURL"] as? String, profilPicURL != "" {
                self.userProfilePicURL = profilPicURL
            }
            if self.userProfilePicURL != "" {
                let placeholderImage = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
                self.profilPictureImageView.sd_setImage(with: URL(string: self.userProfilePicURL), placeholderImage: placeholderImage, options: .progressiveDownload, completed: nil)
            } else {
                self.profilPictureImageView.image = isPro ? #imageLiteral(resourceName: "Logo_commerce") : #imageLiteral(resourceName: "Logo_utilisateur")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let user = PFUser.current() else { return }
        currentUser = user
        nomPrenomTF.text = user["name"] as? String
        mailTF.text = user.email!
        updateViewFrame()
        updateProfilPic(forUser: user)
    }

    func updateViewFrame() {
        guard profilPictureImageView != nil else { return }
        imageProfilContainerView.layer.borderColor = isPro ? UIColor(red: 0.86, green: 0.33, blue: 0.34, alpha: 1.00).cgColor : UIColor(red: 0.11, green: 0.69, blue: 0.96, alpha: 1.00).cgColor
        imageProfilContainerView.clipsToBounds = true
        imageProfilContainerView.layer.cornerRadius = self.imageProfilContainerView.frame.size.width / 2
        imageProfilContainerView.layer.masksToBounds = true
        imageProfilContainerView.layer.borderWidth = userProfilePicURL != "" ? 3 : 3
    }

    @objc func saveProfilInformations() {
        guard let user = currentUser else { return }
        user["name"] = nomPrenomTF.text
        //        TODO: Pouvoir véritablement changer l'adresse email de l'utilisateur
        //        currentUser?.email = mailTF.text

        if !fromCloud { selectedData = profilPictureImageView.image!.jpegData(compressionQuality: 0.7)! }

        let profilPic = PFFileObject(name: "image_de_profil-"+(currentUser?.objectId)!, data: selectedData)
        user["profilPicFile"] = profilPic
        profilPic?.saveInBackground({ (success, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: false)
                SVProgressHUD.showError(withStatus: "Erreur dans la modification de votre profil".localized())
            } else if success {
                user.saveInBackground()
                SVProgressHUD.showSuccess(withStatus: "Informations changés avec succès".localized())
                //self.navigationController?.popViewController(animated: true)
            }
        }, progressBlock: { (progress) in
            SVProgressHUD.showProgress(Float(progress)/100, status: "Envoi de votre photo".localized())
        })
    }

    @IBAction func changeProfilPic(_ sender: Any) {showSelection()}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mdpChange" {
            let vc = segue.destination as! MotDePasseVC
            vc.isPro = self.isPro
            didSelectNewPhoto = false
        }
    }
}

extension ChangeInfosVC: TLPhotosPickerViewControllerDelegate {
    func showSelection() {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        var configure = TLPhotosPickerConfigure()
        configure.cancelTitle = "Annuler".localized()
        configure.doneTitle = "Terminer".localized()
        configure.defaultCameraRollTitle = "Choisir une photo".localized()
        configure.tapHereToChange = "Tapper ici pour changer".localized()
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
        guard withTLPHAssets.count != 0 else { didSelectNewPhoto = false; return; }

        didSelectNewPhoto = true
        let asset = withTLPHAssets[0]
        if asset.type == .photo || asset.type == .livePhoto {
            if asset.fullResolutionImage == nil {
                fromCloud = true
                getImage(phasset: asset.phAsset)
            } else {
                fromCloud = false
                profilPictureImageView.image = asset.fullResolutionImage
            }
        }
    }

    func getImage(phasset: PHAsset?) {
        guard let asset = phasset else {return}
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.version = .current
        options.resizeMode = .exact
        options.progressHandler = { (progress, error, stop, info) in
            SVProgressHUD.showProgress(Float(progress), status: "Chargement".localized())
        }
        _ = PHCachingImageManager().requestImageData(for: asset, options: options) { (imageData, _, _, info) in
            if let data = imageData, let _ = info {
                self.selectedData = data
                self.profilPictureImageView.image = UIImage(data: data)
            }
        }
    }
}
