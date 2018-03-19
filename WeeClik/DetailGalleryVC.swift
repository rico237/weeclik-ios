//
//  DetailGalleryVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 09/03/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import Material
import DZNEmptyDataSet

class DetailGalleryVC: UIViewController {

    @IBOutlet weak var segmentedControl: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let titles = ["Photos", "Vidéos"]
    fileprivate var buttons = [TabItem]()
    fileprivate var tabBar: TabBar!
    var shdShowVideos = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CollectionView Init
        collectionView.register(UINib(nibName:"PhotosVideosCollectionCell", bundle: nil) , forCellWithReuseIdentifier: "Photos/Videos-Cell")
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        
        // Segmented Control Init - (Choix Photos/Videos)
        prepareButtons()
        prepareTabBar()
    }
    
    func refreshViewWithSelectedInput(selectedInput : Int){
        // Photos = 0 & Videos = 1
        if selectedInput == 0 {shdShowVideos = false}
        else if selectedInput == 1 {shdShowVideos = true}
        self.collectionView.reloadData()
    }
}

extension DetailGalleryVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellsPerRow = 3
        let minimumInteritemSpacing = 3
        let marginsAndInsets = CGFloat(minimumInteritemSpacing) * CGFloat(cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !shdShowVideos {
            return 0
        }
        return 25
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Photos/Videos-Cell", for: indexPath) as! PhotosVideosCollectionCell
        
        if !shdShowVideos {
            cell.minuteViewContainer.isHidden = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

extension DetailGalleryVC : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    // DataSource
    
    // Image
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Empty_media_state")
    }
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var attributedStr = "Aucune "
        if self.shdShowVideos {
            attributedStr.append("vidéo")
        } else {
            attributedStr.append("photo")
        }
        attributedStr.append(" trouvé pour ce commercant")
        let attributs : [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.font : UIFont(name: "OpenSans-Regular", size: 18) as Any
        ]
        return NSAttributedString(string: attributedStr)
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var attributedStr = "Ce commercant n'a pas encore ajouté de "
        if self.shdShowVideos {
            attributedStr.append("vidéo")
        } else {
            attributedStr.append("photo")
        }
        attributedStr.append(" de son commerce")
        let attributs : [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.font : UIFont(name: "OpenSans-Regular", size: 10) as Any
        ]
        return NSAttributedString(string: attributedStr)
    }
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return UIColor.init(hex: "#F0F3F5")
    }
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: "Envoyer")
    }
//    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
//
//    }
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        print("TAP")
    }
}

extension DetailGalleryVC : TabBarDelegate {
    
    fileprivate func prepareButtons(){
        for titleStr in titles {
            let btn = TabItem(title: titleStr, titleColor: Color.blueGrey.base)
            btn.pulseAnimation = .none
            buttons.append(btn)
        }
    }
    
    fileprivate func prepareTabBar(){
        tabBar = TabBar()
        tabBar.delegate = self
        
        tabBar.dividerColor = Color.grey.lighten2
        tabBar.dividerAlignment = .top
        
        tabBar.lineColor = UIColor.init(hex: "#2BB1F2")
        tabBar.lineAlignment = .bottom
        
        tabBar.backgroundColor = Color.grey.lighten5
        tabBar.tabItems = buttons
        
        view.layout(tabBar).horizontally().top(0)
    }
    
    @objc func tabBar(tabBar: TabBar, willSelect tabItem: TabItem) {
        self.refreshViewWithSelectedInput(selectedInput: self.titles.index(of: tabItem.title!)!)
    }
    
//    @objc func tabBar(tabBar: TabBar, didSelect tabItem: TabItem) {}
}
