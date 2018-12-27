//
//  LoginViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 24/12/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

class LoginViewController: PFLogInViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.logInView?.logo = UIImageView(image: UIImage(named: "icon"))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.logInView?.logo?.frame = CGRect(x: (self.logInView?.logo?.frame.origin.x)!, y: (self.logInView?.logo?.frame.origin.y)! - 83, width: 167, height:167)
    }
}
