//
//  ProgressViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 10/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

class ProgressViewController: UIViewController {
    
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var progressIndicatorLabel: UILabel!
    @IBOutlet var progressDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Change height
        progressBar.transform = progressBar.transform.scaledBy(x: 1, y: 4)
        // Change corner radius
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.layer.sublayers![1].cornerRadius = 4
        progressBar.subviews.first?.clipsToBounds = true
    }
}
