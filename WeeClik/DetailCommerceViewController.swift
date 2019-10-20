//
//  DetailCommerceViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 30/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO: ouvrir le lien dans l'app et non le navigateur du tel (forcer l'user a rester dans l'application)
// TODO: mettre la description a 500 caractère max
// TODO: vv fonction de timer pour l'attente de partage qui appele a la fin cette fonction vv

import UIKit
import Contacts
import Foundation
import Parse
import MessageUI
import MapKit
import LGButton
import SDWebImage
import SwiftDate

class DetailCommerceViewController: UIViewController {

    @IBOutlet weak var shareButton: LGButton!

    var shrdString = [String]()
    var commerceObject : Commerce!
    var commerceID : String!

    var prefFiltreLocation: Bool!
    var hasGrantedLocation: Bool!

    var routeCommerceId : String!

    let userDefaults : UserDefaults = UserDefaults.standard

    let composeVC = MFMailComposeViewController()

    @IBOutlet weak var imageScroller: ImageScroller!
    @IBOutlet weak var pageIndicatorLabel: UILabel!

    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var websiteButton: UIButton!

    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var nomCommerceLabel: UILabel!
    @IBOutlet weak var categorieLabel: UILabel!
    @IBOutlet weak var headerPartagesLabel: UILabel!
    @IBOutlet weak var headerDistanceLabel: UILabel!

    @IBOutlet weak var distanceView: UIView!

    @IBOutlet weak var tableView: UITableView!

    var sampleImagesUrls = [String]()

    var promotionsH  : CGFloat = 0.0
    var descriptionH : CGFloat = 0.0

    @objc func updateAllViews() {
        // Mise a jour de notre variable globale pour l'ensemble de nos fonctions
        commerceID = self.commerceObject.objectId.description

        // Charger les photos dans le slider
        loadPhotosFromDB()
        loadSliderFromFetchedPhotos()
    }

    func updateCommerce() {
        var objId = commerceID
        if let routeId = routeCommerceId {
            objId = routeId
        }

        let query = PFQuery(className: "Commerce")
        query.whereKey("objectId", equalTo: objId!)
        query.includeKeys(["thumbnailPrincipal", "photosSlider", "videos"])

        query.getFirstObjectInBackground { (object, error) in
            if let obj = object {
                self.commerceObject = Commerce(parseObject: obj)
                self.tableView.reloadData()
            } else if let error  = error {
                ParseErrorCodeHandler.handleUnknownError(error: error)
            }
        }
    }

    func saveCommerceIdInUserDefaults() {
        // Met dans le UserDefaults + ajoute une notification au moment écoulé
        HelperAndKeys.setSharingTime(forCommerceId: commerceID)
        // Met à jour les données dans la BDD distante
        HelperAndKeys.saveStatsInDb(commerce: self.commerceObject.pfObject, user: PFUser.current())

        self.updateCommerce()
    }

    func loadSliderFromFetchedPhotos() {
        if sampleImagesUrls.count > 1 {
            // N images chargé depuis la BDD
            self.headerImage.isHidden = true
            imageScroller.setupScrollerWithImages(images: sampleImagesUrls)
        }
    }

    func loadPhotosFromDB() {
        let queryPhotos = PFQuery(className: "Commerce_Photos")
        queryPhotos.whereKey("commerce", equalTo: self.commerceObject.pfObject!)
        queryPhotos.order(byDescending: "updatedAt")
        queryPhotos.findObjectsInBackground { (objects, err) in

            if let err = err {
                HelperAndKeys.showAlertWithMessage(theMessage: err.localizedDescription, title: "Chargement des images".localized(), viewController: self)
            } else {

                if let objects = objects {
                    self.sampleImagesUrls = []
                    for obj in objects {
                        if let fileUrl = (obj["photo"] as? PFFileObject)?.url {
                            self.sampleImagesUrls.append(fileUrl)
                        }
                    }
                    self.loadSliderFromFetchedPhotos()
                }
            }
        }
    }

