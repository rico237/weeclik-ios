//
//  FileUploadProgressView.swift
//  WeeClik
//
//  Created by Herrick Wolber on 13/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

/*
    progressTintColor – UIColor of the filled part in the ProgressView.
    trackTintColor – UIColor of the unfilled part of the ProgressView.
    ProgressBarStyle – styles: default and bar. The bar style has a transparent track.
*/

final class FileUploadProgressView: NibLoadingView {
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var progressIndicatorLabel: UILabel!
    @IBOutlet var progressDescriptionLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        progressBar.tintColor = .main
        // Change height
        progressBar.transform = progressBar.transform.scaledBy(x: 1, y: 4)
        // Change corner radius
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.layer.sublayers![1].cornerRadius = 4
        progressBar.subviews.first?.clipsToBounds = true
    }
}
