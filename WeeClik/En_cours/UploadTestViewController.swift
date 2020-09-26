//
//  UploadTestViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 11/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit
import Bugsnag

class UploadTestViewController: UIViewController {
    
    var progressBarTimer: Timer!
    var isRunning = false
    var progress: Float = 0
    
    @IBAction func uploadAction(_ sender: Any) {
        shareCommerceViaServerAPI()
    }
    
    func shareCommerceViaServerAPI() {
        let commerceID = "0HaXnEwBpz"
        let userID = "5j7pwQ9y1F"
        ParseHelper.shareCommerce(commereId: commerceID, from: userID) { (error) in
            if let error = error {
                // Did fail
                Log.all.error("Sharing of commerce Failed: HTTP \(error.debug)")
                let exeption = NSException(name: NSExceptionName(rawValue: "APIError"),
                                           reason: "Error debut: \(error.debug)", userInfo: nil)
                Bugsnag.notify(exeption)
                
                switch error {
                case .commerceNotFound:
                    HelperAndKeys.showNotification(type: "E", title: "Erreur", message: "Le commerce associé n'est plus disponible".localized(), delay: 3)
                case .savingCommerceDidFail:
                    HelperAndKeys.showNotification(type: "E", title: "Erreur", message: "Erreur de chargement du commerce", delay: 3)
                case .userNotFound:
                    HelperAndKeys.showNotification(type: "E", title: "Erreur", message: "Erreur de chargement de votre compte", delay: 3)
                case .missingSharingInfos, .unknowError, .savingUserDidFail:
                    HelperAndKeys.showNotification(type: "E", title: "Erreur", message: "Une erreur inconnue est survenue", delay: 3)
                default:
                    HelperAndKeys.showNotification(type: "E", title: "Erreur", message: "Une erreur inconnue est survenue", delay: 3)
                }
            } else {
                // Met dans le UserDefaults + ajoute une notification au moment écoulé
                HelperAndKeys.setSharingTime(forCommerceId: commerceID)
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