    @objc func shareCommerce() {

        if HelperAndKeys.canShareAgain(objectId: commerceID) {
            let str = "Salut, j’ai aimé \(self.commerceObject.nom), je te partage donc ce commerce situé à l’adresse : \n\(self.commerceObject.adresse) http://maps.google.com/maps?f=q&q=(\(self.commerceObject.location?.latitude ?? 0),\(self.commerceObject.location?.longitude ?? 0))".localized()

//            let str = "Voici les coordonées d'un super commerce que j'ai découvert : \n\n\(self.commerceObject.nom)\nTéléphone : \(self.commerceObject.tel)\nAdresse : \(self.commerceObject.adresse) \nURL : weeclik://\(self.commerceObject.objectId.description)"

            let customItem = ShareToGroupsActivity(title: "Partager à un groupe d'amis".localized()) { sharedItems in
                guard let shar = sharedItems as? [String] else {return}
                self.shrdString = shar
            }

            let activit = UIActivityViewController(activityItems: [str], applicationActivities: [customItem])
            activit.excludedActivityTypes = [
                .markupAsPDF, .postToVimeo, .postToWeibo, .postToFlickr, .postToTencentWeibo,
                .copyToPasteboard, .openInIBooks, .assignToContact, .addToReadingList,
                .saveToCameraRoll, .print
            ]
            activit.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems:[Any]?, error: Error?) in
                // Return if cancelled
                if (!completed) {return}

                // Extensions refusé comme partage valide
                let refused : [String] = [
                    "com.apple.mobilenotes.SharingExtension",
                    UIActivity.ActivityType.copyToPasteboard.rawValue
                ]
                // Extensions autorisées comme partage valide
                let autorized : [String] = [
                    UIActivity.ActivityType.mail.rawValue, UIActivity.ActivityType.message.rawValue,
                    UIActivity.ActivityType.postToTwitter.rawValue, UIActivity.ActivityType.postToFacebook.rawValue,
                    "net.whatsapp.WhatsApp.ShareExtension", "com.google.Gmail.ShareExtension", "com.ringosoftware.weeclik.activity"
                ]
                print(activityType!.rawValue)

                if refused.contains(activityType!.rawValue) {
                    self.showAlertWithMessageWithMail(
                        theMessage: "Nous considérons que cette application n'est pas autorisée à être utilisé pour partager un commerce. Vous pouvez cependant nous faire changer d'avis. 🤯".localized(),
                        title: "Application non autorisé",
                        preComposedBody: "Salut Weeclik,\n\nvous avez refusé l'utilisation de l'application suivante : \n\nNom de l'application : < Ajoutez le nom de l'application >\nId : \(activityType?.rawValue ?? "< Nom de l'application utilisé >")\n\n\nPour les raisons suivantes je pense que vous devriez l'activer : \n\n< Ajoutez vos raisons ici >\n\n< Ajoutez une image une ou plusieurs captures d'écran si vous le souhaitez >".localized()
                    )
                    return
                } else if autorized.contains(activityType!.rawValue) {
//                    self.saveCommerceIdInUserDefaults()
                    let vc = UIStoryboard(name: "Partage", bundle: nil).instantiateViewController(withIdentifier: "ListeDesFavorisVCNav") as! UINavigationController
                    if let listeVC = vc.children.first as? ListeDesFavorisVC {
                        listeVC.commerce = self.commerceObject
                        listeVC.strPartage = str
                    }
                    self.present(vc, animated: true, completion: nil)
                } else {
                    // [1] On envoi un mail pour l'intégration de l'app à Weeclik
                    MailHelper.sendErrorMail(content: "Une application inconnue a été utilisée pour la fonction de partage. \nL'identifiant de l'app : \(activityType.debugDescription)".localized())
                    // [2] On affiche un message d'erreur à l'utilisateur pour une future intégration
                    HelperAndKeys.showAlertWithMessage(theMessage: "Nous ne prenons pas encore cette application pour le partage. Nous ferons au plus vite pour l'ajouter au réseau Weeclik".localized(), title: "Application non prise en charge".localized(), viewController: self)
                    return
                }
            }

