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
    var commerceObject: Commerce!
    var commerceID: String!

    var prefFiltreLocation: Bool!
    var hasGrantedLocation: Bool!

    var routeCommerceId: String!
    let userDefaults: UserDefaults = UserDefaults.standard
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

    var sampleImagesUrls: [String] = []

    var promotionsH: CGFloat  = 0.0
    var descriptionH: CGFloat = 0.0

    @objc func updateAllViews() {
        // Mise a jour de notre variable globale pour l'ensemble de nos fonctions
        commerceID = commerceObject.objectId!

        // Charger les photos dans le slider
        loadPhotosFromDB()
        loadSliderFromFetchedPhotos()
    }

    func updateCommerce() {
        var objId = commerceID
        if let routeId = routeCommerceId, !routeCommerceId.isEmptyStr { objId = routeId }

        let query = PFQuery(className: "Commerce")
        query.whereKey("objectId", equalTo: objId!)
        query.includeKeys(["thumbnailPrincipal"])
        query.getFirstObjectInBackground { (commerce, error) in
            guard let commerce = commerce else {
                if let error  = error { ParseErrorCodeHandler.handleUnknownError(error: error) }
                return
            }
            self.commerceObject = Commerce(parseObject: commerce)
            self.tableView.reloadData()
        }
    }

    func saveCommerceIdInUserDefaults() {
        // Met dans le UserDefaults + ajoute une notification au moment écoulé
        HelperAndKeys.setSharingTime(forCommerceId: commerceID)
        // Met à jour les données dans la BDD distante
        HelperAndKeys.saveStatsInDb(commerce: commerceObject.pfObject, user: PFUser.current())

        updateCommerce()
    }

    func loadSliderFromFetchedPhotos() {
        if !sampleImagesUrls.isEmpty {
            // N images chargé depuis la BDD
            headerImage.isHidden = true
            imageScroller.setupScrollerWithImages(images: sampleImagesUrls)
        }
    }

    func loadPhotosFromDB() {
        let queryPhotos = PFQuery(className: "Commerce_Photos")
        queryPhotos.whereKey("commerce", equalTo: commerceObject.pfObject!)
        queryPhotos.order(byDescending: "updatedAt")
        queryPhotos.findObjectsInBackground { (objects, error) in
            guard let commercePhotos = objects else {
                if error != nil { self.showBasicToastMessage(withMessage: "Erreur de chargement des images", state: .error) }
                return
            }

            self.sampleImagesUrls.removeAll()
            for photo in commercePhotos {
                if let fileUrl = (photo["photo"] as? PFFileObject)?.url {
                    self.sampleImagesUrls.append(fileUrl)
                }
            }
            self.loadSliderFromFetchedPhotos()
        }
    }

    @objc func shareCommerce() {

        if HelperAndKeys.canShareAgain(objectId: commerceID) {
            let sharingMessage = Constants.MessageString.partageMessage(commerceObject: commerceObject)

            let customItem = ShareToGroupsActivity(title: "Partager à un groupe d'amis".localized()) { sharedItems in
                guard let customGroupSharing = sharedItems as? [String] else { return }
                self.shrdString = customGroupSharing
            }

            let activit = UIActivityViewController(activityItems: [sharingMessage], applicationActivities: [customItem])
            activit.excludedActivityTypes = [
                .markupAsPDF, .postToVimeo, .postToWeibo, .postToFlickr, .postToTencentWeibo,
                .copyToPasteboard, .openInIBooks, .assignToContact, .addToReadingList,
                .saveToCameraRoll, .print
            ]
            activit.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                // Return if cancelled
                if (!completed) {return}

                // Extensions refusé comme partage valide
                let refused: [String] = [
                    "com.apple.mobilenotes.SharingExtension",
                    UIActivity.ActivityType.copyToPasteboard.rawValue
                ]
                // Extensions autorisées comme partage valide
                let autorized: [String] = [
                    UIActivity.ActivityType.mail.rawValue, UIActivity.ActivityType.message.rawValue,
                    UIActivity.ActivityType.postToTwitter.rawValue, UIActivity.ActivityType.postToFacebook.rawValue,
                    "net.whatsapp.WhatsApp.ShareExtension", "com.google.Gmail.ShareExtension", "com.ringosoftware.weeclik.activity", "com.ringosoftware.weeclik-DEV.activity"
                ]

                if refused.contains(activityType!.rawValue) {
                    self.showAlertWithMessageWithMail(
                        theMessage: "Nous considérons que cette application n'est pas autorisée à être utilisé pour partager un commerce. Vous pouvez cependant nous faire changer d'avis. 🤯".localized(),
                        title: "Application non autorisé",
                        preComposedBody: "Salut Weeclik,\n\nvous avez refusé l'utilisation de l'application suivante : \n\nNom de l'application : < Ajoutez le nom de l'application >\nId : \(activityType?.rawValue ?? "< Nom de l'application utilisé >")\n\n\nPour les raisons suivantes je pense que vous devriez l'activer : \n\n< Ajoutez vos raisons ici >\n\n< Ajoutez une image une ou plusieurs captures d'écran si vous le souhaitez >".localized()
                    )
                    return
                } else if autorized.contains(activityType!.rawValue) {
                    Logger.logEvent(for: "DetailCommerceViewController", message: "Activity type: \(activityType!.rawValue)", level: .debug)
                    if let sharingListNavigationController = UIStoryboard(name: "Partage", bundle: nil).instantiateViewController(withIdentifier: "ListeDesFavorisVCNav") as? UINavigationController,
                        let listeFavorisVC = sharingListNavigationController.children.first as? ListeDesFavorisVC {
                        listeFavorisVC.commerce = self.commerceObject
                        listeFavorisVC.strPartage = sharingMessage
                        self.presentFullScreen(viewController: sharingListNavigationController, completion: nil)
                    }
                } else {
                    // [1] On envoi un mail pour l'intégration de l'app à Weeclik
                    MailHelper.sendErrorMail(content: "Une application inconnue a été utilisée pour la fonction de partage. \nL'identifiant de l'app : \(activityType.debugDescription)".localized())
                    // [2] On affiche un message d'erreur à l'utilisateur pour une future intégration
                    self.showAlertWithMessage(message: "Nous ne prenons pas encore cette application pour le partage. Nous ferons au plus vite pour l'ajouter au réseau Weeclik".localized(), title: "Application non prise en charge".localized(), completionAction: nil)
                    return
                }
            }
            present(activit, animated: true, completion: nil)

        } else {
            // Attendre avant de partager
            let dateBeforeSharingAgain = HelperAndKeys.getSharingTimer(forCommerceId: commerceID)
            if let dateBeforeSharingAgain = dateBeforeSharingAgain {
                let date = dateBeforeSharingAgain + 7.days
                let paris = Region(calendar: Calendars.gregorian, zone: Zones.europeParis, locale: Locales.french)
                self.showAlertWithMessage(message: "Merci d'avoir partagé ce commercant avec vos proches. Vous pourrez de nouveau le partager à cette date :\n\(date.convertTo(region: paris).toFormat("dd MMM yyyy 'à' HH:mm"))".localized(), title: "Merci pour votre confiance".localized(), completionAction: nil)
            } else {
                self.showAlertWithMessage(message: "Merci d'avoir partagé ce commercant avec vos proches. Vous pourrez de nouveau le partager dans une semaine.".localized(), title: "Merci pour votre confiance".localized(), completionAction: nil)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DetailGalleryVC {
            destination.commerce = commerceObject
        }
    }
}

