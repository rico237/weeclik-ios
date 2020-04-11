//
//  FileUploadManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 10/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

/*
 progressTintColor – Used to change the UIColor of the progress part i.e. the filled part in the ProgressView.
 trackTintColor – Used to change the UIColor of the track i.e. the unfilled part of the ProgressView.
 ProgressBarStyle – There are two styles: default and bar. The bar style has a transparent track.
 */

final class FileUploadManager: NSObject {
    var preferedPosition: Position = .top
    static let shared = FileUploadManager()

    enum Position {
        case top
        case bottom
    }

    private var animationDuration: TimeInterval = 0.5
    private var currentProgress: Float = 0
    private var progressViewController: ProgressViewController = ProgressViewController(nibName: "ProgressViewController", bundle: nil)
    private var parentViewController: UIViewController?
    private var offset: CGFloat {
        guard let firstWindow = UIApplication.shared.windows.first else { return 0 }
        
        switch preferedPosition {
        case .top:
            if let parentViewController = parentViewController,
                let navigationHeight = parentViewController.navigationController?.navigationBar.frame.height {
                return firstWindow.safeAreaInsets.top + navigationHeight
            }
            return firstWindow.safeAreaInsets.top
        case .bottom:
            return firstWindow.safeAreaInsets.bottom
        }
    }
    private var isPresented = false

    private override init() {}

    func updateProgress(to number: Float) {
        let progress = number / 100
        progressViewController.progressBar.progress = progress
        currentProgress = progress
        
        progressViewController.progressIndicatorLabel.text = "\(Int(number))%".localized()
        progressViewController.progressDescriptionLabel.text = "Envoi de votre vidéo en cours".localized()
        
        if currentProgress >= 1.0 {
            progressViewController.progressDescriptionLabel.text = "Envoi de votre vidéo terminé".localized()
            hide()
        }
    }
    
    func show(in parentViewController: UIViewController) {
        guard let parent = UIWindow.getVisibleViewControllerFrom(parentViewController), isPresented == false else { return }
        isPresented = true
        parent.modalPresentationStyle = .popover
        parent.present(progressViewController, animated: true, completion: nil)
        
        progressViewController.view.frame = CGRect(x: 0,
                                                   y: parentViewController.view.frame.size.height,
                                                   width: progressViewController.view.frame.size.width,
                                                   height: 92)
        let frame = progressViewController.view.frame
        var newFrame = frame
        switch preferedPosition {
        case .top:
            newFrame.origin.y += frame.size.height + offset
        case .bottom:
            newFrame.origin.y -= frame.size.height - offset
        }
        
        // Animation
        UIView.animate(withDuration: animationDuration, animations: {
            self.progressViewController.view.frame = newFrame
        }, completion: nil)
    }
    
    private func hide() {
        
        let frame = progressViewController.view.frame
        var newFrame = frame
        switch preferedPosition {
        case .top:
            newFrame.origin.y -= frame.size.height - self.offset
        case .bottom:
            newFrame.origin.y += frame.size.height + self.offset
        }
        
        // Wait 2 seconds and hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Animation
            UIView.animate(withDuration: self.animationDuration, animations: {
                self.progressViewController.view.frame = newFrame
            }, completion: { (_ completed) in
                self.updateProgress(to: 0)
                self.progressViewController.dismiss(animated: true, completion: nil)
                self.isPresented = false
            })
        }
    }
}
