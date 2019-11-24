//
//  Extension+PHAsset.swift
//  WeeClik
//
//  Created by Herrick Wolber on 01/11/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import Photos
import WXImageCompress
import SVProgressHUD

extension PHAsset {
    func imageRepresentation(completion: @escaping (_ image: UIImage?, _ data: Data?, _ error: Error?) -> Void) {
        print("\nWith compression\n")
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.version = .current
        options.resizeMode = .exact
        options.progressHandler = { (progress, error, stop, info) in
            if let error = error {
                completion(nil, nil, error)
            } else {
                SVProgressHUD.showProgress(Float(progress), status: "Chargement de la photo".localized())
            }
        }
        
        PHCachingImageManager().requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, _) in
            if let image = image, let data = image.wxCompress().jpegData(compressionQuality: 1) {
                completion(image.wxCompress(), data, nil)
            }
        }
    }
    
    func videoThumbnailImage(progressHandler: (_ progress: Double, _ error: Error?) -> Void,
                             completion: (_ data: Data, _ error: Error?) -> Void) {
//        print("\nWith compression\n")
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.deliveryMode = .fastFormat
        videoRequestOptions.version = .original
        videoRequestOptions.isNetworkAccessAllowed = true
        videoRequestOptions.progressHandler = { (progress, error, stop, info) in
            SVProgressHUD.showProgress(Float(progress), status: "Chargement de la vidéo".localized())
        }

//        PHImageManager().requestAVAsset(forVideo: self, options: videoRequestOptions, resultHandler: { (avaAsset, _, _) in
//            if let successAvaAsset = avaAsset {
//                let generator = AVAssetImageGenerator(asset: successAvaAsset)
//                generator.appliesPreferredTrackTransform = true
//
//                let myAsset = successAvaAsset as? AVURLAsset
//                do {
//                    let videoData = try Data(contentsOf: (myAsset?.url)!)
//                    self.selectedVideoData = videoData  //Set video data to nil in case of video
//                } catch let error as NSError {
//                    self.handleLoadingExceptions(forPhoto: false, withError: error)
//                }
//
//                do {
//                    let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
//                    let imageRef  = try generator.copyCGImage(at: timestamp, actualTime: nil)
//                    let thumbnail = UIImage(cgImage: imageRef).wxCompress()
//                    self.refreshCollectionWithDataForVideo(thumbnail: thumbnail)
//                } catch let error as NSError {
//                    self.handleLoadingExceptions(forPhoto: true, withError: error)
//                }
//            }
//        })
    }
}
