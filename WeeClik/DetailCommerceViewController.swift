//
//  DetailCommerceViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 30/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO : ouvrir le lien dans l'app et non le navigateur du tel (forcer l'user a rester dans l'application)
// TODO : mettre la description a 500 caractère max
// TODO : vv fonction de timer pour l'attente de re-partage qui appele a la fin cette fonction vv
// TODO : faire le slideshow photo automatique
// TODO : faire le bouton vidéo

import UIKit
import Parse
import MessageUI
import MapKit
import LGButton

class DetailCommerceViewController: UIViewController {
    
    
    @IBOutlet weak var shareButton: LGButton!
    
    var commerceObject : Commerce!
    var commerceID : String!
    let userDefaults : UserDefaults = UserDefaults.standard
    
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
//    @IBOutlet weak var headerMapIcon: UIImageView!
    @IBOutlet weak var headerPartagesLabel: UILabel!
//    @IBOutlet weak var headerPartageIcon: UIImageView!
    @IBOutlet weak var headerDistanceLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
//    var sampleImagesUrls = ["https://mir-s3-cdn-cf.behance.net/project_modules/max_1200/5a87b630333405.563390560768a.jpg",
//                            "https://mir-s3-cdn-cf.behance.net/project_modules/fs/3b10c357981735.59eda2fb7d7c5.jpg",
//                            "https://cdn.dribbble.com/users/237483/screenshots/3233293/treetop.png",
//                            "https://cdn.dribbble.com/users/237483/screenshots/3086220/attachments/651074/whatashittyyear-attach.png",
//                            "https://cdn.dribbble.com/users/237483/screenshots/4065365/breakfast.png",
//                            "https://cdn.dribbble.com/users/237483/screenshots/2823366/bixbycanyonbridge.png"]
    var sampleImagesUrls = [String]()
    
    var promotionsH  : CGFloat = 0.0
    var descriptionH : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 70, 0)
        
        self.view.backgroundColor = HelperAndKeys.getBackgroundColor()
        
        // Share actions
        self.shareButton.addTarget(self, action: #selector(shareCommerce), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Share_icon") , style: .plain, target: self, action: #selector(shareCommerce))
        
        self.nomCommerceLabel.text = commerceObject.nom
        self.categorieLabel.text   = commerceObject.type

        initScrollersAndGalleries()
        
        self.title = "Weeclik"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateAllViews()
        
        
        // Refresh UI
        self.tableView.reloadData()
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
    
    // Voir toutes la liste des photos et vidéos
    @IBAction func showSlideShow(_ sender: Any) {

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
            return 74
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
    @IBAction func mailAction(_ sender: Any) {HelperAndKeys.sendFeedBackOrMessageViaMail(messageToSend: "", isFeedBackMsg: false, commerceMail: self.commerceObject.mail, controller: self)}
    
    @IBAction func callAction(_ sender: Any) {HelperAndKeys.callNumer(phone: self.commerceObject.tel)}
    
    @IBAction func webAction(_ sender: Any) {HelperAndKeys.visitWebsite(site: self.commerceObject.siteWeb, controller: self)}
    
    @IBAction func shareActionCell(_ sender: Any) {self.shareCommerce()}
}

extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect.init(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect.init(x: 0, y: 0, width: thickness, height: frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect.init(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        self.addSublayer(border)
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

