//
//  ParseUploadPhotosAndVideos.swift
//  WeeClik
//
//  Created by Herrick Wolber on 05/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

@objc protocol ParseUploadPhotosAndVideosDelegate {
    @objc optional func didFinishUploadingPhotos()
//    @objc optional func didFinishUploadingVideos()
}

class ParseUploadPhotosAndVideos: NSObject {
    weak var delegate : ParseUploadPhotosAndVideosDelegate?
    
    func uploadPhotosToParseDB(photosToUpload : [PFObject], commerceToUploadTo : PFObject) {
        
    }
}
