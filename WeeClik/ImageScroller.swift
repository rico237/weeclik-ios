//
//  ImageScroller.swift
//  ImageScroller
//
//  Created by Akshaykumar Maldhure on 29/08/17.
//  Copyright © 2017. All rights reserved.
//

import UIKit
import SDWebImage

protocol ImageScrollerDelegate: AnyObject {
    func pageChanged(index: Int)
}

class ImageScroller: UIView {

    var scrollView: UIScrollView = UIScrollView()
    weak var delegate: ImageScrollerDelegate?
    var isAutoScrollEnabled = false
    var scrollTimeInterval = 3.0
    var isAutoLoadingEnabled = false
    var timer = Timer()
    var isTimerRunning = false

    func setupScrollerWithImages(images: [String]) {
        scrollView.frame = self.frame
        scrollView.delegate = self
        var x: CGFloat = 0.0
        let y: CGFloat = 0.0
        var index: CGFloat = 0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.contentSize = CGSize(width: CGFloat(images.count) * self.frame.size.width, height: self.frame.height)
        for image in images {
            let imageView = UIImageView(frame: CGRect(x: x, y: y, width: self.frame.width, height: self.frame.height))
            imageView.contentMode = .scaleAspectFill
            if isAutoLoadingEnabled {
                // Load from URL
                let url = URL(string: image)
                imageView.sd_setImage(with: url, placeholderImage: nil, options: .highPriority, completed: nil)
            } else {
                // Load from local storage
                imageView.image = UIImage(named: image)
            }

            scrollView.addSubview(imageView)
            index += 1
            x = scrollView.frame.width * index
        }
        self.addSubview(scrollView)

        if isAutoScrollEnabled {
            startTimer()
        }

    }

    @objc func autoscroll() {
        if isAutoScrollEnabled {
            let contentWidth = self.scrollView.contentSize.width
            let x = self.scrollView.contentOffset.x + self.scrollView.frame.size.width
            if x < contentWidth {
                self.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            } else {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
        }
    }

    func resetScrollImage() {
        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }

    func startTimer() {
        if isTimerRunning == false {
            timer = Timer.scheduledTimer(timeInterval: scrollTimeInterval, target: self, selector: #selector(autoscroll), userInfo: nil, repeats: true)
            isTimerRunning = true
        }
    }

    func stopTimer() {
        timer.invalidate()
        isTimerRunning = false
    }
}

extension ImageScroller: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNum = (Int)(self.scrollView.contentOffset.x / self.scrollView
            .frame.size.width)
        if let delegate = self.delegate {
            delegate.pageChanged(index: pageNum)
        }
    }
}
