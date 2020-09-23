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
        shareCommerceViaServerAPI()
    }
    
    func shareCommerceViaServerAPI() {
        ParseHelper.shareCommerce(commereId: "0HaXnEwBpz", fromUserId: "5j7pwQ9y1F") { (error) in
            if let error = error {
                // Did fail
                Log.all.error("Sharing of commerce Failed: HTTP \(error.debug)")
            } else {
                // Did succeded
                Log.all.info("Sharing did succeed")
            }
        }
    }
    
    func testUploadingFile() {
        if (isRunning) {
            progressBarTimer.invalidate()
        } else {
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