            self.present(activit, animated: true, completion: nil)

        } else {
            // Attendre avant de partager
            let da = HelperAndKeys.getSharingTimer(forCommerceId: commerceID)
            if let da = da {
                let date = da + 1.days
                let paris = Region(calendar: Calendars.gregorian, zone: Zones.europeParis, locale: Locales.french)
                HelperAndKeys.showAlertWithMessage(theMessage: "Merci d'avoir partagé ce commercant avec vos proches. Vous pourrez de nouveau le partager à cette date :\n\(date.convertTo(region: paris).toFormat("dd MMM yyyy 'à' HH:mm"))".localized(), title: "Merci pour votre confiance".localized(), viewController: self)
            } else {
                HelperAndKeys.showAlertWithMessage(theMessage: "Merci d'avoir partagé ce commercant avec vos proches. Vous pourrez de nouveau le partager demain.".localized(), title: "Merci pour votre confiance".localized(), viewController: self)
            }

        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! DetailGalleryVC
        destination.commerce = self.commerceObject
    }
}

extension DetailCommerceViewController: UITableViewDelegate, UITableViewDataSource {

    var sections : Int {get {return 3}}
    var heightForHeaderAndFooter : CGFloat {get {return 25/4}}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier = "ShareButtonCell"

        var cell : UITableViewCell
        if indexPath.section == 1 {
            identifier = "PromotionsCell"
            cell = (tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PromotionsCell)!
            if self.commerceObject != nil {
                let scell = cell as! PromotionsCell

                // Set text
                scell.promotionTextView.text = self.commerceObject.promotions

                // Auto resize of text from its content
                let fixedWidth = scell.promotionTextView.frame.size.width
                scell.promotionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                let newSize = scell.promotionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                var newFrame = scell.promotionTextView.frame
                newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
                self.promotionsH = newSize.height
                scell.promotionTextView.frame = newFrame

                scell.alreadyShared.image = HelperAndKeys.canShareAgain(objectId: self.commerceObject.objectId.description) ? UIImage(named: "Certificate_icon") : UIImage(named: "Certificate_valid_icon")

                let back = cell.viewWithTag(88)
                back?.setCardView(view: back!)
            }
        } else if indexPath.section == 2 {

            identifier = "DescriptionCell"
            cell = (tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? DescriptionCell)!
            if self.commerceObject != nil {
                let scell = cell as! DescriptionCell

                // Set text
                scell.descriptionTextView.text = self.commerceObject.descriptionO

                // Auto resize
                let fixedWidth = scell.descriptionTextView.frame.size.width
                scell.descriptionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                let newSize = scell.descriptionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                var newFrame = scell.descriptionTextView.frame
                newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
                self.descriptionH = newSize.height <= 40 ? 40 : newSize.height
                scell.descriptionTextView.frame = newFrame

                let back = cell.viewWithTag(99)
                back?.setCardView(view: back!)
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return 1}

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 0
//            return 74
        } else if indexPath.section == 1 {
            return self.promotionsH + 52 // 50 = Marges haut et bas + le label "Promotions"
        } else if indexPath.section == 2 {
            return self.descriptionH + 42
        } else {
            return 44
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {return sections}

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == sections-1 ? heightForHeaderAndFooter*2 : heightForHeaderAndFooter
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == self.sections-1 {
            return 0
        } else {
            return section == 0 ? 0 : heightForHeaderAndFooter
        }
    }
}

