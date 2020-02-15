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
        acl.setReadAccess(true, forRoleWithName: "admin")
        acl.setWriteAccess(true, forRoleWithName: "admin")
        acl.hasPublicReadAccess = true
        acl.hasPublicWriteAccess = false
        if let user = user {
            acl.setReadAccess(true, for: user)
            acl.setWriteAccess(true, for: user)
        }

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
