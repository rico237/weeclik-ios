//
//  FileUploadManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 10/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit
import ZAlertView

final class FileUploadManager: Scheduler {
    static let shared = FileUploadManager()
    
    enum Position {
        case top
        case bottom
    }
    
    var currentProgress: Float = 0
    var didFinishUploading: Bool {
        return currentProgress >= 1.0
    }
    
    private var preferedPosition: Position {
        guard let parent = UIApplication.topViewController(), (parent as? AccueilCommerces) == nil else {
            return .bottom
        }
        return .top
    }
    private var animationDuration: TimeInterval = 0.25
    private var progressView: FileUploadProgressView = FileUploadProgressView(frame: .zero)
    private var parentViewController: UIViewController? {
        return UIApplication.topViewController()
    }
    private var progressViewHeight: CGFloat = 92
    private var topSafeMargin: CGFloat {
        guard let parent = UIApplication.topViewController(), (parent as? AccueilCommerces) != nil else { return 0 }
        return 44
    }
    private var bottomSafeMargin: CGFloat {
        guard let firstWindow = UIApplication.shared.windows.first else { return 0 }
        return firstWindow.safeAreaInsets.bottom
    }
    private var isPresented: Bool {
        guard let parent = parentViewController else {return false}
        
        switch preferedPosition {
        case .top:
            return progressView.frame.origin.y >= 0
        case .bottom:
            return progressView.frame.origin.y > parent.view.frame.size.height
        }
    }

    private override init() {
        super.init()
        self.start()
    }

    func updateProgress(to number: Float) {
        guard let parent = parentViewController, (parent as? ZAlertView) == nil else { return }
        initProgressView(with: .default)
        
        let progress = number / 100
        currentProgress = progress
        
        if didFinishUploading {
            progressView.progressDescriptionLabel.text = "Envoi de votre vidéo terminé".localized()
            // Wait 2 seconds and hide
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hideProgressView()
            }
        } else {
            progressView.progressBar.progress = progress
            progressView.progressIndicatorLabel.text = "\(Int(number))%".localized()
            progressView.progressDescriptionLabel.text = "Envoi de votre vidéo en cours".localized()
            
            showProgressView()
        }
    }
}

// Handle progress bar position
extension FileUploadManager {
    private func initProgressView(with style: UIProgressView.Style) {
        guard let parent = parentViewController else { return }
        
        for view in parent.view.subviews where (view as? FileUploadProgressView) != nil {
            // Progress bar already presented
            return
        }
        
        switch preferedPosition {
        case .top:
            progressView.frame = CGRect(x: 0,
                                        y: -progressViewHeight,
                                        width: parent.view.frame.size.width,
                                        height: progressViewHeight)

        case .bottom:
            progressView.frame = CGRect(x: 0,
                                        y: parent.view.frame.size.height,
                                        width: parent.view.frame.size.width,
                                        height: progressViewHeight)
        }
        parent.view.addSubview(progressView)
        progressView.progressBar.progressViewStyle = style
        currentProgress = 0.0
    }
    
    private func showProgressView() {
        guard let parent = parentViewController else { return }
        let frame = progressView.frame
        var newFrame = frame
        switch preferedPosition {
        case .top:
            newFrame.origin.y = topSafeMargin
        case .bottom:
            newFrame.origin.y = parent.view.frame.size.height - progressViewHeight - bottomSafeMargin
        }
        
        // Animation
        UIView.animate(withDuration: animationDuration, animations: {
            self.progressView.frame = newFrame
        }, completion: nil)
    }
    
    private func hideProgressView() {
        guard let parent = parentViewController, isPresented else { return }
        
        let frame = progressView.frame
        var newFrame = frame
        switch preferedPosition {
        case .top:
            newFrame.origin.y = -progressViewHeight
        case .bottom:
            newFrame.origin.y = parent.view.frame.size.height
        }
        
        // Animation
        UIView.animate(withDuration: animationDuration, animations: {
            self.progressView.frame = newFrame
        }, completion: { (_ completed) in
            self.progressView.removeFromSuperview()
        })
    }
}

// Schedule appearing
extension FileUploadManager: Schedulable {
    var block: () -> Void { {
            if self.didFinishUploading == false, self.currentProgress != 0.0, self.isPresented == false {
                self.showProgressView()
            }
        }
    }
    
    var timeInterval: TimeInterval {
        didFinishUploading ? 60 : 1
    }
}