// MARK: Lifecycle + init function
extension DetailCommerceViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.headerImage.isHidden = false
        self.view.backgroundColor = UIColor.white

        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)

        self.view.backgroundColor = HelperAndKeys.getBackgroundColor()

        // Share actions
        self.shareButton.addTarget(self, action: #selector(shareCommerce), for: .touchUpInside)
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Share_icon") , style: .plain, target: self, action: #selector(shareCommerce))
        self.title = "Weeclik".localized()

        initScrollersAndGalleries()

        self.updateCommerce()

        if commerceObject != nil {

            self.nomCommerceLabel.text = commerceObject.nom
            self.categorieLabel.text   = commerceObject.type

            self.nomCommerceLabel.font = FontHelper.getScaledFont(forFont: "Pacifico", textStyle: .title1)
            self.nomCommerceLabel.fontSize = 40
            self.nomCommerceLabel.adjustsFontForContentSizeCategory = true

            self.hasGrantedLocation = HelperAndKeys.getLocationGranted()
            self.prefFiltreLocation = HelperAndKeys.getPrefFiltreLocation()

            if self.hasGrantedLocation {
                self.headerDistanceLabel.text = self.commerceObject.distanceFromUser  == "" ? "--" : self.commerceObject.distanceFromUser
            } else {
                self.headerDistanceLabel.text = "--"
            }

            self.headerPartagesLabel.text = String(self.commerceObject.partages)

            if let thumbFile = self.commerceObject.thumbnail {
                self.headerImage.sd_setImage(with: URL(string: thumbFile.url!))
            }
        } else {
            self.navigationController?.dismiss(animated: true, completion: nil)
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue durant le chargement du commerce. Veuillez réessayer ultérieurement".localized(), title: "Erreur de chargement".localized(), viewController: self)
            print("Erreur de chargment : Commerce est null")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if commerceObject != nil {
            updateAllViews()
        } else {
            print("Erreur de chargment : Commerce est null")
        }

        // Refresh UI
        self.tableView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.imageScroller.stopTimer()
        self.imageScroller.resetScrollImage()
    }

    func initScrollersAndGalleries() {
        self.imageScroller.isAutoScrollEnabled  = true
        self.imageScroller.isAutoLoadingEnabled = true
        self.imageScroller.scrollTimeInterval   = 2.0
        self.imageScroller.scrollView.bounces   = false
    }

    // Customize l'interface utilisateur
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        guard let commerce = self.commerceObject else {
//            print("CommerceID = \(self.commerceID)")
//            return
//        }
        if self.commerceObject == nil {
            updateCommerce()
        }

        // Refresh UI
        self.tableView.reloadData()

//        if self.commerceObject.mail == "" || !self.commerceObject.mail.isValidEmail() {
//            mailButton.isEnabled = false
//        } else {
//            mailButton.isEnabled = true
//        }
//
//        if self.commerceObject.siteWeb == "" || !self.commerceObject.siteWeb.isValidURL() {
//            websiteButton.isEnabled = false
//        } else {
//            websiteButton.isEnabled = true
//        }
//
//        if self.commerceObject.tel == "" || !self.commerceObject.tel.isValidPhone() {
//            callButton.isEnabled = false
//        } else {
//            callButton.isEnabled = true
//        }
//        mailButton.layoutIfNeeded()
//        callButton.layoutIfNeeded()
//        websiteButton.layoutIfNeeded()

        print("website : \(self.commerceObject.siteWeb)")
    }
}

// MARK: Action buttons
extension DetailCommerceViewController {
    @IBAction func mapAction(_ sender: Any) {
        if let location = self.commerceObject.location {
            HelperAndKeys.openMapForPlace(placeName: self.commerceObject.nom, latitude: location.latitude, longitude: location.longitude)
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Erreur de chargement de la position du commerce".localized(), title: "Erreur de position".localized(), viewController: self)
        }
    }
    @IBAction func mailAction(_ sender: Any) {
        if self.commerceObject.mail != "" && self.commerceObject.mail.isValidEmail() {
            sendFeedBackOrMessageViaMail(messageToSend: "", isFeedBackMsg: false, commerceMail: self.commerceObject.mail)
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Erreur de chargement de l'adresse mail du commerce".localized(), title: "Mail non valide".localized(), viewController: self)
        }
    }

    @IBAction func callAction(_ sender: Any) {
        if self.commerceObject.tel != "" {
            if self.commerceObject.tel.isValidPhone() {
                HelperAndKeys.callNumer(phone: self.commerceObject.tel)
            } else {
                HelperAndKeys.showAlertWithMessage(theMessage: "Le téléphone du commerçant renseigné ne permet pas de passer d'appel".localized(), title: "Téléphone invalide".localized(), viewController: self)
            }
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Erreur de chargement du numéro de téléphone du commerce".localized(), title: "Téléphone non valide".localized(), viewController: self)
        }
    }

    @IBAction func webAction(_ sender: Any) {
        if self.commerceObject.siteWeb != "" && self.commerceObject.siteWeb.isValidURL() {
            HelperAndKeys.visitWebsite(site: self.commerceObject.siteWeb, controller: self)
        } else {
            self.showBasicToastMessage(withMessage: "Ce commercant ne possède pas de site web pour le moment".localized(), state: .error)
        }
    }

