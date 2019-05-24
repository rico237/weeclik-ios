//
//  BackendDetailCommerceVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 02/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import TLPhotoPicker
import Photos
import AVKit
import SVProgressHUD


class BackendDetailCommerceVC: UITableViewController {
    
    var photoArray : [UIImage]! = [#imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon"), #imageLiteral(resourceName: "Plus_icon")]      // Tableau de photos
    var videoArray = [TLPHAsset]()                  // Tableau de videos
    var thumbnailArray : [UIImage] = [UIImage()]    // Tableau de preview des vidéos
    var selectedVideoData = Data()                  // Data de vidéos
    
    var passedCommerceId : String!
    var passedCommerceObj : Commerce? = nil
    var passedCommerceParse : PFObject? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if passedCommerceId != nil && !passedCommerceId.isEmpty && passedCommerceId != ""{
            passedCommerceObj = Commerce(objectId: passedCommerceId)
        } else if let passedCommerceParse = passedCommerceParse {
            passedCommerceObj = Commerce(parseObject: passedCommerceParse)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
