//
//  ParseHelper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 24/06/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import AVKit
//import Alamofire

struct ParseHelper {
    static func getUserACL(forUser user: PFUser) -> PFACL {
        let acl = PFACL()
        acl.setReadAccess(true, forRoleWithName: "admin")
        acl.setWriteAccess(true, forRoleWithName: "admin")
        acl.hasPublicReadAccess = true
        acl.hasPublicWriteAccess = false
        acl.setReadAccess(true, for: user)
        acl.setWriteAccess(true, for: user)

        return acl
    }

    static func rewriteParseURLForVideos(forURL url: URL) -> URL {
        // swiftlint:disable line_length
        // Depart   : https://weeclik-server.herokuapp.com/parse/files/JVQZMCuNYvnecPWvWFDTZa8A/326491c13ec62d56fd31ca41caf7401d_file.mp4
        // Objectif : https://firebasestorage.googleapis.com/v0/b/weeclik-1517332083996.appspot.com/o/baas_files%2F326491c13ec62d56fd31ca41caf7401d_file.mp4?alt=media
        // swiftlint:enable line_length
        var originalString = url.absoluteString
        if let parseURLRange = originalString.range(of: "\(Constants.Server.serverURL)/files/\(Constants.Server.serverAppId)/") {
            originalString.replaceSubrange(parseURLRange, with: "https://firebasestorage.googleapis.com/v0/b/weeclik-1517332083996.appspot.com/o/baas_files%2F")
            originalString += "?alt=media"
            return URL(string: originalString) ?? url
        }
        return url
    }
    
//    /// User did share commerce - post https://weeclik-server-dev.herokuapp.com/share
//    static func shareCommerceAlamoFire(commereId: String, fromUser userId: String, completion: @escaping ((_ error: Error?) -> Void)) {
//        // Add Headers
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json; charset=utf-8"
//        ]
//        // JSON Body
//        let body: [String: Any] = [
//            "userId": userId,
//            "commerceId": commereId
//        ]
//        // Fetch Request
//        AF.request(Constants.Server.sharingURL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers, interceptor: nil, requestModifier: nil)
//            .validate(statusCode: 200..<500)
//            .responseJSON { (response) in
//
//                switch response.result {
//                case .success:
//                    Log.all.info("Commerce has been update successfuly")
//                    Log.all.info("HTTP Response Body: \(String(describing: response.description))")
//                    completion(nil)
//
//                case .failure(let error):
//                    Log.all.error("An error occured: \(error.debug)")
//                    Log.all.error("URL Session Task Failed: HTTP \(error.code)")
//                    completion(error)
//                }
//        }
//    }
    
    /// User did share commerce - post https://weeclik-server-dev.herokuapp.com/share
    static func shareCommerce(commereId: String, fromUserId userId: String, completion: @escaping ((_ error: APIError?) -> Void)) {
        guard let URL = URL(string: Constants.Server.sharingURL) else { return }
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        // Headers
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        // JSON Body
        let bodyObject: [String: String] = [
            "userId": userId,
            "commerceId": commereId
        ]
        if let body = try? JSONSerialization.data(withJSONObject: bodyObject, options: []) {
            request.httpBody = body
        }
        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (_: Data?, response: URLResponse?, error: Error?) -> Void in
            if let error = error {
                // Failure
                completion(APIError.custom(error as NSError))
            } else if let httpURLResponse = response as? HTTPURLResponse {
                switch httpURLResponse.statusCode {
                case 200:
                    completion(nil)
                case 400:
                    completion(APIError.missingSharingInfos)
                case 401:
                    completion(APIError.savingCommerceDidFail)
                case 402:
                    completion(APIError.savingUserDidFail)
                case 403:
                    completion(APIError.commerceNotFound)
                case 404:
                    completion(APIError.userNotFound)
                default:
                    completion(APIError.unknowError)
                }
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

extension UIViewController {
    func showVideoPlayerWithVideoURL(withUrl url: URL, fromBAAS isLocal: Bool = false) {
        let player: AVPlayer!

        if isLocal {
            player = AVPlayer(url: url)
        } else {
            player = AVPlayer(url: ParseHelper.rewriteParseURLForVideos(forURL: url))
        }
        
        // Set the audio session to playback to ignore mute switch on device
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            // Didn't work
            Log.all.warning("playback ignore mute switch on device failed")
        }

        let playerViewController = AVPlayerViewController()
        player.isMuted = false
        player.volume = 1
        playerViewController.player = player
        present(playerViewController, animated: true) {
            player.play()
        }
    }
}
