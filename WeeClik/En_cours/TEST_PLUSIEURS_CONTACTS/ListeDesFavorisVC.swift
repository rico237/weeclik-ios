//
//  ListeDesFavorisVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 19/09/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

// TODO: Stocker les groupes dans le cloud = récup les infos des contacts + permet une option payante pour stocker et récup facilement dans le cloud

import UIKit
import SwiftMultiSelect
import Contacts
import MessageUI
import Parse

class ListeDesFavorisVC: UIViewController {

    var listeGroupes    = [GroupePartage]()       // Tableau de tous les groupes crées & stocké en cache
    var groupName       = ""
    let userDef         = UserDefaults.standard
    var imageG          = UIImage(named: "Placeholder_carre")
    var strPartage      = ""
    var newGroupe: GroupePartage!
    var commerce: Commerce!

    @IBOutlet weak var listeGroupesFavoris: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Get data from local storage

        if let favoris = userDef.array(forKey: Constants.UserDefaultsKeys.partageGroupKey) as? [GroupePartage] {
            listeGroupes = favoris
        }

        // Init du tableView
        listeGroupesFavoris.delegate = self
        listeGroupesFavoris.dataSource = self
//        listeGroupesFavoris.register(GroupePartageTVCell.self, forCellReuseIdentifier: "GroupePartageTVCell") // In case of cell direct configuration

        Config.doneString = "Créer".localized()
        Config.viewTitle  = "Créer un groupe".localized()
        Config.maxSelectItems = 20
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listeGroupes = UserDefaultsManager.shared.getGroupesPartage()
        listeGroupesFavoris.reloadData()
    }

    // Fermer le ViewController
    @IBAction func closeView(_ sender: Any) {self.dismiss(animated: true, completion: nil)}
    // Partage SMS TODO: utiliser créer un provider
    @IBAction func action_partage(_ sender: Any) {}
    // Création de groupe
    @IBAction func action_create_group(_ sender: Any) {
        // Création d'un groupe de favoris
        SwiftMultiSelect.delegate = self
        showInputDialog(title: "Ajout d'un groupe".localized(), subtitle: "Créer un groupe pour facilement et rapidement partager ce commerce avec vos proches".localized(), actionTitle: "Créer".localized(), cancelTitle: "Annuler".localized(), inputPlaceholder: "Famille, Amis, Collègues de travail, etc.".localized(), inputKeyboardType: .default, cancelHandler: nil) { (input: String?) in
            if input != "" {
                self.groupName = input ?? "Groupe".localized()
            } else {
                self.groupName = "Groupe".localized()
            }
            SwiftMultiSelect.Show(to: self)
        }
    }

    func saveCommerceIdInUserDefaults() {
        // Met dans le UserDefaults + ajoute une notification au moment écoulé
        HelperAndKeys.setSharingTime(forCommerceId: self.commerce.objectId)
        // Met à jour les données dans la BDD distante
        if let user = PFUser.current() {
            HelperAndKeys.saveStatsInDb(commerce: self.commerce.pfObject, user: user)
        }
        self.updateCommerce()
    }

    func updateCommerce() {
        if let routeId = commerce.objectId {
            let query = PFQuery(className: "Commerce")
            query.whereKey("objectId", equalTo: routeId)
            query.getFirstObjectInBackground { (object, error) in
                if let commerce = object {
                    commerce.incrementKey("nombrePartages")
                    commerce.saveInBackground()
                } else if let error = error {
                    ParseErrorCodeHandler.handleUnknownError(error: error)
                }
            }
        }

    }

    func sendSMSForItems(groupe: GroupePartage) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = self.strPartage
            controller.recipients = groupe.numerosDesMembres
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Aucune application d'envoi d'SMS n'est configuré sur votre téléphone.".localized(), title: "Erreur d'envoi du message".localized(), viewController: self)
        }
    }

}

extension ListeDesFavorisVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return listeGroupes.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 90 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupePartageTVCell", for: indexPath) as! GroupePartageTVCell
        let groupe = listeGroupes[indexPath.row]
//        cell.groupe = listeGroupes[indexPath.row]
//        cell.imageGroupe.image = StyleKitWeeclik.imageOfPartageGroupe_icon(imageSize: CGSize(width: 240, height: 240), first: UIImage(named: "Placeholder_carre")!, second: UIImage(named: "Alimentaire")!)
//        cell.nombreMembresLabel.text = "\(listeGroupes[indexPath.row].getCapacityDescription())"
        cell.imageGroupe.image      = groupe.imageGroupe // TODO: Remplacer par la methode Paintcode
        cell.nomGroupeLabel.text       = groupe.nomGroupe
        cell.descriptionGroupeLabel.text = groupe.descriptionGroupe
        cell.imageGroupe.layer.cornerRadius = cell.imageGroupe.frame.size.width / 2

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.sendSMSForItems(groupe: listeGroupes[indexPath.row])
    }
}
extension ListeDesFavorisVC: SwiftMultiSelectDelegate {
    // User completed selection
    func swiftMultiSelect(didSelectItems items: [SwiftMultiSelectItem]) {
        newGroupe = GroupePartage(FromSwiftMultiSelectItems: self.groupName, imageGr: self.imageG, items: items)
        UserDefaultsManager.shared.addSharingGroup(groupe: newGroupe)
        listeGroupes.append(newGroupe)
        listeGroupesFavoris.reloadData()
    }
    // Number maximum of contact selected
    func numberMaximumOfItemsReached(items: [SwiftMultiSelectItem]) {
        print("Maximum number (\(Config.maxSelectItems)) of items reached")
        HelperAndKeys.showAlertWithMessage(theMessage: "Vous avez atteint le nombre maximum de membre d'un groupe (\(Config.maxSelectItems)). Essayez de créer un second groupe de diffusion par SMS.".localized(), title: "Nombre maximum atteint".localized(), viewController: self)
    }
    // User write something in searchbar
    func userDidSearch(searchString: String) {}
    // User did unselect an item
    func swiftMultiSelect(didUnselectItem item: SwiftMultiSelectItem) {}
    // User did select an item
    func swiftMultiSelect(didSelectItem item: SwiftMultiSelectItem) {}
    // User did close controller with no selection
    func didCloseSwiftMultiSelect() {}
}
extension ListeDesFavorisVC: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled, .failed:
            print(result)
        case .sent:
            saveCommerceIdInUserDefaults()
        @unknown default:
            print("New unknown value for MFMessage result")
        }
        dismiss(animated: true, completion: nil)
    }
}
