//
//  CustomError.swift
//  WeeClik
//
//  Created by Herrick Wolber on 18/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

enum APIError: Error {
    case missingSharingInfos
    case commerceNotFound
    case savingCommerceDidFail
    case userNotFound
    case savingUserDidFail
    
    case unknowError
    case custom(NSError)
    
    var statusCode: Int {
        switch self {
        case .missingSharingInfos:
            return 400
        case .commerceNotFound:
            return 403
        case .savingCommerceDidFail:
            return 401
        case .userNotFound:
            return 404
        case .savingUserDidFail:
            return 402
        case .unknowError:
            return 499
        case .custom(let error):
            return error.code
        }
    }
    var localizedDescription: String {
        switch self {
        case .commerceNotFound:
            return NSLocalizedString("Error while fetching commerce", comment: "Fetching commerce data error")
        case .savingCommerceDidFail:
            return NSLocalizedString("Error while updating/saving commerce data", comment: "Updating/saving commerce data error")
        case .userNotFound:
            return NSLocalizedString("Error while fetching user data", comment: "Fetching user data error")
        case .savingUserDidFail:
            return NSLocalizedString("Error while updating/saving user data", comment: "Updating/saving commerce data error")
        case .missingSharingInfos:
            return NSLocalizedString("Endpoint was called with missing informations", comment: "Missing parameters error")
        case .unknowError:
            return NSLocalizedString("Endpoint return an unhandled error", comment: "Unhandled error")
        case .custom(let error):
            return error.localizedDescription
        }
    }
    
    var debug: String {
        return """

            Error description :
                Code: \(statusCode)
                Description: \(localizedDescription)

        """
    }
}

enum CustomError: Error {
    case encodingVideo
    
    var localizedDescription: String {
        switch self {
        case .encodingVideo:
            return NSLocalizedString("Error while fetching video data", comment: "Fetching video data error")
        }
    }
    
    var debug: String {
        return """

            Error description :
                Description: \(localizedDescription)

        """
    }
}
