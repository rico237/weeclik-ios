//
//  CollectionStackContainerCollectionViewCell.swift
//  Compose
//
//  Created by Bruno Bilescky on 26/10/16.
//  Copyright © 2016 VivaReal. All rights reserved.
//

import UIKit

class CollectionStackContainerCollectionViewCell: UICollectionViewCell {
    
    private var currentConstraints: [NSLayoutConstraint] = []
    
    public private(set) var innerView: ComposingCollectionView
    
    private var widthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    private var topConstraint: NSLayoutConstraint!
    
    var containerSize: CGSize {
        get {
            return CGSize(width: widthConstraint.constant, height: heightConstraint.constant)
        }
        set {
            widthConstraint.constant = newValue.width
            heightConstraint.constant = newValue.height
        }
    }
    
    override public init(frame: CGRect) {
        var innerFrame = frame
        innerFrame.origin = .zero
        self.innerView = ComposingCollectionView(frame: innerFrame)
        super.init(frame: frame)
        commonInit(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported.")
    }
    
    private func commonInit(frame: CGRect) {
        self.isOpaque = false
        self.backgroundColor = .clear
        self.innerView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(innerView)
        self.addConstraints()
    }
    
    private func addConstraints() {
        let toView = self
        let itemView = self.innerView
        leadingConstraint = NSLayoutConstraint(item: itemView, attribute: .leading, relatedBy: .equal, toItem: toView, attribute: .leading, multiplier: 1, constant: 0)
        topConstraint = NSLayoutConstraint(item: itemView, attribute: .top, relatedBy: .equal, toItem: toView, attribute: .top, multiplier: 1, constant: 0)
        widthConstraint = NSLayoutConstraint(item: self.innerView, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .width, multiplier: 1, constant: 0)
        heightConstraint = NSLayoutConstraint(item: self.innerView, attribute: .height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0)
        toView.addConstraints([leadingConstraint, topConstraint])
        self.innerView.addConstraints([widthConstraint, heightConstraint])
    }
    
}
