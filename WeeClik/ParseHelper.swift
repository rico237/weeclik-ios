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

class ParseHelper {
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

    static func rewriteParseURLForVideos(forURL url: URL) -> URL {
        // Depart   : https://weeclik-server.herokuapp.com/parse/files/JVQZMCuNYvnecPWvWFDTZa8A/326491c13ec62d56fd31ca41caf7401d_file.mp4
        // Objectif : https://storage.googleapis.com/weeclik-1517332083996.appspot.com/baas_files/326491c13ec62d56fd31ca41caf7401d_file.mp4
        var originalString = url.absoluteString
        if let parseURLRange = originalString.range(of: "https://weeclik-server.herokuapp.com/parse/files/\(HelperAndKeys.getServerAppId())/") {
            originalString.replaceSubrange(parseURLRange, with: "https://storage.googleapis.com/weeclik-1517332083996.appspot.com/baas_files/")
            return URL(string: originalString) ?? url
        }
        return url
    }

    static func showVideoPlayerWithVideoURL(withUrl url: URL, fromBAAS isLocal: Bool = false, inViewController vc: UIViewController) {
        let player: AVPlayer!

        if isLocal {
            player = AVPlayer(url: url)
        } else {
            player = AVPlayer(url: self.rewriteParseURLForVideos(forURL: url))
        }

        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        vc.present(playerViewController, animated: true) {player.play()}
    }
}