    @IBAction func shareActionCell(_ sender: Any) {self.shareCommerce()}
}

// MARK: Mail & SMS functions
extension DetailCommerceViewController : MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {

    func showAlertWithMessageWithMail(theMessage:String, title:String, preComposedBody:String = "") {
        let alertViewController = UIAlertController.init(title: title, message: theMessage, preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction.init(title: "OK".localized(), style: .cancel) { (_) -> Void in
            alertViewController.dismiss(animated: true, completion: nil)
        }
        alertViewController.addAction(defaultAction)

        let mailAction = UIAlertAction(title: "Envoyer un mail".localized(), style: .default) { (_) in
            if MFMailComposeViewController.canSendMail() {
                let composeVC = MFMailComposeViewController()

                // Configure the fields of the interface.
                composeVC.setSubject("Partage via une application non autorisé".localized())
                composeVC.setToRecipients(["contact@herrick-wolber.fr"])

                if preComposedBody != "" {
                    composeVC.setMessageBody(preComposedBody, isHTML: false)
                }

                composeVC.navigationBar.barTintColor = UIColor.white

                // Present the view controller modally.
                self.present(composeVC, animated: true, completion: nil)
            } else {
                HelperAndKeys.showAlertWithMessage(theMessage: "Il semblerait que vous n'ayez pas configuré votre boîte mail depuis votre téléphone.".localized(), title: "Erreur".localized(), viewController: self)
            }
        }
        alertViewController.addAction(mailAction)

        self.present(alertViewController, animated: true, completion: nil)
    }

    func sendFeedBackOrMessageViaMail(messageToSend : String, isFeedBackMsg : Bool, commerceMail : String) {
        let messageAdded : String
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        if !isFeedBackMsg {
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Téléchargez-la ici : http://www.google.fr/".localized()
        } else {
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Numéro de version de l'app : \(versionNumber)".localized()
        }
        //                let allowedCharacters = NSCharacterSet.urlFragmentAllowed
        let finalMessage = messageToSend.appending(messageAdded)

        if MFMailComposeViewController.canSendMail() {
            // Configure the fields of the interface.
            composeVC.mailComposeDelegate = self
            composeVC.setSubject("Demande de contact via WeeClik".localized())
            composeVC.setToRecipients([commerceMail])
            composeVC.setMessageBody(finalMessage, isHTML: true)

            composeVC.navigationBar.barTintColor = UIColor.white

            // Present the view controller modally.
            self.present(composeVC, animated: true, completion: nil)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            // Erreur
            HelperAndKeys.showAlertWithMessage(theMessage: error.localizedDescription, title: "Erreur", viewController: self)
        } else {
            switch result {
            case .cancelled:
                print("Annulé")
                break
            case .failed:
                HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue lors du partage de ce commerce. Merci de réessayer.".localized(), title: "Erreur".localized(), viewController: self)
                break
            case .sent:
                HelperAndKeys.showAlertWithMessage(theMessage: "Votre partage a été pris en compte. Vous pouvez des à présent profiter de votre promotion.".localized(), title: "Merci pour votre confiance".localized(), viewController: self)
                // On a bien partagé -> sauvegarde dans le UserDefaults
                saveCommerceIdInUserDefaults()
                break
            case .saved:
                print("Sauvegardé en brouillon")
                break
            @unknown default:
                print("unknown result")
            }
        }
        self.dismiss(animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("Ecriture de message annulé")
            break
        case .failed:
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue lors du partage de ce commerce. Merci de réessayer.".localized(), title: "Erreur".localized(), viewController: self)
            break
        case .sent:
            HelperAndKeys.showAlertWithMessage(theMessage: "Votre partage a été pris en compte. Vous pouvez des à présent profiter de votre promotion.".localized(), title: "Merci pour votre confiance".localized(), viewController: self)
            // On a bien partagé -> sauvegarde dans le UserDefaults
            saveCommerceIdInUserDefaults()
            break
        @unknown default:
            print("Unknown result from switch case in Message Compose Delegates")
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
