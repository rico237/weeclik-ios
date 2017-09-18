//
//  DetailCommerceViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 30/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

// TODO : ouvrir le lien dans l'app et non le navigateur du tel (forcer l'user a rester dans l'application)
// TODO : mettre la description a 500 caractère max

import UIKit
import Parse
import MessageUI
import MapKit

class DetailCommerceViewController: UIViewController {
    
    var commerceObject : Commerce!
    
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var websiteButton: UIButton!
    
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var nomCommerceLabel: UILabel!
    @IBOutlet weak var categorieLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var promotionsH : CGFloat = 0.0
    var descriptionH : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = HelperAndKeys.getBackgroundColor()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Share_icon") , style: .plain, target: self, action: #selector(shareCommerce))
        
        self.nomCommerceLabel.text = commerceObject.nom
        self.categorieLabel.text = commerceObject.type
        
        self.title = "Weeclik"
    }
    
    func shareCommerce(){
        if MFMessageComposeViewController.canSendText(){
            let composeVC = MFMessageComposeViewController()
            composeVC.messageComposeDelegate = self
            // Configure the fields of the interface.
            composeVC.body = "Voici les coordonées d'un super commerce que j'ai découvert : \n\n\(self.commerceObject.nom)\nTéléphone : \(self.commerceObject.tel)\nAdresse : \(self.commerceObject.adresse)"
            // Present the view controller modally.
            self.present(composeVC, animated: true, completion: nil)
        }else{
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue lors du partage par SMS", title: "Erreur", viewController: self)
        }
    }
}

extension DetailCommerceViewController: UITableViewDelegate, UITableViewDataSource{
    
    var sections : Int {get {return 3 }}
    var heightForHeaderAndFooter : CGFloat {get {return 25/4 }}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier = "PromotionsCell"
        
        var cell : UITableViewCell
        
        if indexPath.section == 1 {
            identifier = "InfosGeneral"
            cell = (tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? InformationGeneralCell)!
            if self.commerceObject != nil{
                let scell = cell as! InformationGeneralCell
                scell.mailLabel.text = self.commerceObject.mail
                scell.adresseLabel.text = self.commerceObject.adresse
                scell.telLabel.text = self.commerceObject.tel
                scell.webLabel.text = self.commerceObject.siteWeb
                
                
                
                if let imageThumbnailFile = self.commerceObject.thumbnail {
                    self.headerImage.sd_setImage(with: URL(string: imageThumbnailFile.url!))
                }
                else if let coverPhoto = self.commerceObject.coverPhoto{
                    self.headerImage.sd_setImage(with: URL(string: coverPhoto.url!))
                }
                else {
                    self.headerImage.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: self.commerceObject.type)
                }
                
                let back = cell.viewWithTag(77)
                back?.setCardView(view: back!)
            }
        }
        else if indexPath.section == 0{
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
                
                if HelperAndKeys.canShareAgain(objectId: self.commerceObject.objectId){
                    scell.alreadyShared.image = UIImage(named: "Certificate_valid_icon")
                }
                
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
                
                if newSize.height <= 40{
                    self.descriptionH = 40
                }else{
                    self.descriptionH = newSize.height
                }
                
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0{
            return 236
        }else if indexPath.section == 1 {
            return self.promotionsH + 52 // 50 = Marges haut et bas + le label "Promotions"
        }else if indexPath.section == 2{
            return self.descriptionH + 42
        }else{
            return 44
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return heightForHeaderAndFooter*2
        }
        
        return heightForHeaderAndFooter
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == sections-1{
            return heightForHeaderAndFooter*2
        }
        
        return heightForHeaderAndFooter
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
        }
        else{
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
            break
        case .failed:
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue lors du partage de ce commerce. Merci de réessayer.", title: "Erreur", viewController: self)
            break
        case .sent:
            HelperAndKeys.showAlertWithMessage(theMessage: "Votre partage a été exécuté avec succès. Vous pouvez des à présent profiter de votre promotion.", title: "Merci pour votre confiance", viewController: self)
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
