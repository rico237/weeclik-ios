//
//  ComposingUnitTableViewCell.swift
//  Compose
//
//  Created by Bruno Bilescky on 25/10/16.
//  Copyright © 2016 VivaReal. All rights reserved.
//

import UIKit

/// Generic cell that encapsulates another view inside it. You can use it to fast embed other views inside a UITableViewCell.
public class ComposingUnitTableViewCell<V: UIView>: UITableViewCell {

    private var currentConstraints: [NSLayoutConstraint] = []
    
    /// Embeded view (this view is generated by the TableViewCell)
    public var innerView: V!
    
    /// insets applied to the embeded view.
    public var insets: UIEdgeInsets = .zero
    
    public convenience init(reuseIdentifier: String?) {
        self.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit(frame: self.frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit(frame: self.frame)
    }
    
    private func commonInit(frame: CGRect) {
        self.isOpaque = false
        self.backgroundColor = .clear
        self.innerView = V(frame: frame)
        self.contentView.addSubview(innerView)
        self.innerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    /// You can apply some ViewTraits to the tableViewCell, in order to configure it
    ///
    /// - parameter traits: an array of ViewTraits
    public func apply(traits: [ViewTraits]) {
        self.backgroundColor = .clear
        let result = ViewTraits.mapStyle(from: traits)
        self.insets = result.insets
        self.contentView.isOpaque = result.opaque
        self.contentView.backgroundColor = result.backgroundColor
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        update(insets: insets)
    }
    
    private func update(insets: UIEdgeInsets, animated: Bool = false) {
        let superview = self
        superview.removeConstraints(currentConstraints)
        self.innerView.removeConstraints(currentConstraints)
        let leadingConstraint = NSLayoutConstraint(item: self.innerView, attribute: .leading, relatedBy: .equal, toItem: superview, attribute: .leading, multiplier: 1, constant: insets.left)
        let topConstraint = NSLayoutConstraint(item: self.innerView, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1, constant: insets.top)
        let trailingConstraint = NSLayoutConstraint(item: self.innerView, attribute: .trailing, relatedBy: .equal, toItem: superview, attribute: .trailing, multiplier: 1, constant: -insets.right)
        let bottomConstraint = NSLayoutConstraint(item: self.innerView, attribute: .bottom, relatedBy: .equal, toItem: superview, attribute: .bottom, multiplier: 1, constant: -insets.bottom)
        currentConstraints = [leadingConstraint, topConstraint, trailingConstraint, bottomConstraint]
        superview.addConstraints(currentConstraints)
    }

}
