//
//  UploadTestViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 11/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

class UploadTestViewController: UIViewController {
    
    var progressBarTimer: Timer!
    var isRunning = false
    var progress: Float = 0
    
    @IBAction func uploadAction(_ sender: Any) {
        if (isRunning) {
            progressBarTimer.invalidate()
        } else {
            FileUploadManager.shared.preferedPosition = .top
            FileUploadManager.shared.show(in: self)
            
            progressBarTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgressView), userInfo: nil, repeats: true)
        }
        isRunning = !isRunning
    }
    
    @objc func updateProgressView() {
        progress += 1
        
        FileUploadManager.shared.updateProgress(to: progress)
        
        if (progress >= 100) {
            progressBarTimer.invalidate()
            isRunning = false
            progress = 0
        }
    }
}
