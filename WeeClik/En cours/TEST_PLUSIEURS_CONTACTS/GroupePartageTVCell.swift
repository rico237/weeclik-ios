//
//  GroupePartageTVCell.swift
//  WeeClik
//
//  Created by Herrick Wolber on 20/09/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit

class GroupePartageTVCell: UITableViewCell {

    @IBOutlet weak var imageGroupe: UIImageView!
    @IBOutlet weak var nomGroupeLabel: UILabel!
    @IBOutlet weak var descriptionGroupeLabel: UILabel!
    @IBOutlet weak var nombreMembresLabel: UILabel!

//    var groupe: GroupePartage? {
//        didSet {
//            nomDuGroupe.text = groupe?.nomGroupe
//            descriptionGroupe.text = groupe?.descriptionGroupe
//            refreshImage()
//        }
//    }
//
//    private let imageGroupe : UIView = {
//        let view = UIView()
//        view.backgroundColor = .red
//        return view
//    }()
//
//    private let nomDuGroupe : UILabel = {
//        let lbl = UILabel()
//        lbl.textColor = .black
////        lbl.font = UIFont.systemFont(ofSize: 17)
//        lbl.font = UIFont.OpenSans(.bold, size: 17)
//        lbl.textAlignment = .left
//        lbl.numberOfLines = 1
//        return lbl
//    }()
//
//    private let descriptionGroupe : UILabel = {
//        let lbl = UILabel()
//        lbl.textColor = .black
//        lbl.font = UIFont.OpenSans(.light, size: 17)
//        lbl.textAlignment = .left
//        lbl.numberOfLines = 1
//        return lbl
//    }()
//
//    private let firstImage : UIImageView = {
//        let imgView = UIImageView(image: UIImage(named: "Placeholder_carre"))
//        imgView.contentMode = .scaleAspectFill
//        imgView.clipsToBounds = true
//        return imgView
//    }()
//    private let secondImage: UIImageView = {
//        let imgView = UIImageView(image: UIImage(named: "Bien-etre"))
//        imgView.contentMode = .scaleAspectFill
//        imgView.clipsToBounds = true
//        return imgView
//    }()
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        let stackView = UIStackView(arrangedSubviews: [nomDuGroupe, descriptionGroupe])
//        stackView.distribution = .equalSpacing
//        stackView.axis = .vertical
//        stackView.spacing = 0
//
//        addSubview(imageGroupe)
//        addSubview(stackView)
//
//
//        // Arrange UI
////        imageGroupe.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: stackView.leftAnchor, paddingTop: 8, paddingLeft: 20, paddingBottom: 8, paddingRight: 16, width: self.contentView.frame.size.height, height: self.contentView.frame.size.height, enableInsets: false)
//        imageGroupe.topAnchor.constraint(equalTo: topAnchor, constant: 8)
//        imageGroupe.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8)
//        imageGroupe.leftAnchor.constraint(equalTo: leftAnchor, constant: 20)
//        imageGroupe.widthAnchor.constraint(equalToConstant: contentView.frame.size.height).isActive = true
//        imageGroupe.heightAnchor.constraint(equalTo: imageGroupe.widthAnchor, multiplier: 1.0/1.0).isActive = true
//
//        stackView.anchor(top: topAnchor, left: imageGroupe.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 16, paddingBottom: -8, paddingRight: 8, width: 0, height: self.contentView.frame.size.height, enableInsets: false)
//
//        firstImage.layer.cornerRadius = contentView.frame.size.height / 2
//        secondImage.layer.cornerRadius = contentView.frame.size.height / 2
//
//        contentView.clipsToBounds = true
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func refreshImage(){
//        if let groupe = groupe {
//            print("Nombre de membre : \(groupe.nombreMembre) pour le groupe : \(groupe.nomGroupe)")
//            if groupe.nombreMembre > 1 {
//                print("Plusieur membres")
//                // Plus de deux membres
//                generateTwoImageGroup()
//            } else {
//                // Un seul membre
//                print("Un seul membre")
//                generateOneImageGroup()
//            }
//        } else {
//            generateOneImageGroup()
//        }
//    }
//    func generateOneImageGroup(){
//        imageGroupe.addSubview(firstImage)
//        firstImage.anchor(top: imageGroupe.topAnchor, left: imageGroupe.leftAnchor, bottom: imageGroupe.bottomAnchor, right: imageGroupe.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: contentView.frame.size.height, height: contentView.frame.size.height, enableInsets: false)
//    }
//
//    func generateTwoImageGroup(){
//        imageGroupe.addSubview(secondImage)
//        imageGroupe.addSubview(firstImage)
//
//        secondImage.frame = CGRect(x: self.imageGroupe.frame.size.width / 2, y: 0, width: self.imageGroupe.frame.size.width / 2, height: self.imageGroupe.frame.size.height / 2)
//        firstImage.frame = CGRect(x: self.imageGroupe.frame.size.width * 0.25, y: self.imageGroupe.frame.size.height * 0.25, width: self.imageGroupe.frame.size.width * 0.75, height: self.imageGroupe.frame.size.height * 0.7)
//    }
}
