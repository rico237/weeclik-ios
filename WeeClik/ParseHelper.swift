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

struct ParseHelper {
    static func getUserACL(forUser user: PFUser?) -> PFACL {
        let acl = PFACL()
        acl.setReadAccess(true, forRoleWithName: "Public")
        acl.setReadAccess(true, forRoleWithName: "admin")
        acl.setWriteAccess(false, forRoleWithName: "Public")
        acl.setWriteAccess(true, forRoleWithName: "admin")
        if let user = user {
            acl.setReadAccess(true, for: user)
            acl.setWriteAccess(true, for: user)
        }

        return acl
    }

    static func rewriteParseURLForVideos(forURL url: URL) -> URL { // !!!: pb de lecture de vidéos
        // Depart   : https://weeclik-server.herokuapp.com/parse/files/JVQZMCuNYvnecPWvWFDTZa8A/326491c13ec62d56fd31ca41caf7401d_file.mp4
        // Objectif : https://storage.googleapis.com/weeclik-1517332083996.appspot.com/baas_files/326491c13ec62d56fd31ca41caf7401d_file.mp4
        var originalString = url.absoluteString
        if let parseURLRange = originalString.range(of: "\(Constants.Server.serverURL())/files/\(Constants.Server.serverAppId)/") {
            if let fireBaseServerURL: String = Constants.Plist.getDataForKey(key: "DATABASE_URL", type: .firebase) {
                originalString.replaceSubrange(parseURLRange, with: "https://storage.googleapis.com/\(fireBaseServerURL)/baas_files/")
            } else {
                originalString.replaceSubrange(parseURLRange, with: "https://storage.googleapis.com/weeclik-1517332083996.appspot.com/baas_files/")
            }
            return URL(string: originalString) ?? url
        }
        return url
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

        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        present(playerViewController, animated: true) {player.play()}
    }
}