extension DetailCommerceViewController: UITableViewDelegate, UITableViewDataSource {

    var sections: Int {return 3}
    var heightForHeaderAndFooter: CGFloat {return 25/4}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier = "ShareButtonCell"

        var cell: UITableViewCell
        if indexPath.section == 1 {
            identifier = "PromotionsCell"
            cell = (tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PromotionsCell)!
            if commerceObject != nil {
                let promotionCell = cell as! PromotionsCell

                // Set text
                promotionCell.promotionTextView.text = commerceObject.promotions

                // Auto resize of text from its content
                let fixedWidth = promotionCell.promotionTextView.frame.size.width
                promotionCell.promotionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                let newSize = promotionCell.promotionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                var newFrame = promotionCell.promotionTextView.frame
                newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
                promotionsH = newSize.height
                promotionCell.promotionTextView.frame = newFrame

                promotionCell.alreadyShared.image = HelperAndKeys.canShareAgain(objectId: commerceObject.objectId!) ? UIImage(named: "Certificate_icon") : UIImage(named: "Certificate_valid_icon")

                if let back = cell.viewWithTag(88) {
                    back.setCardView(view: back)
                }
            }
        } else if indexPath.section == 2 {

            identifier = "DescriptionCell"
            cell = (tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? DescriptionCell)!
            if commerceObject != nil {
                let descriptionCell = cell as! DescriptionCell

                // Set text
                descriptionCell.descriptionTextView.text = commerceObject.descriptionO

                // Auto resize
                let fixedWidth = descriptionCell.descriptionTextView.frame.size.width
                descriptionCell.descriptionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                let newSize = descriptionCell.descriptionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                var newFrame = descriptionCell.descriptionTextView.frame
                newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
                descriptionH = newSize.height <= 40 ? 40 : newSize.height
                descriptionCell.descriptionTextView.frame = newFrame

                if let back = cell.viewWithTag(99) {
                    back.setCardView(view: back)
                }
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
            return promotionsH + 52 // 50 = Marges haut et bas + le label "Promotions"
        } else if indexPath.section == 2 {
            return descriptionH + 42
        } else {
            return 44
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {return sections}

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == sections-1 ? heightForHeaderAndFooter*2 : heightForHeaderAndFooter
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == sections-1 {
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
        NotificationCenter.default.addObserver(self, selector: #selector(onDidSendGroupeFavorisSMS(_:)), name: .didSendGroupeFavorisSMS, object: nil)
        
        headerImage.isHidden = false
        view.backgroundColor = UIColor.white
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        view.backgroundColor = Colors.backgroundColor

        // Share actions
        shareButton.addTarget(self, action: #selector(shareCommerce), for: .touchUpInside)
        title = "Weeclik".localized()

        initScrollersAndGalleries()

        updateCommerce()

        if commerceObject != nil {

            nomCommerceLabel.text = commerceObject.nom
            categorieLabel.text   = commerceObject.type

            nomCommerceLabel.font = FontHelper.getScaledFont(forFont: "Pacifico", textStyle: .title1)
            nomCommerceLabel.fontSize = 40
            nomCommerceLabel.adjustsFontForContentSizeCategory = true

            hasGrantedLocation = HelperAndKeys.getLocationGranted()
            prefFiltreLocation = HelperAndKeys.getPrefFiltreLocation()

            if hasGrantedLocation {
                headerDistanceLabel.text = commerceObject.distanceFromUser  == "" ? "--" : commerceObject.distanceFromUser
            } else {
                headerDistanceLabel.text = "--"
            }

            headerPartagesLabel.text = String(commerceObject.partages)

            if let thumbFile = commerceObject.thumbnail {
                headerImage.sd_setImage(with: URL(string: thumbFile.url!))
            }
        } else {
            navigationController?.dismiss(animated: true, completion: nil)
            self.showAlertWithMessage(message: "Une erreur est survenue durant le chargement du commerce. Veuillez réessayer ultérieurement".localized(), title: "Erreur de chargement".localized(), completionAction: nil)
        }
    }
    
    @objc func onDidSendGroupeFavorisSMS(_ notification: Notification) {
        print("Nombre partage : \(commerceObject.partages)")
        headerPartagesLabel.text = String(commerceObject.partages + 1)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageScroller.stopTimer()
        imageScroller.resetScrollImage()
    }

    func initScrollersAndGalleries() {
        imageScroller.isAutoScrollEnabled  = true
        imageScroller.isAutoLoadingEnabled = true
        imageScroller.scrollTimeInterval   = 2.0
        imageScroller.scrollView.bounces   = false
    }

    // Customize l'interface utilisateur
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard commerceObject != nil else { return }
        // Refresh UI
        updateAllViews()
        tableView.reloadData()
//        print("website : \(commerceObject.siteWeb)")
        
//        if commerceObject.mail == "" || !commerceObject.mail.isValidEmail() {
//            mailButton.isEnabled = false
//        } else {
//            mailButton.isEnabled = true
//        }
//
//        if commerceObject.siteWeb == "" || !commerceObject.siteWeb.isValidURL() {
//            websiteButton.isEnabled = false
//        } else {
//            websiteButton.isEnabled = true
//        }
//
//        if commerceObject.tel == "" || !commerceObject.tel.isValidPhone() {
//            callButton.isEnabled = false
//        } else {
//            callButton.isEnabled = true
//        }
    }
}

// MARK: Action buttons
extension DetailCommerceViewController {
    @IBAction func mapAction(_ sender: Any) {
        if let location = commerceObject.location {
            HelperAndKeys.openMapForPlace(placeName: commerceObject.nom, latitude: location.latitude, longitude: location.longitude)
        } else {
            self.showAlertWithMessage(message: "Erreur de chargement de la position du commerce".localized(), title: "Erreur de position".localized(), completionAction: nil)
        }
    }
    @IBAction func mailAction(_ sender: Any) {
        if commerceObject.mail != "" && commerceObject.mail.isValidEmail() {
            sendFeedBackOrMessageViaMail(messageToSend: "", isFeedBackMsg: false, commerceMail: commerceObject.mail)
        } else {
            self.showAlertWithMessage(message: "Erreur de chargement de l'adresse mail du commerce".localized(), title: "Mail non valide".localized(), completionAction: nil)
        }
    }

    @IBAction func callAction(_ sender: Any) {
        if commerceObject.tel != "" {
            if commerceObject.tel.isValidPhone() {
                HelperAndKeys.callNumer(phone: commerceObject.tel)
            } else {
                 self.showAlertWithMessage(message: "Le téléphone du commerçant renseigné ne permet pas de passer d'appel".localized(), title: "Téléphone invalide".localized(), completionAction: nil)
            }
        } else {
            self.showAlertWithMessage(message: "Erreur de chargement du numéro de téléphone du commerce".localized(), title: "Téléphone non valide".localized(), completionAction: nil)
        }
    }

    @IBAction func webAction(_ sender: Any) {
        if commerceObject.siteWeb != "" && commerceObject.siteWeb.isValidURL() {
            self.visitWebsite(urlString: commerceObject.siteWeb)
        } else {
            self.showBasicToastMessage(withMessage: "Ce commercant ne possède pas de site web pour le moment".localized(), state: .error)
        }
    }

    @IBAction func shareActionCell(_ sender: Any) {shareCommerce()}
}

// MARK: Mail & SMS functions
extension DetailCommerceViewController: MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {

    func showAlertWithMessageWithMail(theMessage: String, title: String, preComposedBody: String = "") {
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
                composeVC.setToRecipients(["contact@weeclik.com"])

                if preComposedBody != "" {
                    composeVC.setMessageBody(preComposedBody, isHTML: false)
                }

                composeVC.navigationBar.barTintColor = UIColor.white

                // Present the view controller modally.
                self.present(composeVC, animated: true, completion: nil)
            } else {
                self.showAlertWithMessage(message: "Il semblerait que vous n'ayez pas configuré votre boîte mail depuis votre téléphone.".localized(), title: "Erreur".localized(), completionAction: nil)
            }
        }
        alertViewController.addAction(mailAction)

        present(alertViewController, animated: true, completion: nil)
    }

    func sendFeedBackOrMessageViaMail(messageToSend: String, isFeedBackMsg: Bool, commerceMail: String) {
        let messageAdded: String

        if !isFeedBackMsg {
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Téléchargez-la ici : https://www.weeclik.com/".localized()
        } else {
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Numéro de version de l'app : \(UIApplication.shared.versionBuild())".localized()
        }
        let finalMessage = messageToSend.appending(messageAdded)

        if MFMailComposeViewController.canSendMail() {
            // Configure the fields of the interface.
            composeVC.mailComposeDelegate = self
            composeVC.setSubject("Demande de contact via WeeClik".localized())
            composeVC.setToRecipients([commerceMail])
            composeVC.setMessageBody(finalMessage, isHTML: true)

            composeVC.navigationBar.barTintColor = UIColor.white

            // Present the view controller modally.
            present(composeVC, animated: true, completion: nil)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            // Erreur
            self.showAlertWithMessage(message: error.localizedDescription, title: "Erreur", completionAction: nil)
        } else {
            switch result {
            case .cancelled:
                print("Annulé")
            case .failed:
                self.showAlertWithMessage(message: "Une erreur est survenue lors du partage de ce commerce. Merci de réessayer.".localized(), title: "Erreur".localized(), completionAction: nil)
            case .sent:
                self.showAlertWithMessage(message: "Votre partage a été pris en compte. Vous pouvez des à présent profiter de votre promotion.".localized(), title: "Merci pour votre confiance".localized(), completionAction: nil)
                // On a bien partagé -> sauvegarde dans le UserDefaults
                saveCommerceIdInUserDefaults()
            case .saved:
                print("Sauvegardé en brouillon")
            @unknown default:
                print("unknown result")
            }
        }
        dismiss(animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("Ecriture de message annulé")
        case .failed:
            self.showAlertWithMessage(message: "Une erreur est survenue lors du partage de ce commerce. Merci de réessayer.".localized(), title: "Erreur".localized(), completionAction: nil)
        case .sent:
            self.showAlertWithMessage(message: "Votre partage a été pris en compte. Vous pouvez des à présent profiter de votre promotion.".localized(), title: "Merci pour votre confiance".localized(), completionAction: nil)
            // On a bien partagé -> sauvegarde dans le UserDefaults
            saveCommerceIdInUserDefaults()
        @unknown default:
            print("Unknown result from switch case in Message Compose Delegates")
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
