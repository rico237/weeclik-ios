//
//  ParseHelper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 24/06/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

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
}
