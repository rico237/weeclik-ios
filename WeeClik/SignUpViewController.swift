//
//  SignUpViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 24/12/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

class SignUpViewController: PFSignUpViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.signUpView?.logo = UIImageView(image: UIImage(named: "icon"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.signUpView?.logo?.frame = CGRect(x: (self.signUpView?.logo?.frame.origin.x)!, y: (self.signUpView?.logo?.frame.origin.y)! - 83, width: 167, height: 167)
    }
}
