//
//  GroupePartage.swift
//  WeeClik
//
//  Created by Herrick Wolber on 20/09/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import SwiftMultiSelect
import Contacts

@objc(GroupePartage)
class GroupePartage: NSObject, NSCoding {

    var nomGroupe           : String = ""
    var descriptionGroupe   : String = ""
    var imageGroupe         = UIImage(named: "Placeholder_carre") ?? UIImage()
    var nombreMembre        : Int = 0
    var numerosDesMembres   : [String]

    init(FromSwiftMultiSelectItems nomGroupe: String, imageGr: UIImage? = nil, items :[SwiftMultiSelectItem]) {

        self.nomGroupe = nomGroupe
        if let image = imageGr {self.imageGroupe = image}
        self.nombreMembre = items.count

        var membresPhones = [String]()
        var membresName   = [String]()
//        var emailAdresses = [String]()

        for item: SwiftMultiSelectItem in items {
            // Nom Prénom du caontact
            membresName.append(item.title)

            // Si le contact possède une image && l'image du groue n'est pas déja existante
            // Alors on assigne une image
            if item.image != nil {
                self.imageGroupe = item.image!
            }

            if let userInfo = item.userInfo as? CNContact {
                // TODO: Intégration des adresse mail
//                for email in userInfo.emailAddresses {
//                    print(email.value)
//                    emailAdresses.append(email.value as String)
//                    break
//                }

                print("All \(item.title) numbers : \(userInfo.phoneNumbers.count)")

                for ContctNumVar: CNLabeledValue in userInfo.phoneNumbers {
                    //  let label = ContctNumVar.label  // Label : CNLabelPhoneNumberiPhone, CNLabelPhoneNumberMobile, CNLabelPhoneNumberMain
                    let FulMobNumVar    = ContctNumVar.value
                    let MccNamVar       = FulMobNumVar.value(forKey: "countryCode") as? String
                    let MobNumVar       = FulMobNumVar.value(forKey: "digits") as? String

                    if let country = MccNamVar {
                        if country == "fr" {
                            if let phoneNum = MobNumVar {
                                print("Append phone number : \(phoneNum)")
                                membresPhones.append(phoneNum)
                                break
                            }
                        }
                    }

                }

            }

        }
        self.numerosDesMembres = membresPhones
        self.descriptionGroupe = membresName.joined(separator: ", ")
    }

    // Encode
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(nomGroupe, forKey: "nomGroupeKey")
        aCoder.encode(descriptionGroupe, forKey: "descriptionGroupeKey")
        aCoder.encode(imageGroupe, forKey: "imageGroupeKey")
        aCoder.encode(nombreMembre, forKey: "nombreGroupeKey")
        aCoder.encode(numerosDesMembres, forKey: "membresGroupeKey")
    }
    // Decode
    required public init?(coder aDecoder: NSCoder) {
        nomGroupe = aDecoder.decodeObject(forKey: "nomGroupeKey") as! String
        descriptionGroupe = aDecoder.decodeObject(forKey: "descriptionGroupeKey") as! String
        imageGroupe = aDecoder.decodeObject(forKey: "imageGroupeKey") as! UIImage
        nombreMembre = aDecoder.decodeInteger(forKey: "nombreGroupeKey")
        numerosDesMembres = aDecoder.decodeObject(forKey: "membresGroupeKey") as! [String]
    }

    func getCapacityDescription() -> String {
        let double = Double(nombreMembre)
        let thousandNum = double/1000
        let millionNum = double/1000000

        if double >= 1000 && double < 1000000 {
            if(floor(thousandNum) == thousandNum) {
                return("\(Int(thousandNum))k")
            }
            return("\(thousandNum.round(to: 1))k")
        }
        if double > 1000000 {
            if(floor(millionNum) == millionNum) {
                return("\(Int(thousandNum))k")
            }
            return ("\(millionNum.round(to: 1))M")
        } else {
            if(floor(double) == double) {
                return ("\(Int(double))")
            }
            return ("\(double)")
        }
    }

    override var description: String {
        return "\nGroupe partage : \n\tNom du groupe : \(self.nomGroupe)\n\tDescription du groupe : \(self.descriptionGroupe)\n\tNombre de membres : \(nombreMembre)\n\tNuméros du groupe : \n\t\t\(self.numerosDesMembres)"
    }
}
