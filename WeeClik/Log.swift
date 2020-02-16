//
//  Logger.swift
//  WeeClik
//
//  Created by Herrick Wolber on 05/02/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import SwiftyBeaver

struct Log {
    // log to platform and console
    static let all = Log.enableDestination(console: true, platform: true)
    static let console = Log.enableDestination(console: true, platform: false)

    private static func enableDestination(console: Bool, platform: Bool) -> SwiftyBeaver.Type {

        let logger = SwiftyBeaver.self

        if console {
            logger.addDestination(ConsoleDestination())
        }

        if platform {
            let platformDestination = SBPlatformDestination(
                appID: "wg7X3p",
                appSecret: "3EcckRNz8tjnKd2Gie5kd8oczv5gwl22",
                encryptionKey: "kcdeu1zfyq7Kpvrm9B6XakrQszmuwyqu"
            )
            logger.addDestination(platformDestination)
        }

        return logger
    }
}
