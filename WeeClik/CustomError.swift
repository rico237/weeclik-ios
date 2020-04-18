//
//  CustomError.swift
//  WeeClik
//
//  Created by Herrick Wolber on 18/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

enum CustomError: Error {
    case encodingVideo
    
    var localizedDescription: String {
        switch self {
        case .encodingVideo:
            return NSLocalizedString("Error while fetching video data", comment: "Fetching video data error")
        }
    }
}
