//
//  Log.swift
//  WeeClik
//
//  Created by Herrick Wolber on 05/02/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit
import SwiftyBeaver

struct Logger {
    // log to platform and console
    static let everything = Logger.enableDestination(console: true, platform: true)
    
    enum Level {
        case verbose
        case debug
        case info
        case warning
        case error
    }
    
    enum `Type` { // Not used for now
        case everything
        case console
        case platform
        
        var logger: SwiftyBeaver.Type {
            switch self {
            case .everything:
                return Logger.enableDestination(console: true, platform: true)
            case .console:
                return Logger.enableDestination(console: true, platform: false)
            case .platform:
                return Logger.enableDestination(console: false, platform: true)
            }
        }
    }
    
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
    
    static func logEvent(for controller: String, message: String, level: Level) {
        let content = "[\(controller)]: \(message)"
        
        switch level {
        case .verbose:
            everything.verbose(content)    // prio 1, VERBOSE in silver, not so important
        case .debug:
            everything.debug(content)      // prio 2, DEBUG in green, something to debug
        case .info:
            everything.info(content)       // prio 3, INFO in blue, a nice information
        case .warning:
            everything.warning(content)    // prio 4, WARNING in yellow, oh no, that won't be good
        case .error:
            everything.error(content)      // prio 5, ERROR in red, ouchn an error did occur!
        }
    }
}
