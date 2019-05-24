//
//  ParseUploadPhotosAndVideos.swift
//  WeeClik
//
//  Created by Herrick Wolber on 05/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

enum MediaType {
    case Photos
    case Videos
}

@objc protocol ParseUploadPhotosAndVideosDelegate {
    @objc optional func didFinishUploadingPhotos()
    @objc optional func didFinishUploadingVideos()
}

/*
 
 TODO : search for way to implement boolean delegate methods for upload like parse
        with a boolean succes + error object that could be null
 */

class ParseUploadPhotosAndVideos: NSObject {
    weak var delegate : ParseUploadPhotosAndVideosDelegate?
    
    func uploadPhotosOrVidosToParseDB(mediasToUpload : [PFObject], commerceToUploadTo : PFObject, mediaType: MediaType) {
        switch mediaType {
        case .Photos:
            handlePhotosUpload(mediasToUpload: mediasToUpload, commerceToUploadTo: commerceToUploadTo)
            break
        case .Videos:
            handleVideosUpload(mediasToUpload: mediasToUpload, commerceToUploadTo: commerceToUploadTo)
            break
        }
    }
    
    func handlePhotosUpload(mediasToUpload : [PFObject], commerceToUploadTo : PFObject){
        // TODO: Save photos to commerce and return result, error or success
    }
    
    func handleVideosUpload(mediasToUpload : [PFObject], commerceToUploadTo : PFObject) {
        // TODO: Save videos to commerce and return result, error or success for now limit to one video
        
    }
}
