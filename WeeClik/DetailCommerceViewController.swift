//
//  DetailCommerceViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 30/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO : ouvrir le lien dans l'app et non le navigateur du tel (forcer l'user a rester dans l'application)
// TODO : mettre la description a 500 caractère max
// TODO : vv fonction de timer pour l'attente de rvarartage qui appele a la fin cette fonction vv
// TODO : faire le slideshow photo automatique
// TODO : faire le bouton vidéo
// TODO : 6. Faire une verification sur l'autorisation de la position plutot qu'une verification sur la valeur enregistré de la distance

import UIKit
import Foundation
import Parse
import MessageUI
import MapKit
import LGButton

class DetailCommerceViewController: UIViewController {
    
    
    @IBOutlet weak var shareButton: LGButton!
    
    var commerceObject : Commerce!
    var commerceID : String!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.headerImage.isHidden = false
        self.view.backgroundColor = UIColor.white
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 70, 0)
        
        self.view.backgroundColor = HelperAndKeys.getBackgroundColor()
        
        // Share actions
        self.shareButton.addTarget(self, action: #selector(shareCommerce), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Share_icon") , style: .plain, target: self, action: #selector(shareCommerce))
        
        self.nomCommerceLabel.text = commerceObject.nom
        self.categorieLabel.text   = commerceObject.type
        
        // 6. TODO
        if self.commerceObject.distanceFromUser == "" {
            self.distanceView.isHidden = true
        } else {
            self.headerDistanceLabel.text = self.commerceObject.distanceFromUser
            self.distanceView.isHidden = false
        }
        
        self.headerPartagesLabel.text = String(self.commerceObject.partages)
        
        initScrollersAndGalleries()
        
        self.title = "Weeclik"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateAllViews()
        
        // Refresh UI
        self.tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.imageScroller.stopTimer()
    }
    
    func initScrollersAndGalleries(){
        self.imageScroller.isAutoScrollEnabled  = true
        self.imageScroller.isAutoLoadingEnabled = true
        self.imageScroller.scrollTimeInterval   = 2.0
        self.imageScroller.scrollView.bounces   = false
    }
    
    @objc func updateAllViews(){
        // Mise a jour de notre variable globale pour l'ensemble de nos fonctions
        commerceID = self.commerceObject.objectId.description
        
        // Charger les photos dans le slider
        loadPhotosFromDB()
        loadSliderFromFetchedPhotos()
    }
    
    func saveCommerceIdInUserDefaults(){
        // Met dans le UserDefaults + ajoute une notification au moment écoulé
        HelperAndKeys.setSharingTime(forCommerceId: commerceID, commerceName : commerceObject.nom)
        // Met à jour les données dans la BDD distante
        HelperAndKeys.saveStatsInDb(commerce: self.commerceObject.pfObject)
        self.tableView.reloadData()
    }
    
    func loadSliderFromFetchedPhotos(){
        if sampleImagesUrls.count > 1{
            self.headerImage.isHidden = true
            imageScroller.setupScrollerWithImages(images: sampleImagesUrls)
        }
    }
    
    func loadPhotosFromDB(){
        let queryPhotos = PFQuery(className: "Commerce_Photos")
        queryPhotos.whereKey("commerce", equalTo: self.commerceObject.pfObject)
        queryPhotos.order(byDescending: "updatedAt")
        queryPhotos.findObjectsInBackground { (objects, err) in
            if (err != nil) {
                // TODO: Error Handling
                print("Erreur de chargement du slider => \(String(describing: err?.localizedDescription))")
            } else {
                if objects != nil {
                    // TEST:
                    self.sampleImagesUrls = []
                    for obj in objects!{
                        let fileUrl = (obj["photo"] as? PFFile)?.url
                        if fileUrl != nil {
                            self.sampleImagesUrls.append(fileUrl!)
                        }
                    }
                    //print("Sample urls : \n    \(self.sampleImagesUrls)")
                    self.loadSliderFromFetchedPhotos()
                }
            }
        }
    }
    
    @objc func shareCommerce(){
        if HelperAndKeys.canShareAgain(objectId: commerceID){
            let str = "Voici les coordonées d'un super commerce que j'ai découvert : \n\n\(self.commerceObject.nom)\nTéléphone : \(self.commerceObject.tel)\nAdresse : \(self.commerceObject.adresse)"
            let activit = UIActivityViewController(activityItems: [str], applicationActivities: nil)
            self.present(activit, animated: true, completion: nil)
            
        } else {
            // Attendre avant de partager
            let date = HelperAndKeys.getSharingStringDate(objectId: commerceID)
            
            HelperAndKeys.showAlertWithMessage(theMessage: "Merci d'avoir partagé ce commercant avec vos proches. Vous pourrez de nouveau le partager à cette date :\n\(String(describing: date))", title: "Merci", viewController: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! DetailGalleryVC
        destination.commerce = self.commerceObject
//        destination.photos = commerceObject.photosCommerces
//        destination.videos = commerceObject.videosCommerce
    }
}

extension DetailCommerceViewController: UITableViewDelegate, UITableViewDataSource{
    
    var sections : Int {get {return 3}}
    var heightForHeaderAndFooter : CGFloat {get {return 25/4}}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier = "ShareButtonCell"
        
        var cell : UITableViewCell
        if indexPath.section == 1 {
            identifier = "PromotionsCell"
            cell = (tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PromotionsCell)!
            if self.commerceObject != nil{
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
        }
        else if indexPath.section == 2{
            
            identifier = "DescriptionCell"
            cell = (tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? DescriptionCell)!
            if self.commerceObject != nil{
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
        }
        else{
            cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return 1}
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0{
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

extension DetailCommerceViewController{
    // Customize l'interface utilisateur
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mailButton.layoutIfNeeded()
        callButton.layoutIfNeeded()
        websiteButton.layoutIfNeeded()
        
        let colorBorder = UIColor(red:0.59, green:0.59, blue:0.59, alpha:0.35)
        
        mailButton.layer.addBorder(edge: .left, color: colorBorder, thickness: 1)
        callButton.layer.addBorder(edge: .left, color: colorBorder, thickness: 1)
        websiteButton.layer.addBorder(edge: .left, color: colorBorder, thickness: 1)
    }
}

// Actions
extension DetailCommerceViewController{
    @IBAction func mapAction(_ sender: Any) {
        if let location = self.commerceObject.location{
            HelperAndKeys.openMapForPlace(placeName: self.commerceObject.nom, latitude: location.latitude, longitude: location.longitude)
        } else {
            HelperAndKeys.openMapForPlace(placeName: self.commerceObject.nom, latitude: 23, longitude: 3)
        }
    }
    @IBAction func mailAction(_ sender: Any) {sendFeedBackOrMessageViaMail(messageToSend: "", isFeedBackMsg: false, commerceMail: self.commerceObject.mail)}
    
    @IBAction func callAction(_ sender: Any) {HelperAndKeys.callNumer(phone: self.commerceObject.tel)}
    
    @IBAction func webAction(_ sender: Any) {HelperAndKeys.visitWebsite(site: self.commerceObject.siteWeb, controller: self)}
    
    @IBAction func shareActionCell(_ sender: Any) {self.shareCommerce()}
}

extension DetailCommerceViewController : MFMailComposeViewControllerDelegate {
    func sendFeedBackOrMessageViaMail(messageToSend : String, isFeedBackMsg : Bool, commerceMail : String){
        let messageAdded : String
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        if !isFeedBackMsg{
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Téléchargez-la ici : http://www.google.fr/"
        }else{
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Numéro de version de l'app : \(versionNumber)"
        }
        //                let allowedCharacters = NSCharacterSet.urlFragmentAllowed
        let finalMessage = messageToSend.appending(messageAdded)
        
        if MFMailComposeViewController.canSendMail(){
            // Configure the fields of the interface.
            composeVC.mailComposeDelegate = self
            composeVC.setSubject("Demande de contact via WeeClik")
            composeVC.setToRecipients([commerceMail])
            composeVC.setMessageBody(finalMessage, isHTML: true)
            
            composeVC.navigationBar.barTintColor = UIColor.white
            
            // Present the view controller modally.
            self.present(composeVC, animated: true, completion: nil)
        }else{
//            self.showAlertWithMessage(theMessage: "Il semblerait que vous n'ayez pas configuré votre boîte mail depuis votre téléphone.", title: "Erreur", viewController: controller)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if error == nil {
            switch result {
            case .cancelled:
                print("Annulé")
                break
            case .failed:
                print("Echoué")
                break
            case .sent:
                print("Envoyé")
                break
            case .saved:
                print("Sauvegardé en brouillon")
                break
            }
        } else {
            // Erreur
            HelperAndKeys.showAlertWithMessage(theMessage: "", title: "", viewController: self)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension DetailCommerceViewController : MFMessageComposeViewControllerDelegate{
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled:
//            HelperAndKeys.showNotification(type: "", title: "Title", message: "Message", delay: 2)
            break
        case .failed:
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue lors du partage de ce commerce. Merci de réessayer.", title: "Erreur", viewController: self)
            break
        case .sent:
            HelperAndKeys.showAlertWithMessage(theMessage: "Votre partage a été pris en compte. Vous pouvez des à présent profiter de votre promotion.", title: "Merci pour votre confiance", viewController: self)
            // On a bien partagé -> sauvegarde dans le UserDefaults
//            saveCommerceIdInUserDefaults(viewController: self)
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

