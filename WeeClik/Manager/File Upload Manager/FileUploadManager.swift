//
//  FileUploadManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 10/04/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

final class FileUploadManager: NSObject {
    static let shared = FileUploadManager()
    
    enum Position {
        case top
        case bottom
    }
    
    var currentProgress: Float = 0
    var didFinishUploading: Bool {
        return currentProgress >= 1.0
    }
    
    private var preferedPosition: Position = .top
    private var animationDuration: TimeInterval = 0.25
    private var progressView: FileUploadProgressView = FileUploadProgressView(frame: .zero)
    private var parentViewController: UIViewController?
    private var margin: CGFloat = 8
    private var progressViewHeight: CGFloat = 92
    private var bottomSafeMargin: CGFloat {
        guard let firstWindow = UIApplication.shared.windows.first else { return 0 }
        if #available(iOS 11.0, *) {
            if let bottomInset = progressView.superview?.safeAreaInsets.bottom {
                return bottomInset + margin * 4
            }
        }
        return firstWindow.safeAreaInsets.bottom + margin * 4
    }
    private var isPresented = false

    private override init() {}

    func updateProgress(to number: Float) {
        let progress = number / 100
        currentProgress = progress
        
        progressView.progressBar.progress = progress
        progressView.progressIndicatorLabel.text = "\(Int(number))%".localized()
        progressView.progressDescriptionLabel.text = "Envoi de votre vidéo en cours".localized()
        
        if didFinishUploading {
            progressView.progressDescriptionLabel.text = "Envoi de votre vidéo terminé".localized()
            // Wait 2 seconds and hide
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hideProgressView()
                self.updateProgress(to: 0)
            }
        }
    }
    
    func show(in parentViewController: UIViewController, from position: Position = .top, style: UIProgressView.Style = .default) {
        guard let parent = UIWindow.getVisibleViewControllerFrom(parentViewController), isPresented == false else { return }
        self.parentViewController = parent
        preferedPosition = position
        isPresented = true
        
        // Init base on position
        initProgressView(with: style)
        // Show with animation
        showProgressView()
    }
}

// Handle progress bar position
extension FileUploadManager {
    private func initProgressView(with style: UIProgressView.Style) {
        guard let parent = parentViewController else { return }
        
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
    }
    
    private func showProgressView() {
        let frame = progressView.frame
        var newFrame = frame
        switch preferedPosition {
        case .top:
            newFrame.origin.y = 0
        case .bottom:
            newFrame.origin.y -= (progressViewHeight * 2) - bottomSafeMargin
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
            self.isPresented = false
            self.progressView.removeFromSuperview()
        })
    }
}
