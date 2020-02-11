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
import SVProgressHUD
import AppImageViewer
import AVKit

class DetailGalleryVC: UIViewController {

    @IBOutlet weak var segmentedControl: UIView!
    @IBOutlet weak var collectionView: UICollectionView!

    var fetchedPhotos = [UIImage?]()

    var commerce: Commerce!
    var photos = [PFObject]()
    var videos = [PFObject]()

    let titles = ["Photos", "Vidéos"]

    fileprivate var buttons = [TabItem]()
    fileprivate var tabBar: TabBar!
    var shdShowVideos = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Gallerie".localized()

        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setDefaultStyle(.dark)

        // CollectionView Init
        collectionView.register(UINib(nibName: "PhotosVideosCollectionCell", bundle: nil), forCellWithReuseIdentifier: "Photos/Videos-Cell")
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self

        // Segmented Control Init - (Choix Photos/Videos)
        prepareButtons()
        prepareTabBar()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queryMedias()
    }

    func queryMedias() {
        SVProgressHUD.show(withStatus: "Chargement des images et vidéos du commerce".localized())
        self.fetchPhotos()
    }

    func fetchPhotos() {
        guard let parseCommerce = self.commerce.pfObject else {return}

        let queryPhotos = PFQuery(className: "Commerce_Photos")
        queryPhotos.whereKey("commerce", equalTo: parseCommerce)
        queryPhotos.addDescendingOrder("updatedAt")

        queryPhotos.findObjectsInBackground(block: { (objects, error) in
            if let error = error {
                print("Erreur Chargement Photos DetailGalleryVC")
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else {
                // Success
                self.photos = objects!
                for photo in self.photos {
                    if let file = photo["photo"] as? PFFileObject,
                        let data = try? file.getData(),
                        let image = UIImage(data: data) {
                        self.fetchedPhotos.append(image)
                    }
                }
            }
            self.fetchVideos()
        })
    }

    func fetchVideos() {
        guard let parseCommerce = self.commerce.pfObject else {return}

        let queryVideos = PFQuery(className: "Commerce_Videos")
        queryVideos.whereKey("leCommerce", equalTo: parseCommerce)
        queryVideos.addDescendingOrder("updatedAt")

        queryVideos.findObjectsInBackground { (objects, error) in
            if let error = error {
                print("Erreur Chargement Videos DetailGalleryVC")
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else {
                self.videos = objects ?? []
            }
            SVProgressHUD.dismiss(withDelay: 1)
            self.refreshCollection()
        }
    }

    func refreshViewWithSelectedInput(selectedInput: Int) {
        // Photos = 0 & Videos = 1
        if selectedInput == 0 {shdShowVideos = false} else if selectedInput == 1 {shdShowVideos = true}
        refreshCollection()
    }

    func refreshCollection() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

extension DetailGalleryVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellsPerRow = 3
        let minimumInteritemSpacing = 3
        let marginsAndInsets = CGFloat(minimumInteritemSpacing) * CGFloat(cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !shdShowVideos {
            // Photos
            return photos.count
        }
        // Videos
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Photos/Videos-Cell", for: indexPath)
        guard let cell = dequeuedCell as? PhotosVideosCollectionCell else { return UICollectionViewCell() }

        var object: PFObject!
        var file: PFFileObject?

        if !shdShowVideos {
            // Photos
            object = photos[indexPath.row]
            file = object["photo"] as? PFFileObject
            cell.minuteViewContainer.isHidden = true
        } else {
            object = videos[indexPath.row]
            cell.timeLabel.text = object["time"] as? String
            if let thumb = object["thumbnail"] as? PFFileObject {
                file = thumb
            }
            cell.minuteViewContainer.isHidden = false
        }

        let placeholderImage = UIImage(named: "Placeholder_carre")
        if let file = file, let urlStr = file.url {
            cell.imagePlaceholder.sd_setImage(with: URL(string: urlStr), placeholderImage: placeholderImage, options: .highPriority, completed: nil)
        } else {
            cell.imagePlaceholder.image = placeholderImage
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if !shdShowVideos {
            // Photos
            var images = [ViewerImageProtocol]()
            var originImage = UIImage()
            for (index, photo) in fetchedPhotos.enumerated() {
                if let image = photo {
                    if index == indexPath.row { originImage = image }
                    images.append(ViewerImage.appImage(forImage: image))
                }
            }

            let viewer = AppImageViewer(originImage: originImage, photos: images, animatedFromView: view)
            viewer.currentPageIndex = indexPath.row
            present(viewer, animated: true, completion: nil)
        } else {
            // Videos
            let parseObject = self.videos[indexPath.row]
            let videoFile = parseObject["video"] as! PFFileObject
            
            // TODO : Optimize for NS/InputStream object reading = charge video section by section = better loading
            // let v = videoFile.getDataStreamInBackground()
            if let url = URL(string: videoFile.url!) {
                showVideoPlayerWithVideoURL(withUrl: url)
            } else {
                showAlertWithMessage(message: "Un problème est arrivé lors du chargement de la vidéo".localized(), title: "Erreur de chargement".localized(), completionAction: nil)
            }
        }
    }
}

extension DetailGalleryVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
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
        return NSAttributedString(string: attributedStr.localized())
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var attributedStr = "Ce commercant n'a pas encore ajouté de "
        if shdShowVideos {
            attributedStr.append("vidéo")
        } else {
            attributedStr.append("photo")
        }
        attributedStr.append(" de son commerce")
        return NSAttributedString(string: attributedStr.localized())
    }
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0)
    }

// TODO: envoyer mail au commercant pour qu'il ajoute du contenu
//    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
//        return NSAttributedString(string: "Envoyer")
//    }
//    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
//
//    }
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        print("TAP")
    }
}

extension DetailGalleryVC: TabBarDelegate {

    fileprivate func prepareButtons() {
        for titleStr in titles {
            let sectionBouton = TabItem(title: titleStr, titleColor: Color.blueGrey.base)
            sectionBouton.pulseAnimation = .none
            buttons.append(sectionBouton)
        }
    }

    fileprivate func prepareTabBar() {
        tabBar = TabBar()
        tabBar.delegate = self

        tabBar.dividerColor = Color.grey.lighten2
        tabBar.dividerAlignment = .top

        tabBar.lineColor = UIColor(red: 0.17, green: 0.69, blue: 0.95, alpha: 1.0)
        tabBar.lineAlignment = .bottom

        tabBar.backgroundColor = Color.grey.lighten5
        tabBar.tabItems = buttons

        view.layout(tabBar).horizontally().top(0)
    }

    @objc func tabBar(tabBar: TabBar, willSelect tabItem: TabItem) {
        refreshViewWithSelectedInput(selectedInput: titles.firstIndex(of: tabItem.title!)!)
    }
}
